import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Incrementa el XP del usuario cuando completa un ejercicio.
  Future<void> addXp(String userId, {int xpGain = 10}) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        debugPrint('⚠️ Usuario no encontrado en Firestore.');
        return;
      }

      final data = userDoc.data()!;
      int currentXp = data['xp_points'] ?? 0;
      int level = data['level'] ?? 1;

      currentXp += xpGain;

      // 🔹 Subir de nivel si llega a 100 XP
      if (currentXp >= 100) {
        level += 1;
        currentXp -= 100;

        debugPrint('🎯 ¡Nivel aumentado! Nuevo nivel: $level');
      }

      await userRef.update({
        'xp_points': currentXp,
        'level': level,
        'last_exercise_completed': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ XP actualizado: +$xpGain (total: $currentXp)');
    } catch (e) {
      debugPrint('❌ Error al actualizar XP: $e');
    }
  }
}
