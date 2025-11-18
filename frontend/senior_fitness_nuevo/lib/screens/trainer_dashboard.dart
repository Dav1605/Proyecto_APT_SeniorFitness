import 'package:flutter/material.dart';
import 'package:senior_fitness_app/services/auth_service.dart';
import 'package:senior_fitness_app/models/user.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  final AuthService _authService = AuthService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todos los usuarios (en producción, solo los asignados al entrenador)
      // Por ahora, obtenemos todos los usuarios
      final users =
          await _authService.getAllUsers(); // Añade este método en AuthService

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard del Entrenador'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(user.name.substring(0, 1)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Edad: ${user.age}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Condiciones: ${user.conditionsDisplay}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ejercicios programados:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Aquí mostrarías los ejercicios programados para este usuario
                        const Text(
                          'Caminata ligera - Fácil - 30 min',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Yoga suave - Fácil - 20 min',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Estado de completitud:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✅ Completado hoy',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Racha actual: 5 días consecutivos',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Activar sonido en el celular del usuario
                                _activateSound(user.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Activar Sonido'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Enviar mensaje de recordatorio
                                _sendReminder(user.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Enviar Recordatorio'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _activateSound(String userId) async {
    // Lógica para activar sonido en el celular del usuario
    debugPrint('Activando sonido para usuario: $userId');
    // En producción, enviarías una notificación push con una acción especial
  }

  Future<void> _sendReminder(String userId) async {
    // Lógica para enviar mensaje de recordatorio
    debugPrint('Enviando recordatorio para usuario: $userId');
    // En producción, usarías Firebase Cloud Messaging
  }
}
