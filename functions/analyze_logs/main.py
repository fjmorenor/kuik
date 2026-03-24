# functions/analyze_logs/main.py
import functions_framework
import base64, json
import google.generativeai as genai
 
@functions_framework.cloud_event
def analyze_log_error(cloud_event):
    # Decodificar el mensaje de Pub/Sub
    data = base64.b64decode(cloud_event.data['message']['data']).decode()
    log_entry = json.loads(data)
    log_text  = log_entry.get('textPayload', '') or str(log_entry.get('jsonPayload', ''))
    pod_name  = log_entry.get('resource', {}).get('labels', {}).get('pod_name', 'unknown')
 
    # Analizar con Gemini
    genai.configure()  # Usa Application Default Credentials
    model  = genai.GenerativeModel('gemini-1.5-flash')
    prompt = f'''
    Analiza este error de un pod de Kubernetes llamado '{pod_name}':
    {log_text}
    Responde en español con:
    1. Causa probable del error
    2. Impacto potencial
    3. Pasos recomendados para resolverlo
    '''
    response  = model.generate_content(prompt)
    diagnosis = response.text
    print(f'Pod: {pod_name}')
    print(f'Diagnóstico Gemini: {diagnosis}')
    return 'OK'
