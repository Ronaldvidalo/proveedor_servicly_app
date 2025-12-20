// functions/index.js (CORREGIDO - ERROR DE REDECLARACIÓN ELIMINADO)

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

// Configuración Global (Opcional)
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

// Al usar 'export const' aquí, YA SE ESTÁ EXPORTANDO. No hace falta repetirlo al final.
export const notifyOnNewReview = onDocumentCreated('artifacts/{appId}/public/reviews/items/{reviewId}', async(event) => {
    const reviewData = event.data.data();

    const targetId = reviewData ? reviewData.targetId : null;
    const authorId = reviewData ? reviewData.authorId : null;
    const newRating = reviewData ? reviewData.rating : null;

    if (!targetId || !newRating) return null;

    try {
        // Obtener nombre autor
        const authorDoc = await db.collection('users').doc(authorId).get();
        const authorName = (authorDoc.exists && authorDoc.data().display_name) ? authorDoc.data().display_name : "Un usuario";

        const targetUserRef = db.collection('users').doc(targetId);
        let tokens = [];

        await db.runTransaction(async(transaction) => {
            const userDoc = await transaction.get(targetUserRef);
            if (!userDoc.exists) throw new Error("Usuario no existe");

            const userData = userDoc.data();
            tokens = userData.fcmTokens || [];

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

// --- NUEVO TRIGGER: NOTIFICACIÓN DE NUEVA VENTA ---

// Al usar 'export const' aquí, YA SE ESTÁ EXPORTANDO.
export const notifyOnNewOrder = onDocumentCreated('orders/{orderId}', async(event) => {
    const orderData = event.data.data();
    if (!orderData) return;

    const providerId = orderData.providerId;
    const clientName = orderData.clientName || "Un cliente";
    const totalAmount = orderData.total || 0;

    if (!providerId) {
        logger.error("La orden no tiene providerId");
        return;
    }

    try {
        // 1. Buscar al proveedor para obtener sus Tokens FCM
        const providerDoc = await db.collection('users').doc(providerId).get();

        if (!providerDoc.exists) {
            logger.warn(`Proveedor ${providerId} no encontrado.`);
            return;
        }

        const providerData = providerDoc.data();
        const tokens = providerData.fcmTokens || [];

        if (tokens.length === 0) {
            logger.info(`El proveedor ${providerId} no tiene tokens FCM registrados.`);
            return;
        }

        // 2. Crear el mensaje Push
        const message = {
            notification: {
                title: "¡Nueva Venta! 💰",
                body: `${clientName} te compró por $${totalAmount}. Revisa el comprobante.`
            },
            data: {
                type: "new_order",
                orderId: event.params.orderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            tokens: tokens,
        };

        // 3. Enviar
        const response = await messaging.sendEachForMulticast(message);
        logger.info(`Notificación enviada: ${response.successCount} éxitos, ${response.failureCount} fallos.`);

    } catch (error) {
        logger.error("Error en notifyOnNewOrder:", error);
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

// Exports de Servi AI (Estos SÍ se quedan porque vienen importados de otro archivo como 'serviAi')
export const extractInvoiceData = serviAi.extractInvoiceData;
export const classifyTransaction = serviAi.classifyTransaction;
export const predictClientRecommendations = serviAi.predictClientRecommendations;
export const handleUserQuery = serviAi.handleUserQuery;

// --- YA NO PONEMOS LAS OTRAS EXPORTACIONES AQUÍ PORQUE YA ESTÁN ARRIBA ---