// lib/models/exercise_model.dart

/// Modelo base de un ejercicio físico generado por Sofi o Firestore.
class Exercise {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String difficultyLevel; // 🔹 Nivel de dificultad (Fácil / Media / Alta)
  final List<String> compatibleConditions; // 🔹 Condiciones compatibles
  final List<String> precautions; // 🔹 Precauciones médicas
  final bool completed; // 🔹 Estado de finalización del ejercicio

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.difficultyLevel,
    required this.compatibleConditions,
    this.precautions = const [],
    this.completed = false,
  });

  /// Crea una instancia a partir de un mapa de Firestore.
  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        durationMinutes: (map['durationMinutes'] ?? 10) is int
            ? map['durationMinutes']
            : int.tryParse(map['durationMinutes'].toString()) ?? 10,
        difficultyLevel:
            map['difficultyLevel'] ?? map['level'] ?? 'Baja', // compatibilidad
        compatibleConditions:
            List<String>.from(map['compatibleConditions'] ?? const []),
        precautions: List<String>.from(map['precautions'] ?? const []),
        completed: map['completed'] ?? false,
      );

  /// Convierte el ejercicio a un mapa (para guardar en Firestore).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'difficultyLevel': difficultyLevel,
        'compatibleConditions': compatibleConditions,
        'precautions': precautions,
        'completed': completed,
      };

  /// Permite clonar y actualizar propiedades específicas del ejercicio.
  Exercise copyWith({
    String? id,
    String? title,
    String? description,
    int? durationMinutes,
    String? difficultyLevel,
    List<String>? compatibleConditions,
    List<String>? precautions,
    bool? completed,
  }) {
    return Exercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      compatibleConditions: compatibleConditions ?? this.compatibleConditions,
      precautions: precautions ?? this.precautions,
      completed: completed ?? this.completed,
    );
  }
}
