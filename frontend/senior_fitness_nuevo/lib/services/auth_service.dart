import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:senior_fitness_app/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Iniciar sesión con email y PIN
  Future<Map<String, dynamic>?> loginWithPin(String email, String pin) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pin,
      );

      final user = userCredential.user;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      return {
        'user_id': user.uid,
        'token': await user.getIdToken(),
        'email': user.email,
        'name': userData['name'] ?? '',
        'age': userData['age'] ?? 0,
        'gender': userData['gender'] ?? '',
        'chronic_conditions': userData['chronic_conditions'] ?? [],
      };
    } catch (e) {
      debugPrint('Error en login: $e');
      return null;
    }
  }

  // ✅ Crear usuario con PIN y rol
  Future<bool> createUser(
    String email,
    String name,
    String pin, {
    int age = 65,
    String gender = 'Masculino',
    List<String> chronicConditions = const ['Ninguna'],
    String role = 'adulto_mayor',
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pin,
      );

      final user = userCredential.user;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'name': name,
        'age': age,
        'gender': gender,
        'chronic_conditions': chronicConditions,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error al crear usuario: $e');
      return false;
    }
  }

  // ✅ Obtener perfil del usuario
  Future<UserProfile?> getCurrentUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserProfile(
        id: userId,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        age: data['age'] ?? 65,
        gender: data['gender'] ?? 'Masculino',
        chronicConditions:
            List<String>.from(data['chronic_conditions'] ?? ['Ninguna']),
        role: data['role'] ?? 'adulto_mayor',
      );
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      return null;
    }
  }

  // ✅ Actualizar perfil (crea el documento si no existe)
  Future<void> updateUserProfile(UserProfile user, String token) async {
    try {
      final doc = await _firestore.collection('users').doc(user.id).get();

      final data = {
        'email': user.email,
        'name': user.name,
        'age': user.age,
        'gender': user.gender,
        'chronic_conditions': user.chronicConditions,
        'role': user.role,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (!doc.exists) {
        data['created_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.id).set(data);
        debugPrint('✅ Usuario creado: ${user.id}');
      } else {
        await _firestore.collection('users').doc(user.id).update(data);
        debugPrint('✅ Usuario actualizado: ${user.id}');
      }
    } catch (e) {
      debugPrint('❌ Error al guardar perfil: $e');
      throw Exception('Error al guardar perfil: $e');
    }
  }

  // ✅ Obtener todos los usuarios (para entrenador)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserProfile(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          age: data['age'] ?? 0,
          gender: data['gender'] ?? 'Masculino',
          chronicConditions:
              List<String>.from(data['chronic_conditions'] ?? ['Ninguna']),
          role: data['role'] ?? 'adulto_mayor',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener usuarios: $e');
      return [];
    }
  }

  // ✅ Obtener ejercicios por condiciones (sin cast innecesario)
  Future<List<Map<String, dynamic>>> getExercisesByCondition(
      List<String> conditions) async {
    try {
      final snapshot = await _firestore.collection('exercises').get();

      final exercises = snapshot.docs.map((doc) => doc.data()).toList();

      if (conditions.isEmpty ||
          conditions.contains('Ninguna') ||
          conditions.contains('ninguna')) {
        return exercises;
      }

      return exercises.where((exercise) {
        final exerciseConditions =
            List<String>.from(exercise['compatible_conditions'] ?? []);
        return conditions
            .any((condition) => exerciseConditions.contains(condition));
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener ejercicios: $e');
      return [];
    }
  }

  // ✅ Actualizar racha
  Future<void> updateUserStreak(String userId, String token) async {
    try {
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final streakRef = _firestore.collection('streaks').doc(userId);
      final streakDoc = await streakRef.get();

      if (!streakDoc.exists) {
        await streakRef.set({
          'current_streak': 1,
          'longest_streak': 1,
          'last_activity_date': todayString,
          'user_id': userId,
        });
        return;
      }

      final streakData = streakDoc.data()!;
      final lastActivityStr = streakData['last_activity_date'];

      if (lastActivityStr == todayString) return;

      final lastActivity = DateTime.parse('$lastActivityStr 00:00:00');
      final difference = today.difference(lastActivity).inDays;

      int newStreak = streakData['current_streak'];
      int longestStreak = streakData['longest_streak'];

      if (difference == 1) {
        newStreak++;
        if (newStreak > longestStreak) longestStreak = newStreak;
      } else if (difference > 1) {
        newStreak = 1;
      }

      await streakRef.update({
        'current_streak': newStreak,
        'longest_streak': longestStreak,
        'last_activity_date': todayString,
      });
    } catch (e) {
      debugPrint('Error al actualizar racha: $e');
      rethrow;
    }
  }

  // ✅ Obtener racha actual
  Future<Map<String, dynamic>> getCurrentStreak(String userId) async {
    try {
      final doc = await _firestore.collection('streaks').doc(userId).get();
      if (!doc.exists) {
        return {'current_streak': 0, 'longest_streak': 0};
      }

      final data = doc.data()!;
      return {
        'current_streak': data['current_streak'] ?? 0,
        'longest_streak': data['longest_streak'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error al obtener racha: $e');
      return {'current_streak': 0, 'longest_streak': 0};
    }
  }
}
