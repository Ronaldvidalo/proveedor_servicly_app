/**
 * LÓGICA DE BACKEND PARA EL MÓDULO CRM (CLIENT-MANAGEMENT)
 * * Este archivo contiene las Cloud Functions que automatizan el flujo de trabajo CRM
 * (Lead-to-Client) y controlan el límite de contactos para la versión gratuita.
 *
 * NOTA: Usa la sintaxis moderna del SDK v2, que corrige el error 'functions.firestore.document is not a function'.
 */

// Importa los módulos necesarios
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require('firebase-functions/v2/firestore');

// Inicializa la app de Firebase Admin
initializeApp();
const db = getFirestore();

// --- Utilidades ---
/**
 * Obtiene el documento de control del usuario para el plan y el contador de clientes.
 * @param {string} userId - ID del usuario.
 * @returns {Promise<FirebaseFirestore.DocumentSnapshot>} Snapshot del documento.
 */
const getUserData = async(userId) => {
    return db.collection('users').doc(userId).get();
};

/**
 * Función genérica para incrementar o decrementar el contador de clientes del usuario.
 * @param {string} userId - ID del usuario.
 * @param {number} amount - Cantidad a incrementar (1) o decrementar (-1).
 */
const updateClienteCount = async(userId, amount) => {
    const userRef = db.collection('users').doc(userId);

    // Transacción atómica para garantizar la integridad del contador
    await db.runTransaction(async(t) => {
        const userDoc = await t.get(userRef);

        if (userDoc.exists) {
            const currentCount = userDoc.data().clienteCount || 0;
            const newCount = currentCount + amount;

            // Si el nuevo conteo cae por debajo de cero, lo establecemos en cero (prevención)
            t.update(userRef, {
                clienteCount: newCount < 0 ? 0 : newCount
            });
        }
    });
};


// --- 1. Control de Límites para Versión FREE ---

/**
 * 1.1. Se activa cuando se crea un nuevo documento en /users/{userId}/clientes/{clienteId}.
 * Incrementa el contador total de clientes del usuario.
 */
exports.onClienteCreated = onDocumentCreated('users/{userId}/clientes/{clienteId}', async(event) => {
    const userId = event.params.userId;
    if (!userId) {
        console.error("No se pudo obtener el userId.");
        return;
    }

    console.log(`Cliente creado para el usuario: ${userId}. Incrementando contador.`);
    return updateClienteCount(userId, 1);
});

/**
 * 1.2. Se activa cuando se elimina un documento en /users/{userId}/clientes/{clienteId}.
 * Decrementa el contador total de clientes del usuario.
 */
exports.onClienteDeleted = onDocumentDeleted('users/{userId}/clientes/{clienteId}', async(event) => {
    const userId = event.params.userId;
    if (!userId) {
        console.error("No se pudo obtener el userId.");
        return;
    }

    console.log(`Cliente eliminado para el usuario: ${userId}. Decrementando contador.`);
    return updateClienteCount(userId, -1);
});


// --- 2. Integración Crítica con el Módulo de Finanzas (Lógica de Conversión) ---

/**
 * 2.1. Se activa cuando un documento en la colección 'cobros' (del módulo de Finanzas)
 * es creado o actualizado, y el estado cambia a 'COBRADO'.
 * Esta función automatiza la promoción de un LEAD a CLIENTE y calcula el LTV.
 *
 * RUTA ASUMIDA: /users/{userId}/cobros/{cobroId}
 * Condición: (after.data().estado === 'COBRADO') && (before.data().estado !== 'COBRADO')
 */
exports.onCobroPagado = onDocumentUpdated('users/{userId}/cobros/{cobroId}', async(event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();
    const userId = event.params.userId;

    // Verificación 1: Debe ser un cambio de estado a COBRADO
    if (after.estado !== 'COBRADO' || before.estado === 'COBRADO') {
        console.log("Cobro no completado o ya procesado. Terminando función.");
        return null;
    }

    const clienteId = after.clienteId;
    const montoCobrado = after.monto || 0;

    if (!clienteId) {
        console.warn(`Cobro ${event.params.cobroId} no tiene clienteId. Saltando actualización de CRM.`);
        return null;
    }

    const clienteRef = db.collection('users').doc(userId).collection('clientes').doc(clienteId);

    // Transacción para garantizar la integridad del montoTotalFacturado
    return db.runTransaction(async(t) => {
        const clienteDoc = await t.get(clienteRef);

        if (!clienteDoc.exists) {
            console.error(`Cliente ID: ${clienteId} no encontrado.`);
            return;
        }

        const clienteData = clienteDoc.data();
        const clienteEstado = clienteData.estadoCRM;

        const updates = {};

        // 1. Actualizar LTV: Incrementa el montoTotalFacturado
        const currentLTV = clienteData.montoTotalFacturado || 0;
        updates.montoTotalFacturado = currentLTV + montoCobrado;

        // 2. Actualizar Última Interacción
        updates.ultimaInteraccion = new Date();

        // 3. Lógica de Conversión (si el cliente era un LEAD)
        if (clienteEstado && clienteEstado.startsWith('LEAD')) {
            // Convierte cualquier estado LEAD (NUEVO, CONTACTADO, COTIZADO) a CLIENTE_ACTIVO
            updates.estadoCRM = 'CLIENTE_ACTIVO';
            console.log(`LEAD ${clienteId} convertido automáticamente a CLIENTE_ACTIVO.`);
        }

        // 4. Ejecuta la actualización atómica
        t.update(clienteRef, updates);
        console.log(`Cliente ${clienteId} actualizado con nuevo LTV y estado.`);
    });
});