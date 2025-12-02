import json
import re
from typing import Dict, Any

# --- DEPENDENCIAS NECESARIAS ---
# IMPORTAR: El constructor de contexto (archivo del Paso 2)
# Reemplace 'your_path' con la ruta real a servi_context_builder.py
from .servi_context_builder import build_company_context 

# --- CONFIGURACIÓN ESTÁTICA ---
# Ruta al archivo de instrucciones de SERVI (del Paso 1)
SYSTEM_PROMPT_FILE_PATH = 'lib/ai/prompts/servi_system_prompt.txt'
# -----------------------------

# --- # PLACEHOLDER 1: LECTURA DEL PROMPT ESTÁTICO ---
def read_static_system_prompt() -> str:
    """Lee el texto completo del prompt de SERVI desde el archivo."""
    try:
        with open(SYSTEM_PROMPT_FILE_PATH, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"ERROR FATAL: Archivo de prompt no encontrado en {SYSTEM_PROMPT_FILE_PATH}")
        # En producción, esto debería lanzar una excepción crítica.
        return "ERROR: PROMPT INACCESIBLE. ACTÚA COMO UN ASISTENTE DE IA DE SOPORTE." 

# --- # PLACEHOLDER 2: LLAMADA REAL A LA API DEL VENDOR ---
def call_llm_api_vendor(payload: list) -> str:
    """Simula la llamada HTTP real al proveedor de IA (Gemini, OpenAI, etc.)."""
    # **AQUÍ VA SU CÓDIGO DE SOLICITUD HTTP/SDK REAL**
    
    # Simulación de una respuesta exitosa del LLM
    if "Filtro de Aceite X" in payload[1]['content']:
        return """
        Aquí está su JSON:
        {
          "TEXTO_ESCRITO": "⚠️ ALERTA DE BAJO STOCK: Filtro de Aceite X (SKU F-001)\\n\\n* Stock Actual: 15 unidades.",
          "TEXTO_VOZ": "¡Alerta! El Filtro de Aceite X tiene bajo stock. Solo quedan 15 unidades disponibles."
        }
        """
    # Simulación de un error de formato (el LLM agregó texto extra)
    if "ERROR" in payload[1]['content']:
        return 'El modelo se equivocó: {"TEXTO_VOZ": "error"}'
        
    return '{"TEXTO_ESCRITO": "Respuesta predeterminada.", "TEXTO_VOZ": "Respuesta corta."}'

# --- LÓGICA CORE DEL CONNECTOR (Paso 4) ---

def build_final_llm_payload(context_json: str, user_query: str) -> list:
    """Construye el payload final uniendo el prompt estático y el contexto dinámico."""
    
    system_prompt = read_static_system_prompt()
    
    # Construir el contenido del mensaje del usuario
    user_content = (
        "--- CONTEXTO DINÁMICO DE LA EMPRESA ---\n\n"
        f"{context_json}\n\n"
        "--- PREGUNTA DEL USUARIO ---\n\n"
        f"{user_query}"
    )

    # El payload final que se envía a la API
    payload = [
        {
            "role": "system",
            "content": system_prompt 
        },
        {
            "role": "user",
            "content": user_content
        }
    ]
    return payload

def handle_llm_parsing(raw_response_text: str) -> Dict[str, Any]:
    """
    Función de robustez: Aisla el JSON e implementa la lógica de manejo de errores de SERVI.
    """
    
    # Patrón RegEx para aislar el JSON, buscando la primera '{' hasta la última '}'
    # Esta es la parte más crítica para la robustez
    match = re.search(r'\{.*\}', raw_response_text, re.DOTALL)
    
    if not match:
        raise ValueError("No se pudo aislar una estructura JSON válida en la respuesta del LLM.")
        
    cleaned_json_string = match.group(0).strip()
    
    try:
        # Parseo estricto del JSON
        response_object = json.loads(cleaned_json_string)
        
        # Validación de que las claves obligatorias existen (robustez extra)
        if "TEXTO_VOZ" not in response_object or "TEXTO_ESCRITO" not in response_object:
             raise ValueError("JSON de SERVI inválido: Faltan claves obligatorias (TEXTO_VOZ/TEXTO_ESCRITO).")
        
        # Devolver el objeto limpio
        return {
            "voz": response_object['TEXTO_VOZ'],
            "display": response_object['TEXTO_ESCRITO'],
            "exito": True
        }
        
    except json.JSONDecodeError as e:
        # Fallo en el parseo, el LLM rompió el formato
        raise ValueError(f"Fallo en el parseo JSON: {e}. Texto crudo: {cleaned_json_string[:100]}...")
    except ValueError as e:
        # Fallo en la validación o aislamiento
        raise e

# --- FUNCIÓN PRINCIPAL DE ORQUESTACIÓN ---

def get_servi_response(user_query: str, db_connector: Any) -> Dict[str, Any]:
    """
    Orquesta la construcción del contexto, la llamada a la API y el manejo de la respuesta.
    """
    try:
        # 1. CONSTRUIR CONTEXTO (Llamada al archivo del Paso 2)
        context_json_string = build_company_context(user_query, db_connector) 
        
        # 2. CONSTRUIR PAYLOAD FINAL
        final_payload = build_final_llm_payload(context_json_string, user_query)
        
        # 3. LLAMADA A LA API
        raw_response_text = call_llm_api_vendor(final_payload)
        
        # 4. PARSEO Y MANEJO DE ERRORES (Paso 4)
        return handle_llm_parsing(raw_response_text)
        
    except Exception as e:
        # Manejo de fallos en el build_context, API o parseo.
        print(f"Error crítico en la operación de SERVI: {e}")
        return {
            "voz": "Disculpe, el sistema tuvo un error de procesamiento interno. Por favor, inténtelo de nuevo.",
            "display": f"Error: {e}",
            "exito": False
        }