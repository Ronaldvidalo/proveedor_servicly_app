import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- IMPORTAMOS LA LLAVE DE NAVEGACIÓN ---
import 'package:proveedor_servicly_app/core/utils/global_navigation.dart';

// --- IMPORTAMOS LAS PANTALLAS DE DESTINO ---
import 'package:proveedor_servicly_app/features/orders/screens/client_orders_screen.dart'; // Para Cliente
import 'package:proveedor_servicly_app/features/orders/screens/provider_orders_screen.dart'; // Para Proveedor
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart'; // Para Reseñas

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // --- INICIALIZACIÓN ---
  Future<void> init() async {
    // 1. Pedir Permiso
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // 2. Configurar Canales Locales (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones urgentes.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Escuchar mensajes en Primer Plano (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          // Pasamos el tipo en el payload para manejar el tap local
          payload: message.data['type'], 
        );
      }
    });

    // --- CONFIGURAR LA INTERACCIÓN (TAP) ---
    _setupInteractedMessage();
    
    debugPrint("✅ Sistema de Notificaciones Inicializado");
  }

  // --- LÓGICA DE NAVEGACIÓN INTELIGENTE ---
  Future<void> _setupInteractedMessage() async {
    // CASO 1: La app estaba CERRADA
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    // CASO 2: La app estaba en SEGUNDO PLANO
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
    
    // CASO 3: Tap en notificación LOCAL (Primer plano)
    _localNotifications.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
             // Simulamos un RemoteMessage simple para reutilizar la lógica
             _handleMessageNavigation(RemoteMessage(data: {'type': response.payload}));
          }
        }
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type']; 
    
    debugPrint("🚀 Navegando por notificación tipo: $type");

    // --- RUTEADOR DE NOTIFICACIONES ---

    // 1. NUEVA VENTA (Para el Proveedor)
    if (type == 'new_order') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ProviderOrdersScreen()),
      );
    } 
    
    // 2. ACTUALIZACIÓN PARA EL CLIENTE (En camino / Cancelado)
    else if (type == 'order_update_client') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ClientOrdersScreen()),
      );
    } 
    
    // 3. ACTUALIZACIÓN PARA EL PROVEEDOR (Cliente confirmó recepción)
    else if (type == 'order_update_provider') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ProviderOrdersScreen()),
      );
    }

    // 4. NUEVA RESEÑA
    else if (type == 'nueva_resena') {
      final profileId = data['profileId'];
      if (profileId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => PublicProfileScreen(providerId: profileId)),
        );
      }
    }
  }

  // --- GUARDAR TOKEN ---
  Future<void> saveTokenToDatabase() async {
    String? token = await _firebaseMessaging.getToken();
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (token == null || userId == null) return;

    try {
      await _db.collection('users').doc(userId).collection('tokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      debugPrint("❌ Error guardando token: $e");
    }
  }
}