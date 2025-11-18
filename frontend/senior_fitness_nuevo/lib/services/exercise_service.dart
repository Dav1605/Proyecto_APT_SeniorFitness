import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:senior_fitness_app/models/exercise_model.dart';
import 'package:senior_fitness_app/services/gemini_service.dart';
import 'package:senior_fitness_app/prompts/sofi_prompts.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();
  final _random = Random();

  /// 🔹 Obtiene ejercicios personalizados según el perfil del usuario.
  Future<List<Exercise>> recommendedForUser({required String userId}) async {
    try {
      final userSnap = await _firestore.collection('users').doc(userId).get();
      if (!userSnap.exists) throw Exception('Usuario no encontrado');

      final userData = userSnap.data()!;
      final String name = userData['name'] ?? 'Usuario';
      final int age = (userData['age'] ?? 60).toInt();
      final int xp = (userData['xp'] ?? 0).toInt();
      final List<String> conditions =
          List<String>.from(userData['chronic_conditions'] ?? []);

      final String level = _determineLevel(xp);
      debugPrint('🎯 Nivel de $name: $level ($xp XP)');
      debugPrint('⚕️ Condiciones médicas: ${conditions.join(", ")}');

      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month}-${today.day}";
      final userExercisesRef =
          _firestore.collection('users').doc(userId).collection('exercises');

      // 🔍 Buscar ejercicios del día actual
      final existing = await userExercisesRef.get();
      final todayExercises = existing.docs
          .where((d) => (d.data()['date'] ?? '') == dateKey)
          .map((d) => Exercise.fromMap(d.data()..['id'] = d.id))
          .toList();

      if (todayExercises.isNotEmpty &&
          todayExercises.any((e) => e.completed == false)) {
        debugPrint("📅 Ya existen ejercicios activos para hoy");
        return todayExercises;
      }

      // 🔹 Generar nueva rutina personalizada
      debugPrint("🧠 Generando rutina nueva con Sofi IA...");
      final newExercises = await _generatePersonalizedExercises(
          userId, name, age, level, conditions);

      // Limpiar ejercicios viejos del día
      for (final d in existing.docs) {
        if ((d.data()['date'] ?? '') == dateKey) await d.reference.delete();
      }

      // Guardar nuevos ejercicios en Firestore
      for (final ex in newExercises) {
        await userExercisesRef.doc(ex.id).set({
          ...ex.toMap(),
          'date': dateKey,
          'completed': false,
          'level': level,
        });
      }

      return newExercises;
    } catch (e) {
      debugPrint('❌ Error en recommendedForUser: $e');
      return _defaultExercises();
    }
  }

  String _determineLevel(int xp) {
    if (xp < 200) return 'Principiante';
    if (xp < 500) return 'Intermedio';
    return 'Avanzado';
  }

  /// 🧠 Usa Gemini para generar ejercicios personalizados según edad, nivel y enfermedades.
  Future<List<Exercise>> _generatePersonalizedExercises(
    String userId,
    String name,
    int age,
    String level,
    List<String> conditions,
  ) async {
    try {
      final prompt = '''
${SofiPrompts.extraExercises}

Información del usuario:
- Nombre: $name
- Edad: $age años
- Nivel actual: $level
- Condiciones médicas: ${conditions.isEmpty ? "Ninguna" : conditions.join(", ")}

Adapta los ejercicios considerando estas condiciones:
- Si hay artrosis o problemas articulares → evita saltos o impacto.
- Si hay hipertensión → evita ejercicios de alta intensidad o retención de respiración.
- Si hay diabetes → incluye ejercicios suaves de movilidad y estiramiento.
- Si hay problemas cardíacos → prioriza caminatas suaves y ejercicios respiratorios.
- Si no hay condiciones → permite variación normal.

Devuelve entre 4 y 7 ejercicios variados, siempre en formato JSON válido.
''';

      final response =
          await _geminiService.generateDynamicResponse(prompt, userId: userId);

      final match = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (match == null) {
        debugPrint('⚠️ Gemini no devolvió JSON válido, usando fallback.');
        return _defaultExercises();
      }

      final List<dynamic> decoded = jsonDecode(match.group(0)!);
      final exercises = decoded.map((e) {
        return Exercise(
          id: _firestore.collection('tmp').doc().id,
          title: e['title'] ?? 'Ejercicio personalizado',
          description: e['description'] ?? 'Actividad recomendada por Sofi 💙',
          difficultyLevel: e['difficultyLevel'] ?? 'Fácil',
          durationMinutes: (e['durationMinutes'] ?? 10).toInt(),
          compatibleConditions: conditions,
          precautions: [],
          completed: false,
        );
      }).toList();

      debugPrint("✅ Sofi generó ${exercises.length} ejercicios personalizados");
      return exercises;
    } catch (e) {
      debugPrint('❌ Error generando ejercicios personalizados: $e');
      return _defaultExercises();
    }
  }

  /// ✅ Suma XP cuando el usuario completa un ejercicio
  Future<void> completeExercise(String userId, Exercise exercise) async {
    try {
      final exerciseRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exercise.id);

      await exerciseRef.set(
          {...exercise.toMap(), 'completed': true}, SetOptions(merge: true));

      int xpGain = switch (exercise.difficultyLevel.toLowerCase()) {
        'media' => 20,
        'alta' || 'difícil' => 30,
        _ => 10,
      };

      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final currentXp = (snap['xp'] ?? 0) as int;
        transaction.update(userRef, {'xp': currentXp + xpGain});
      });

      debugPrint("🎯 Ejercicio completado: +$xpGain XP (${exercise.title})");
    } catch (e) {
      debugPrint('❌ Error al sumar XP: $e');
    }
  }

  List<Exercise> _defaultExercises() {
    return [
      Exercise(
        id: _firestore.collection('tmp').doc().id,
        title: 'Caminata ligera',
        description: 'Camina a paso tranquilo durante 10 minutos. 🚶‍♂️',
        difficultyLevel: 'Fácil',
        durationMinutes: 10,
        compatibleConditions: ['Ninguna'],
        precautions: ['Evita terrenos irregulares', 'Hidrátate bien 💧'],
      ),
      Exercise(
        id: _firestore.collection('tmp').doc().id,
        title: 'Estiramientos suaves',
        description: 'Estira brazos y piernas lentamente por 8 minutos. 🤸‍♀️',
        difficultyLevel: 'Fácil',
        durationMinutes: 8,
        compatibleConditions: ['Ninguna'],
        precautions: ['No fuerces el movimiento', 'Respira profundo 🧘‍♂️'],
      ),
      Exercise(
        id: _firestore.collection('tmp').doc().id,
        title: 'Levantamiento de brazos sentado',
        description: 'Siéntate y levanta los brazos 10 veces. 💪',
        difficultyLevel: 'Media',
        durationMinutes: 6,
        compatibleConditions: ['Ninguna'],
        precautions: ['Evita movimientos bruscos'],
      ),
    ];
  }
}
