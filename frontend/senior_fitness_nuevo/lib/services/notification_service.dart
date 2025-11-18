import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senior_fitness_app/services/gemini_service.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

/// Servicio de notificaciones diarias personalizadas con Sofi IA 🤖
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  /// Inicializa las notificaciones locales y zonas horarias
  Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  /// Programa una notificación diaria con IA personalizada 💬
  Future<void> scheduleDailySmartReminder(String userId) async {
    try {
      // Obtener mensaje IA
      final aiMessage =
          await _geminiService.getPersonalizedRecommendation(userId);

      // Calcular hora aleatoria (ej. entre 9:00 y 11:00)
      final randomHour = 9 + Random().nextInt(2);
      final scheduledTime = tz.TZDateTime.now(tz.local)
          .add(Duration(hours: randomHour - DateTime.now().hour))
          .add(const Duration(minutes: 0));

      const androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Recordatorios Sofi',
        channelDescription: 'Notificaciones diarias personalizadas de Sofi',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

      await _notificationsPlugin.zonedSchedule(
        0,
        '💪 Sofi te recuerda...',
        aiMessage,
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repite cada día
      );

      debugPrint('✅ Notificación diaria programada: $aiMessage');
    } catch (e) {
      debugPrint('❌ Error al programar notificación diaria: $e');
    }
  }

  /// Enviar una notificación instantánea (por ejemplo al iniciar sesión)
  Future<void> showInstantNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Mensajes Sofi',
      channelDescription: 'Mensajes inmediatos personalizados de Sofi',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      1,
      '💬 Sofi dice...',
      message,
      details,
    );
  }

  /// Actualiza automáticamente los mensajes diarios según Firestore
  Future<void> updateDailyMessagesFromFirestore(String userId) async {
    try {
      final userDoc = await _firestore.collection('streaks').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final streak = data['current_streak'] ?? 0;

      final aiMessage =
          await _geminiService.getPersonalizedRecommendation(userId);

      final scheduledTime =
          tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

      await _notificationsPlugin.zonedSchedule(
        2,
        '🔥 Tu progreso con Sofi',
        'Llevas $streak días seguidos 🏆\n$aiMessage',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'update_channel',
            'Recordatorios IA',
            channelDescription: 'Actualización diaria de motivación de Sofi',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Notificación IA actualizada para $userId');
    } catch (e) {
      debugPrint('❌ Error al actualizar recordatorios IA: $e');
    }
  }
}
