// functions/index.js (MODIFIED TO USE ESM SYNTAX)

// 1. Importaciones de módulos (usando sintaxis ESM)
import * as functions from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
// Importaciones de triggers de Firestore v2
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from 'firebase-functions/v2/firestore';

// Importar las funciones de IA desde servi_ai.js
// IMPORTANTE: El .js es requerido para el entorno ESM
import * as serviAi from './servi_ai.js';

// 2. Inicialización de Firebase Admin
initializeApp();
const db = getFirestore();

// --- Utilidades ---

/**
 * Función auxiliar para obtener el perfil del usuario (proveedor)
 * @param {string} uid 
 * @returns {Promise<any>}
 */
const getUserData = async(uid) => {
    const doc = await db.collection('users').doc(uid).get();
    return doc.data();
};

/**
 * Función auxiliar para actualizar el contador de clientes en el documento del proveedor.
 * Se llama desde los triggers de Firestore.
 * @param {string} providerId
 */
const updateClienteCount = async(providerId) => {
    // Esto podría ser un trigger en la vida real, pero lo modelamos como helper
    const snapshot = await db.collection('users').doc(providerId).collection('clientes').count().get();
    const count = snapshot.count || 0;

    await db.collection('users').doc(providerId).update({
        clienteCount: count,
        lastUpdated: FieldValue.serverTimestamp(),
    });
};


// 3. Triggers Firestore (Lógica de Negocio CRM)

// Trigger cuando se crea un nuevo documento de cliente/lead
export const onClienteCreated = onDocumentCreated('users/{providerId}/clientes/{clienteId}', async(event) => {
    const providerId = event.params.providerId;
    const clienteData = event.data.data();

    functions.logger.info(`Nuevo cliente/lead creado para ${providerId}: ${clienteData.nombreCompleto}`);

    // Lógica para actualizar el contador de clientes
    await updateClienteCount(providerId);
});

// Trigger cuando se elimina un documento de cliente/lead
export const onClienteDeleted = onDocumentDeleted('users/{providerId}/clientes/{clienteId}', async(event) => {
    const providerId = event.params.providerId;

    functions.logger.info(`Cliente/lead eliminado para ${providerId}.`);

    // Lógica para actualizar el contador de clientes
    await updateClienteCount(providerId);
});


/**
 * 2.1. Se activa cuando un documento en la colección 'cobros' (del módulo de Finanzas)
 * es creado o actualizado, y el estado cambia a 'COBRADO'.
 * Esta función automatiza la promoción de un LEAD a CLIENTE y calcula el LTV.
 *
 * RUTA ASUMIDA: /users/{userId}/cobros/{cobroId}
 * Condición: (after.data().estado === 'COBRADO') && (before.data().estado !== 'COBRADO')
 */
export const onCobroPagado = onDocumentUpdated('users/{providerId}/cobros/{cobroId}', async(event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();
    const providerId = event.params.providerId; // Usamos providerId en v2

    // Verificación 1: Debe ser un cambio de estado a COBRADO
    if (after.estado !== 'COBRADO' || before.estado === 'COBRADO') {
        functions.logger.log("Cobro no completado o ya procesado. Terminando función.");
        return null;
    }

    const clienteId = after.clienteId;
    const montoCobrado = after.monto || 0;

    if (!clienteId) {
        functions.logger.warn(`Cobro ${event.params.cobroId} no tiene clienteId. Saltando actualización de CRM.`);
        return null;
    }

    const clienteRef = db.collection('users').doc(providerId).collection('clientes').doc(clienteId);

    // Transacción para garantizar la integridad del montoTotalFacturado
    return db.runTransaction(async(t) => {
        const clienteDoc = await t.get(clienteRef);

        if (!clienteDoc.exists) {
            functions.logger.error(`Cliente ID: ${clienteId} no encontrado.`);
            return;
        }

        const clienteData = clienteDoc.data();
        const clienteEstado = clienteData.estadoCRM;

        const updates = {};

        // 1. Actualizar LTV: Incrementa el montoTotalFacturado
        const currentLTV = clienteData.montoTotalFacturado || 0;
        updates.montoTotalFacturado = currentLTV + montoCobrado;

        // 2. Actualizar Última Interacción
        updates.ultimaInteraccion = FieldValue.serverTimestamp(); // Usamos FieldValue

        // 3. Lógica de Conversión (si el cliente era un LEAD)
        if (clienteEstado && clienteEstado.startsWith('LEAD')) {
            // Convierte cualquier estado LEAD a CLIENTE_ACTIVO
            updates.estadoCRM = 'CLIENTE_ACTIVO';
            functions.logger.log(`LEAD ${clienteId} convertido automáticamente a CLIENTE_ACTIVO.`);
        }

        // 4. Ejecuta la actualización atómica
        t.update(clienteRef, updates);
        functions.logger.log(`Cliente ${clienteId} actualizado con nuevo LTV y estado.`);
    });
});


// 4. Exportación de las funciones de SERVI (IA)
// Estas funciones se importan desde servi_ai.js y se re-exportan para Firebase
export const extractInvoiceData = serviAi.extractInvoiceData;
export const classifyTransaction = serviAi.classifyTransaction;
export const predictClientRecommendations = serviAi.predictClientRecommendations;
export const handleUserQuery = serviAi.handleUserQuery; // El asistente conversacional