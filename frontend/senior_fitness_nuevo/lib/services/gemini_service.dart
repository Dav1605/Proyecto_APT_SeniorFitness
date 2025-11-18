import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';

/// 💙 Servicio Sofi IA (Gemini) – Generador de mensajes y ejercicios personalizados
class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Recomendación diaria personalizada (para Home o Perfil)
  Future<String> getPersonalizedRecommendation(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists)
        throw Exception('Usuario no encontrado en Firestore.');

      final userData = userDoc.data() ?? {};
      final String name = userData['name'] ?? 'Usuario';
      final int age = (userData['age'] ?? 65).toInt();
      final String gender = userData['gender'] ?? 'Masculino';
      final List<String> conditions = List<String>.from(
        userData['chronic_conditions'] ?? ['Ninguna'],
      );
      final String lastActivity =
          userData['last_exercise_completed'] ?? 'ninguna registrada';

      // 🔀 Baraja condiciones para que las respuestas varíen
      final safeConditions = List<String>.from(conditions)..shuffle(Random());

      final prompt =
          """
Eres Sofi 💙, una entrenadora virtual para adultos mayores.
Crea un MENSAJE CORTO y motivacional para $name ($age años, ${gender.toLowerCase()}).
Tiene las siguientes condiciones: ${safeConditions.join(', ')}.
Su última actividad fue: $lastActivity.
Usa un tono positivo y empático. Puedes incluir 1–2 emojis naturales.
Evita tecnicismos, frases largas o listas.
""";

      final response = await _callGeminiAPI(prompt, userId: userId);
      return response ??
          "🌿 Sofi dice: ¡Hoy es un gran día para moverse y sentirse bien!";
    } catch (e) {
      debugPrint('⚠️ Error en getPersonalizedRecommendation: $e');
      return "💬 Sofi dice: ¡Respira profundo, sonríe y sigue adelante! 💪";
    }
  }

  /// 💬 Respuesta dinámica genérica: usada por múltiples pantallas
  Future<String> generateDynamicResponse(
    String prompt, {
    String? userId,
  }) async {
    try {
      final response = await _callGeminiAPI(prompt, userId: userId);
      return response ??
          "💡 Sofi no puede responder ahora, pero te recordará moverte pronto 💙";
    } catch (e) {
      debugPrint('⚠️ Error en generateDynamicResponse: $e');
      return "⚠️ Sofi dice: No logré responder en este momento. Intenta más tarde 💪";
    }
  }

  /// 🌐 Llamada central al endpoint de Gemini (maneja JSON o texto)
  Future<String?> _callGeminiAPI(String prompt, {String? userId}) async {
    try {
      final url = Uri.parse(
        'https://generateexerciserecommendation-l2xuzgiifa-uc.a.run.app',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          if (userId != null) 'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Error API Gemini: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      final rawText = data['recommendation']?.toString().trim();
      if (rawText == null || rawText.isEmpty) return null;

      final sanitized = _sanitizeResponse(rawText);

      // 🔍 Determinar si contiene estructura JSON
      final hasJson = sanitized.contains('[') || sanitized.contains('{');
      if (hasJson) {
        final match = RegExp(r'\[[\s\S]*\]').firstMatch(sanitized);
        if (match != null) {
          final jsonBlock = match.group(0)!;
          debugPrint('✅ Gemini devolvió JSON válido:\n$jsonBlock');
          return jsonBlock;
        }
        debugPrint('⚠️ JSON detectado pero no extraído correctamente.');
      } else {
        debugPrint('✅ Gemini devolvió texto motivacional:\n$sanitized');
      }

      return sanitized;
    } catch (e) {
      debugPrint('⚠️ Error al conectar con Gemini: $e');
      return null;
    }
  }

  /// 🧹 Limpieza y normalización de la respuesta
  String _sanitizeResponse(String raw) {
    String cleaned = raw
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .replaceAll("\\n", "\n")
        .replaceAll("\\\"", "\"")
        .trim();

    // Extraer solo el bloque JSON si existe
    final match = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(0)!;
    }

    return cleaned;
  }

  /// 🧠 Obtiene el ID real del usuario desde el endpoint checkUser
  Future<String?> fetchRealUserId(String email) async {
    try {
      final url = Uri.parse(
        'https://checkuser-l2xuzgiifa-uc.a.run.app/?email=$email',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint('⚠️ Error al validar usuario: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['found'] == true && data['realUserId'] != null) {
        debugPrint('✅ Usuario encontrado con ID: ${data['realUserId']}');
        return data['realUserId'];
      }

      debugPrint('❌ Usuario no encontrado en Firestore (checkUser)');
      return null;
    } catch (e) {
      debugPrint('⚠️ Error en fetchRealUserId: $e');
      return null;
    }
  }
}
