// functions/servi_ai.js
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as functions from 'firebase-functions';
import * as dotenv from 'dotenv';

// Carga las variables del archivo .env automáticamente
dotenv.config();

// --- CORRECCIÓN FINAL ---
// Eliminamos functions.config() porque ya no existe en la v7.
// Ahora leemos directo de las variables de entorno estándar.
const API_KEY = process.env.GEMINI_API_KEY;

// Inicializamos la IA solo si hay Key
const genAI = API_KEY ? new GoogleGenerativeAI(API_KEY) : null;

if (!API_KEY) {
    console.warn("⚠️ ADVERTENCIA CRÍTICA: No se encontró GEMINI_API_KEY en el archivo .env");
}

/**
 * SERVI MVP 1.0: Extracción de datos de facturas (OCR).
 */
export const extractInvoiceData = functions.https.onCall(async(data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado.');
    if (!genAI) throw new functions.https.HttpsError('failed-precondition', 'Servidor: API Key de IA no configurada.');

    const base64Image = data.image_data;
    if (!base64Image) throw new functions.https.HttpsError('invalid-argument', 'Falta la imagen.');

    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        generationConfig: { responseMimeType: "application/json" }
    });

    const prompt = `You are an expert invoice parser. Extract fields: 'vendorName', 'invoiceNumber', 'totalAmount', and 'lineItems' (array with description, quantity, unitPrice). Respond ONLY with raw JSON.`;

    try {
        const result = await model.generateContent([
            prompt,
            { inlineData: { data: base64Image, mimeType: "image/jpeg" } }
        ]);
        return JSON.parse(result.response.text());
    } catch (error) {
        functions.logger.error("Error OCR Gemini:", error);
        throw new functions.https.HttpsError('internal', 'Error procesando la factura.', error.message);
    }
});

/**
 * SERVI MVP 1.4: Clasificación de Transacciones.
 */
export const classifyTransaction = functions.https.onCall(async(data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado.');
    if (!genAI) throw new functions.https.HttpsError('failed-precondition', 'API Key no configurada.');

    const description = data.transaction_description;
    const userCategories = data.user_categories || [];

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = `Classify this transaction: "${description}". 
    Choose one category from: [${userCategories.join(', ')}]. 
    Respond ONLY with the category name string.`;

    try {
        const result = await model.generateContent(prompt);
        return result.response.text().trim().replace(/['"`.]/g, '');
    } catch (error) {
        functions.logger.error("Error Clasificación Gemini:", error);
        throw new functions.https.HttpsError('internal', 'Error clasificando.', error.message);
    }
});

/**
 * SERVI MVP 1.5: Recomendaciones (CRM).
 */
export const predictClientRecommendations = functions.https.onCall(async(data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth requerida');

    // Validación simple y segura
    if (!genAI) return [];
    if (!data.product_list || data.product_list.length === 0) return [];

    const productList = data.product_list;
    const clientHistory = data.client_history || [];

    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        generationConfig: { responseMimeType: "application/json" }
    });

    const prompt = `Client History: ${clientHistory.join(', ')}. 
    Available Products: ${productList.join('; ')}. 
    Suggest 3 logical cross-sell products not in history. 
    Respond ONLY with a JSON Array of strings.`;

    try {
        const result = await model.generateContent(prompt);
        const json = JSON.parse(result.response.text());
        return Array.isArray(json) ? json : [];
    } catch (error) {
        functions.logger.error("Error CRM Gemini:", error);
        return [];
    }
});

/**
 * SERVI MVP 3.0: Clasificación de Intenciones (Chat).
 */
export const handleUserQuery = functions.https.onCall(async(data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth requerida');
    if (!genAI) throw new functions.https.HttpsError('failed-precondition', 'API Key no configurada.');

    const userQuery = data.query;

    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        generationConfig: { responseMimeType: "application/json" }
    });

    const prompt = `Classify intent for provider app. 
    Modules: AGENDA, INVENTORY, CRM, GENERAL. 
    Query: "${userQuery}". 
    Respond JSON: { "intent": "string", "module": "string", "params": {} }`;

    try {
        const result = await model.generateContent(prompt);
        return { data: JSON.parse(result.response.text()) };
    } catch (error) {
        functions.logger.error("Error Intent Gemini:", error);
        throw new functions.https.HttpsError('internal', 'Error IA', error.message);
    }
});