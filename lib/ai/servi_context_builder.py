import json
from typing import Dict, List, Any, Tuple

# --- DEPENDENCIAS (PLACEHOLDERS) ---

# Se asume que usted tiene un conector de base de datos genérico.
class DBConnector:
    """Simula las llamadas a la base de datos."""
    def fetch_data(self, query_key: str, date: str = None, item_id: str = None) -> List[Dict[str, Any]]:
        """Devuelve datos crudos de la DB según la clave."""
        # **ESTO DEBE SER REEMPLAZADO POR SUS CONSULTAS REALES**
        
        # Simulación de datos de la DB:
        if query_key == "PAGOS_CRITICOS":
            return [
                {"id": 101, "name": "Nómina", "amount": 3000.00, "due_date_status": "Hoy", "is_critical": True},
                {"id": 102, "name": "Impuesto Anual", "amount": 800.00, "due_date_status": "Vencido", "is_critical": True},
            ]
        if query_key == "INVENTARIO_FILTRO":
            return [{"name": "Filtro Aceite A", "stock": 15, "cost": 8.00, "price": 15.00, "alert": "BAJO_STOCK"}]
        
        return []

class IntentAnalyzer:
    """Simula el análisis de NLP para determinar la intención y los parámetros."""
    def analyze(self, query: str) -> Tuple[str, str]:
        """Devuelve la intención y la fecha solicitada (ej: "CONSULTA_PAGOS", "Hoy")."""
        # **ESTO DEBE SER REEMPLAZADO POR SU SERVICIO DE NLP/INTENT DETECTION**
        
        if "pago" in query.lower():
            return "CONSULTA_PAGOS_CRITICOS", "Hoy"
        if "stock" in query.lower():
            return "CONSULTA_INVENTARIO", "N/A"
        return "SALUDO_APERTURA", "N/A"
        
# Inicialización de Placeholders (En su código real, estas se inyectan)
DB_CONNECTOR = DBConnector()
INTENT_ANALYZER = IntentAnalyzer()

# --- FUNCIONES DE SOPORTE ---

def initialize_base_context(target_date: str) -> Dict[str, Any]:
    """Crea la plantilla JSON base con todos los módulos nulos."""
    return {
        "fecha_consulta": target_date,
        "agenda_data": None,
        "pagos_pendientes": None,
        "inventario_consulta": None,
        "ventas_hoy": None,
        "finanzas_reporte": None,
        "estructura_costo": None,
        "crm_consulta": None
    }

def formatear_para_servi(raw_data: List[Dict[str, Any]], module_name: str) -> Any:
    """
    Transforma los datos complejos de la DB en el JSON simple y conciso que SERVI espera.
    """
    if not raw_data:
        return None

    # MÓDULO: PAGOS (Lista)
    if module_name == 'pagos':
        formatted_list = []
        for item in raw_data:
            formatted_list.append({
                "concepto": item.get('name', 'Pago Desconocido'),
                "monto": item.get('amount', 0.00),
                "vencimiento": item.get('due_date_status'),
                "estado_critico": item.get('is_critical', False)
            })
        return formatted_list

    # MÓDULO: INVENTARIO (Objeto único)
    if module_name == 'inventario':
        item = raw_data[0]
        return {
            "nombre": item.get('name', 'Producto Desconocido'),
            "stock_actual": item.get('stock', 0),
            "costo_unitario": item.get('cost', 0.00),
            "precio_venta": item.get('price', 0.00),
            "alerta_stock": item.get('alert', 'N/A')
        }

    # MÓDULO: VENTAS (Objeto resumen)
    if module_name == 'ventas':
        item = raw_data[0] # Asumimos que la DB devuelve un resumen de un día/periodo
        return {
            "total_ventas": item.get('total', 0.00),
            "ordenes_totales": item.get('orders', 0),
            "variacion_ayer_porc": item.get('change_perc', 0.0)
        }
        
    # MÓDULO: CRM (Objeto único de cliente)
    if module_name == 'crm':
        item = raw_data[0]
        return {
            "nombre": item.get('client_name'),
            "saldo_pendiente": item.get('outstanding_balance', 0.00),
            "ultima_compra": item.get('last_purchase_date'),
            "total_gastado": item.get('lifetime_value', 0.00)
        }
    
    # AGREGAR LÓGICA PARA 'agenda', 'finanzas', 'costo' AQUÍ...

    return raw_data

# --- FUNCIÓN PRINCIPAL DE CONSTRUCCIÓN DEL CONTEXTO (Paso 2) ---

def build_company_context(user_query: str, db_connector: DBConnector) -> str:
    """
    Determina la intención del usuario, consulta la DB y construye el JSON de contexto final 
    para el LLM.
    """
    
    # 1. ANÁLISIS DE INTENCIÓN Y EXTRACCIÓN DE PARÁMETROS
    # Aquí se utiliza el placeholder de NLP. En su app, esto puede ser una función compleja.
    intent, target_date = INTENT_ANALYZER.analyze(user_query)
    
    # 2. INICIALIZAR CONTEXTO BASE
    context = initialize_base_context(target_date)

    # 3. LÓGICA CONDICIONAL DE CONSULTA (Mapeo de Intenciones)
    
    if intent in ["CONSULTA_PAGOS_CRITICOS", "RESUMEN_DIARIO"]:
        # Se requiere data de pagos
        raw_payments = db_connector.fetch_data("PAGOS_CRITICOS", target_date)
        context["pagos_pendientes"] = formatear_para_servi(raw_payments, 'pagos')

    if intent == "CONSULTA_INVENTARIO":
        # Se requiere data de inventario
        # Asumimos que la clave del producto se extrae en el análisis o se pasa como parámetro
        raw_inventory = db_connector.fetch_data("INVENTARIO_FILTRO", item_id="Filtro A")
        context["inventario_consulta"] = formatear_para_servi(raw_inventory, 'inventario')

    # AGREGAR MÁS INTENCIONES AQUÍ:
    # elif intent == "CONSULTA_CRM":
    #     raw_crm = db_connector.fetch_data("CRM_CLIENTE", item_id=cliente_nombre)
    #     context["crm_consulta"] = formatear_para_servi(raw_crm, 'crm')

    # 4. DEVOLVER EL JSON FINAL COMO STRING
    # Se utiliza el parámetro indent para mayor legibilidad en el debugging, pero puede ser omitido.
    return json.dumps(context, indent=2)

# --- EJEMPLO DE USO ---
if __name__ == '__main__':
    # Para probar el builder sin la API
    
    test_query = "¿Qué pagos tengo vencidos?"
    context_output = build_company_context(test_query, DB_CONNECTOR)
    
    print("\n--- CONSULTA DE USUARIO ---")
    print(f"Pregunta: {test_query}")
    
    print("\n--- COMPANY_CONTEXT GENERADO PARA EL LLM ---")
    print(context_output)

    # El LLM solo verá los datos relevantes y nulos, reduciendo el ruido.