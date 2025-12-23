// functions/index.js (ACTUALIZADO PARA FLUTTER SUBCOLLECTION TOKENS)

// 1. Importaciones V2 (Triggers Modernos)
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { logger } from 'firebase-functions';

// 2. Importaciones V1 (Legacy - NECESARIO PARA RECALCULATE RANKING ANTIGUO)
import * as v1 from 'firebase-functions/v1';

// 3. Admin SDK
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

// 4. Importar funciones de IA
import * as serviAi from './servi_ai.js';

// Configuración Global
setGlobalOptions({ maxInstances: 10 });

// Inicialización
const app = initializeApp();
const db = getFirestore();
const messaging = getMessaging(app);

// --- Utilidades ---

const updateClienteCount = async(providerId) => {
    try {
        const snapshot = await db.collection('users').doc(providerId).collection('clientes').count().get();
        const count = snapshot.data().count || 0;

        await db.collection('users').doc(providerId).update({
            clienteCount: count,
            lastUpdated: FieldValue.serverTimestamp(),
        });
    } catch (e) {
        logger.error("Error updating client count", e);
    }
};

// --- HELPER: OBTENER TOKENS DE SUBCOLECCIÓN ---
// (Necesario porque Flutter guarda los tokens en users/{uid}/tokens/{token})
const getUserTokens = async(userId) => {
    try {
        const tokensSnapshot = await db.collection('users').doc(userId).collection('tokens').get();
        // Mapeamos los IDs de los documentos, ya que en Flutter usamos doc(token).set(...)
        return tokensSnapshot.docs.map(doc => doc.id);
    } catch (error) {
        logger.error(`Error obteniendo tokens para ${userId}:`, error);
        return [];
    }
};

// --- Triggers V2 (CRM & SISTEMA NUEVO) ---

export const onClienteCreated = onDocumentCreated('users/{providerId}/clientes/{clienteId}', async(event) => {
    const providerId = event.params.providerId;
    const clienteData = event.data.data();
    const nombre = clienteData ? clienteData.nombreCompleto : 'Desconocido';

    logger.info(`Nuevo cliente creado para ${providerId}: ${nombre}`);
    await updateClienteCount(providerId);
});

export const onClienteDeleted = onDocumentDeleted('users/{providerId}/clientes/{clienteId}', async(event) => {
    const providerId = event.params.providerId;
    logger.info(`Cliente eliminado para ${providerId}.`);
    await updateClienteCount(providerId);
});

export const onCobroPagado = onDocumentUpdated('users/{providerId}/cobros/{cobroId}', async(event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();
    const providerId = event.params.providerId;

    if (after.estado !== 'COBRADO' || before.estado === 'COBRADO') return null;

    const clienteId = after.clienteId;
    const montoCobrado = after.monto || 0;

    if (!clienteId) return null;

    const clienteRef = db.collection('users').doc(providerId).collection('clientes').doc(clienteId);

    return db.runTransaction(async(t) => {
        const clienteDoc = await t.get(clienteRef);
        if (!clienteDoc.exists) return;

        const clienteData = clienteDoc.data();
        const currentLTV = clienteData.montoTotalFacturado || 0;
        const updates = {
            montoTotalFacturado: currentLTV + montoCobrado,
            ultimaInteraccion: FieldValue.serverTimestamp()
        };

        if (clienteData.estadoCRM && clienteData.estadoCRM.startsWith('LEAD')) {
            updates.estadoCRM = 'CLIENTE_ACTIVO';
        }

        t.update(clienteRef, updates);
    });
});

// --- RANKING SYSTEM (V2 - NUEVO) ---

