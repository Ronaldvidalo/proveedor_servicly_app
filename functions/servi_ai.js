// functions/servi_ai.js
import { GoogleGenAI } from '@google/genai';
import * as functions from 'firebase-functions';

// Obtener la clave de forma segura y configurar la instancia de IA
const GEMINI_API_KEY = functions.config().ai.gemini_key;
const ai = new GoogleGenAI(GEMINI_API_KEY);

/**
 * SERVI MVP 1.0: Extracción de datos de facturas (OCR).
 */
export const extractInvoiceData = functions.https.onCall(async(data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'La función requiere un usuario autenticado.');
    }

    const base64Image = data.image_data;
    if (!base64Image) {
        throw new functions.https.HttpsError('invalid-argument', 'Falta la imagen codificada en Base64.');
    }

    const imagePart = {
        inlineData: {
            data: base64Image,
            mimeType: 'image/jpeg',
        },
    };

    const prompt = `You are an expert invoice parser. Analyze this image of a supplier invoice. Extract the following fields: 'vendorName' (string), 'invoiceNumber' (string), 'totalAmount' (float), and an array named 'lineItems'. Each item in 'lineItems' must contain: 'description' (string), 'quantity' (integer), and 'unitPrice' (float). Respond ONLY with a clean JSON object. Do not include any introductory text, markdown formatting like \`\`\`, or explanations.`;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [imagePart, { text: prompt }],
            config: {
                responseMimeType: 'application/json',
            },
        });

        return JSON.parse(response.text);

    } catch (error) {
        functions.logger.error("Error al llamar a la API de Gemini (OCR):", error);
        throw new functions.https.HttpsError('internal', 'Error al procesar la imagen con SERVI.', error.message);
    }
});


/**
 * SERVI MVP 1.4: Clasificación de Transacciones Financieras.
 */
export const classifyTransaction = functions.https.onCall(async(data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'La función requiere autenticación.');
    }

    const description = data.transaction_description;
    const userCategories = data.user_categories;

    if (!description || !userCategories || userCategories.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Faltan descripción o categorías.');
    }

    const categoryListString = userCategories.join(', ');

    const prompt = `You are an expert accounting classifier. Based on this transaction description: "${description}". 
    Assign the single best category from this list: [${categoryListString}]. 
    If the transaction is a revenue, assign an "Ingreso" category (if available). 
    If the transaction is an expense, assign a "Gasto" category.
    If uncertain, respond 'Gasto General'. 
    Respond ONLY with the chosen category name. Do not include any punctuation, explanation, or markdown.`;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [{ text: prompt }],
            config: {
                temperature: 0.2, // Mantener baja para precisión en la clasificación
            },
        });

        const resultCategory = response.text.trim().replace(/['"`.]/g, '');
        return resultCategory;

    } catch (error) {
        functions.logger.error("Error al clasificar transacción con Gemini:", error);
        throw new functions.https.HttpsError('internal', 'Error al clasificar transacción con SERVI.', error.message);
    }
});


/**
 * SERVI MVP 1.5: Recomendaciones de Productos (CRM).
 */
export const predictClientRecommendations = functions.https.onCall(async(data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'La función requiere autenticación.');
    }

    const clientId = data.client_id;
    const productList = data.product_list;
    const clientHistory = data.client_history;

    if (!productList || productList.length === 0) {
        return [];
    }

    const historyString = clientHistory.length > 0 ?
        `El historial de compras del cliente incluye: ${clientHistory.join(', ')}.` :
        'El cliente no tiene historial de compras registrado.';

    const prompt = `You are a sales prediction expert specializing in e-commerce cross-selling. 
    Analyze the following information:
    1. Client Profile: ${historyString}
    2. Available Products: ${productList.join('; ')}
    
    Based on this data, suggest the 3 most logical products from the 'Available Products' list 
    that the client has NOT bought yet. Focus on logical cross-selling or upsell opportunities.
    
    Respond ONLY with a clean JSON array of the 3 suggested product names (string). 
    Example: ["Nombre Producto Sugerido 1", "Nombre Producto Sugerido 2"].`;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [{ text: prompt }],
            config: {
                responseMimeType: 'application/json',
                temperature: 0.5,
            },
        });

        const jsonResponse = JSON.parse(response.text);
        if (Array.isArray(jsonResponse)) {
            return jsonResponse.map(item => String(item).trim());
        }
        return [];

    } catch (error) {
        functions.logger.error(`Error de predicción SERVI para cliente ${clientId}:`, error);
        return [];
    }
});


/**
 * SERVI CONVERSACIONAL MVP 3.0: Clasificación de Intenciones.
 */
export const handleUserQuery = functions.https.onCall(async(data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'La solicitud debe estar autenticada.');
    }
    const userQuery = data.query;
    if (!userQuery || typeof userQuery !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'El parámetro "query" es obligatorio y debe ser un texto.');
    }

    const classificationPrompt = `
        Eres el Asistente Inteligente SERVI, un experto en gestión de negocios (Inventario, CRM, Agenda) para proveedores.
        Tu rol es analizar la pregunta del usuario y CLASIFICAR su INTENCIÓN de forma precisa en un objeto JSON.
        NO respondas la pregunta. Solo CLASIFICA.

        El usuario interactúa con los siguientes Módulos (para el campo "module"):
        - AGENDA: Preguntas sobre citas, horarios, o tareas.
        - INVENTARIO: Preguntas sobre stock, costos, o cómo usar la pantalla de carga de productos.
        - CRM: Preguntas sobre clientes, leads, o sugerencias de venta.
        - GENERAL: Saludos, despedidas, o información general de la aplicación.

        Tu respuesta DEBE ser un objeto JSON que siga el siguiente esquema, incluso si el campo 'params' está vacío:

        {
          "intent": "[AGENDA_NEXT_APPOINTMENT, AGENDA_TODAY_EVENTS, INVENTORY_GUIDE, INVENTORY_CHECK_STOCK, CRM_SALES_REC, GENERAL_GREETING, GENERAL_OTHER]",
          "module": "[AGENDA, INVENTORY, CRM, GENERAL]",
          "params": {
            // Parámetros clave extraídos de la consulta (ej: "date": "today", "product": "shampoo")
          }
        }
        
        Clasifica la siguiente consulta del usuario: "${userQuery}"
    `;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [
                { role: "user", parts: [{ text: classificationPrompt }] }
            ],
            config: {
                temperature: 0.1,
            }
        });

        const jsonText = response.text.trim();
        const startIndex = jsonText.indexOf('{');
        const endIndex = jsonText.lastIndexOf('}');

        if (startIndex === -1 || endIndex === -1) {
            throw new Error("Gemini no devolvió un JSON válido.");
        }

        const jsonString = jsonText.substring(startIndex, endIndex + 1);
        const result = JSON.parse(jsonString);

        return { data: result };

    } catch (error) {
        console.error("Error en handleUserQuery:", error);
        throw new functions.https.HttpsError('internal', 'Error de clasificación de IA: ' + error.message);
    }
});