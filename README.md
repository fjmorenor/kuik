Proyecto landing zone y gke - kuik
este es el repo con todo lo que hemos hecho en el lab del viernes para que funcione el pipeline.

Que hay en las carpetas:
host: aqui estan los archivos de terraform para la red y la vpc shared que mandan los de sistemas.

dev: esta el cluster de gke-kuik-dev-002 y la config del proyecto de desarrollo.

yaml: los archivos de kubernetes (deployment, service y el ingress).

functions: el codigo de python para que gemini lea los logs cuando algo peta en el cluster.

.github: los workflows para que al hacer push se suba la imagen a google cloud sola.

Como hacerlo funcionar:
primero hay que hacer terraform apply en host y luego en dev (tarda como 15 min).

conectar el kubectl con el comando de gcloud que nos dieron.

subir los cambios a github para que se active la action.

mirar la ip del ingress para ver la web (la mia es 136.110.169.2 pero puede cambiar si borras el ingress).

Notas:
si un pod se queda en pending es por que google no tiene mas cpus e2-medium en belgica (europe-west1-b), hay que bajar las replicas a 1.
el dockerfile usa nginx para servir el index.html que esta en la raiz.