export const notifyOnNewReview = onDocumentCreated('artifacts/{appId}/public/reviews/items/{reviewId}', async(event) => {
    const reviewData = event.data.data();

    const targetId = reviewData ? reviewData.targetId : null;
    const authorId = reviewData ? reviewData.authorId : null;
    const newRating = reviewData ? reviewData.rating : null;

    if (!targetId || !newRating) return null;

    try {
        const authorDoc = await db.collection('users').doc(authorId).get();
        const authorName = (authorDoc.exists && authorDoc.data().display_name) ? authorDoc.data().display_name : "Un usuario";

        const targetUserRef = db.collection('users').doc(targetId);

        // 1. Calcular nuevo promedio
        await db.runTransaction(async(transaction) => {
            const userDoc = await transaction.get(targetUserRef);
            if (!userDoc.exists) throw new Error("Usuario no existe");

            const userData = userDoc.data();
            const currentCount = userData.ratingCount || 0;
            const currentAvg = userData.ratingAvg || 0.0;
            const newCount = currentCount + 1;
            const newAvg = ((currentAvg * currentCount) + newRating) / newCount;

            transaction.update(targetUserRef, {
                ratingCount: newCount,
                ratingAvg: Number(newAvg.toFixed(2)),
                lastReviewDate: FieldValue.serverTimestamp()
            });
        });

        // 2. Obtener Tokens (CORREGIDO: Busca en subcolección)
        const tokens = await getUserTokens(targetId);

        if (tokens.length > 0) {
            const emoji = newRating >= 4 ? "🌟" : "👍";
            const message = {
                notification: {
                    title: `¡Nueva calificación! ${emoji}`,
                    body: `${authorName} te dio ${newRating} estrellas.`
                },
                data: {
                    type: "nueva_resena",
                    profileId: targetId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                tokens: tokens,
            };
            await messaging.sendEachForMulticast(message);
        }
        return { success: true };
    } catch (error) {
        logger.error("Error en notifyOnNewReview", error);
        return { success: false };
    }
});

// --- MARKETPLACE & PEDIDOS (V2) ---

// 1. NOTIFICAR AL PROVEEDOR (Nueva Venta)
export const notifyOnNewOrder = onDocumentCreated('orders/{orderId}', async(event) => {
    const orderData = event.data.data();
    if (!orderData) return;

    const providerId = orderData.providerId;
    const clientName = orderData.clientName || "Un cliente";
    const totalAmount = orderData.total || 0;

    if (!providerId) return;

    try {
        // CORREGIDO: Busca en subcolección 'tokens'
        const tokens = await getUserTokens(providerId);

        if (tokens.length === 0) {
            logger.info(`El proveedor ${providerId} no tiene tokens registrados.`);
            return;
        }

        const message = {
            notification: {
                title: "¡Nueva Venta! 💰",
                body: `${clientName} te compró por $${totalAmount}. Revisa el pedido.`
            },
            data: {
                type: "new_order",
                orderId: event.params.orderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            tokens: tokens,
        };

        const response = await messaging.sendEachForMulticast(message);
        logger.info(`Notificación Venta enviada: ${response.successCount} éxitos.`);

    } catch (error) {
        logger.error("Error en notifyOnNewOrder:", error);
    }
});

// 2. NOTIFICAR AL CLIENTE (Cambio de Estado) - ¡NUEVO!
export const notifyOrderStatus = onDocumentUpdated('orders/{orderId}', async(event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // Si el estado no cambió, no hacemos nada
    if (newData.status === oldData.status) return null;

    const newStatus = newData.status;
    const orderId = event.params.orderId;

    let targetUserId = "";
    let title = "";
    let body = "";
    let notificationType = ""; // Para saber a qué pantalla ir en Flutter

    // --- CASO 1: PROVEEDOR PROGRAMÓ EL ENVÍO (inProgress) ---
    // Destino: Cliente
    if (newStatus === 'inProgress') {
        targetUserId = newData.clientId;
        title = "🚚 ¡Tu pedido está en camino!";
        body = newData.providerNote ?
            `Nota del proveedor: ${newData.providerNote}` :
            "El proveedor ha programado la entrega/retiro.";
        notificationType = "order_update_client"; // Ir a Mis Compras
    }

    // --- CASO 2: CLIENTE CONFIRMÓ RECEPCIÓN (completed) ---
    // Destino: Proveedor
    else if (newStatus === 'completed') {
        targetUserId = newData.providerId;
        title = "✅ Entrega Confirmada";
        body = `El cliente ${newData.clientName || 'Usuario'} confirmó que recibió el pedido.`;
        notificationType = "order_update_provider"; // Ir a Gestión de Pedidos
    }

    // --- CASO 3: PEDIDO CANCELADO (cancelled) ---
    // Destino: Cliente (asumiendo que el proveedor cancela usualmente)
    else if (newStatus === 'cancelled') {
        targetUserId = newData.clientId;
        title = "Pedido Cancelado ❌";
        body = "El proveedor ha cancelado la orden.";
        notificationType = "order_update_client";
    }

    // Si no hay target, salimos
    if (!targetUserId) return null;

    try {
        // Obtenemos tokens del usuario destino
        const tokens = await getUserTokens(targetUserId);

        if (tokens.length === 0) {
            logger.info(`El usuario ${targetUserId} no tiene tokens.`);
            return null;
        }

        const message = {
            notification: { title, body },
            data: {
                type: notificationType, // Usamos esto en Flutter para navegar
                orderId: orderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            tokens: tokens,
        };

        const response = await messaging.sendEachForMulticast(message);
        logger.info(`Notificación (${newStatus}) enviada a ${targetUserId}: ${response.successCount} éxitos.`);

    } catch (error) {
        logger.error("Error en notifyOrderStatus:", error);
    }
});

// --- TRIGGERS V1 (LEGACY) ---

export const recalculateRankingV1 = v1.firestore.document('ratings/{ratingId}')
    .onCreate(async(snapshot, context) => {
        try {
            const newRatingData = snapshot.data();
            const valoradoId = newRatingData.valorado_id;

            if (!valoradoId) return null;

            await db.runTransaction(async(transaction) => {
                const ratingsRef = db.collection('ratings').where('valorado_id', '==', valoradoId);
                const ratingsSnapshot = await transaction.get(ratingsRef);

                if (ratingsSnapshot.empty) return;

                let sumScores = 0;
                ratingsSnapshot.docs.forEach(doc => {
                    sumScores += (doc.data().puntuacion_estrellas) || 0;
                });

                const N = ratingsSnapshot.size;
                const R = sumScores / N;

                const userMetricRef = db.collection('tienda').doc(valoradoId);
                transaction.set(userMetricRef, {
                    ranking_promedio: parseFloat(R.toFixed(1)),
                    total_valoraciones: N,
                    last_calculated: FieldValue.serverTimestamp(),
                }, { merge: true });
            });
        } catch (error) {
            logger.error("[RECALC ERROR V1]", error);
        }
        return null;
    });

// Exports de Servi AI
export const extractInvoiceData = serviAi.extractInvoiceData;
export const classifyTransaction = serviAi.classifyTransaction;
export const predictClientRecommendations = serviAi.predictClientRecommendations;
export const handleUserQuery = serviAi.handleUserQuery;