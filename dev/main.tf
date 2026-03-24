# =============================================================================
# CONFIGURACIÓN DE INFRAESTRUCTURA GKE - ENTORNO DEV
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 1. ESTADO REMOTO (LECTURA)
# Conectamos con el bucket donde guardamos la red (Host Project).
# Esto nos permite usar la VPC y Subnets sin escribir sus nombres a mano.
# ─────────────────────────────────────────────────────────────────────────────
data "terraform_remote_state" "host" {
  backend = "gcs"
  config = {
    bucket = "tf-state-host-002"
    prefix = "landing-zone/host"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. ACTIVACIÓN DE APIs
# Habilita los servicios de Google necesarios en el proyecto DEV.
# ─────────────────────────────────────────────────────────────────────────────
module "apis" {
  source     = "../modules/apis"
  project_id = var.dev_project_id
  services   = [ 
    "container.googleapis.com",          # Para el clúster de Kubernetes (GKE)
    "artifactregistry.googleapis.com",   # Para guardar tus imágenes Docker propias
    "logging.googleapis.com",            # Para logs y auditoría
    "monitoring.googleapis.com",         # Para métricas de rendimiento
    "aiplatform.googleapis.com",         # Vertex AI (Necesario para Gemini pro/enterprise)
    "generativelanguage.googleapis.com", # Gemini API para desarrolladores
    "cloudaicompanion.googleapis.com"    # Duet AI / Gemini Code Assist
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. GESTIÓN DE IDENTIDADES (IAM)
# Crea las Service Accounts y asigna permisos (GSA, Workload Identity, etc.)
# ─────────────────────────────────────────────────────────────────────────────
module "IAM" {
  source             = "../modules/iam"
  project_id         = var.dev_project_id
  host_project_id    = var.host_project_id
  dev_project_number = var.dev_project_number
  depends_on         = [ module.apis ] # No creamos permisos si las APIs no están listas
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. CLÚSTER DE KUBERNETES (GKE)
# Despliega el clúster usando la red compartida (Shared VPC).
# ─────────────────────────────────────────────────────────────────────────────
module "gke" {
  source          = "../modules/gke"
  project_id      = var.dev_project_id
  host_project_id = var.host_project_id
  region          = var.region
  cluster_name    = var.cluster_name
 
  # Conexión dinámica: usamos los IDs que Terraform leyó en el paso 1 (remote_state)
  network_id      = data.terraform_remote_state.host.outputs.network_id
  subnet_names    = data.terraform_remote_state.host.outputs.subnet_names["gke"]
 
  # Usamos la cuenta de servicio creada por el módulo IAM
  nodes_sa_email  = module.IAM.gke_nodes_sa_email
  depends_on      = [module.IAM] # El clúster espera a que sus permisos estén listos
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. OBSERVABILIDAD Y ALERTAS (PUB/SUB + LOGGING)
# Configuramos un sistema automático que captura errores graves.
# ─────────────────────────────────────────────────────────────────────────────

# Creamos un 'canal' (Topic) de mensajería para los errores
resource "google_pubsub_topic" "gke_errors" {
  name    = "gke-error-logs"
  project = var.dev_project_id
}

# Creamos un 'sumidero' (Sink) que filtra logs de contenedores con nivel ERROR o mayor
# y los envía automáticamente al canal de Pub/Sub.
resource "google_logging_project_sink" "gke_errors" {
  name                   = "gke-error-sink"
  project                = var.dev_project_id
  destination            = "pubsub.googleapis.com/${google_pubsub_topic.gke_errors.id}"
  filter                 = "resource.type=k8s_container AND severity>=ERROR"
  unique_writer_identity = true
}

# Permiso especial: permitimos que el sistema de Logs pueda "escribir" en Pub/Sub
resource "google_pubsub_topic_iam_member" "sink_publisher" {
  project = var.dev_project_id
  topic   = google_pubsub_topic.gke_errors.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.gke_errors.writer_identity
}


resource "google_monitoring_alert_policy" "pod_restarts" {
 display_name = "Pods reiniciandose frecuentemente"
 project = var.dev_project_id
 combiner = "OR"

   conditions {
    display_name = "Reinicios de pods > 5 en 5 minutos"
    condition_threshold {
      filter           = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/restart_count\""
      duration         = "300s"
      comparison       = "COMPARISON_GT"
      threshold_value  = 5
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.name]
}
 
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email DevOps"
  type         = "email"
  project      = var.dev_project_id
  labels       = { email_address = var.alert_email }
}

