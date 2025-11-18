class UserProfile {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final List<String> chronicConditions;
  final String role; // ✅ Diferencia entre "adulto_mayor" y "entrenador"

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.chronicConditions,
    required this.role,
  });

  // ✅ Convertir el objeto a JSON (para guardar en Firestore)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'chronic_conditions': chronicConditions,
      'role': role,
    };
  }

  // ✅ Crear un objeto desde JSON (desde Firestore o API)
  factory UserProfile.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserProfile(
      id: id ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      age: (json['age'] is int)
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender'] ?? '',
      chronicConditions: List<String>.from(
        json['chronic_conditions'] ?? <String>['Ninguna'],
      ),
      role: json['role'] ?? 'adulto_mayor',
    );
  }

  // ✅ Verifica si el perfil está completo
  bool get isComplete =>
      email.isNotEmpty && name.isNotEmpty && age >= 50 && gender.isNotEmpty;

  // ✅ Devuelve un string legible de las condiciones
  String get conditionsDisplay {
    if (chronicConditions.isEmpty ||
        chronicConditions.contains('Ninguna') ||
        chronicConditions.contains('ninguna')) {
      return 'Ninguna condición médica reportada';
    }
    return chronicConditions.join(', ');
  }

  // ✅ Permite clonar el objeto con cambios parciales
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? gender,
    List<String>? chronicConditions,
    String? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      role: role ?? this.role,
    );
  }

  // ✅ Método extra: crea una instancia vacía (útil para inicializar estados)
  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      email: '',
      name: '',
      age: 0,
      gender: '',
      chronicConditions: const ['Ninguna'],
      role: 'adulto_mayor',
    );
  }
}
