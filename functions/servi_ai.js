// functions/servi_ai.js
const functions = require('firebase-functions');
const { GoogleGenAI } = require('@google/genai');

// Obtener la clave de forma segura
const GEMINI_API_KEY = functions.config().ai.gemini_key;
const ai = new GoogleGenAI(GEMINI_API_KEY);

/**
 * Función HTTPS para la extracción de datos de facturas mediante Gemini Vision.
 * Protege la API Key de Gemini al no exponerla en el cliente.
 * Se accede mediante una llamada HTTP autenticada desde Flutter.
 */
exports.extractInvoiceData = functions.https.onCall(async(data, context) => {
    // 1. AUTORIZACIÓN: Requerir autenticación para usar el servicio de pago (IA)
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'La función requiere un usuario autenticado.');
    }

    const base64Image = data.image_data;
    if (!base64Image) {
        throw new functions.https.HttpsError('invalid-argument', 'Falta la imagen codificada en Base64.');
    }

    // 2. Preparar el contenido para Gemini (Base64 + MimeType)
    const imagePart = {
        inlineData: {
            data: base64Image,
            mimeType: 'image/jpeg', // Asumimos JPEG
        },
    };

    // 3. Prompt de Extracción de Datos
    const prompt = `You are an expert invoice parser. Analyze this image of a supplier invoice. Extract the following fields: 'vendorName' (string), 'invoiceNumber' (string), 'totalAmount' (float), and an array named 'lineItems'. Each item in 'lineItems' must contain: 'description' (string), 'quantity' (integer), and 'unitPrice' (float). Respond ONLY with a clean JSON object. Do not include any introductory text, markdown formatting like \`\`\`, or explanations.`;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [imagePart, { text: prompt }],
            config: {
                responseMimeType: 'application/json',
            },
        });

        // 4. Devolver el JSON a la aplicación Flutter
        return JSON.parse(response.text);

    } catch (error) {
        functions.logger.error("Error al llamar a la API de Gemini:", error);
        throw new functions.https.HttpsError('internal', 'Error al procesar la imagen con SERVI.', error.message);
    }
    exports.classifyTransaction = functions.https.onCall(async(data, context) => {
        // 1. Autorización
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'La función requiere autenticación.');
        }

        const description = data.transaction_description;
        const userCategories = data.user_categories; // Recibido como array

        if (!description || !userCategories || userCategories.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Faltan descripción o categorías.');
        }

        const categoryListString = userCategories.join(', ');

        // 2. Prompt de Clasificación Financiera
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

            // Limpiamos y devolvemos el resultado de la IA
            const resultCategory = response.text.trim().replace(/['"`.]/g, '');

            // Devolvemos la clasificación sugerida
            return resultCategory;

        } catch (error) {
            functions.logger.error("Error al clasificar transacción con Gemini:", error);
            throw new functions.https.HttpsError('internal', 'Error al clasificar transacción con SERVI.', error.message);
        }
    });
    exports.predictClientRecommendations = functions.https.onCall(async(data, context) => {
        // 1. Autorización
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'La función requiere autenticación.');
        }

        const clientId = data.client_id; // ID del cliente (para logs, no para IA)
        const productList = data.product_list; // Nombres de todos los productos disponibles (Array<string>)
        const clientHistory = data.client_history; // Historial de compras (Array<string>)

        if (!productList || productList.length === 0) {
            return [];
        }

        // 2. Preparación del Prompt
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
                    responseMimeType: 'application/json', // Pedir el JSON directamente
                    temperature: 0.5, // Un poco más de creatividad para las sugerencias
                },
            });

            // 3. Devolver la lista de strings (nombres de productos)
            const jsonResponse = JSON.parse(response.text);
            return jsonResponse.map(item => String(item).trim());

        } catch (error) {
            functions.logger.error(`Error de predicción SERVI para cliente ${clientId}:`, error);
            // Devolvemos una lista vacía en caso de error
            return [];
        }
    });
});