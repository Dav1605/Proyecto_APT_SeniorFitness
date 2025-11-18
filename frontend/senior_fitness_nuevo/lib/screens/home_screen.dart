import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'package:senior_fitness_app/ui/widgets/xp_progress.dart';
import 'package:senior_fitness_app/screens/exercises_screen.dart';
import 'package:senior_fitness_app/screens/progress_screen.dart';
import 'package:senior_fitness_app/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  String _determineLevel(int xp) {
    if (xp < 200) return 'Principiante';
    if (xp < 500) return 'Intermedio';
    return 'Avanzado';
  }

  int _xpToNextLevel(int xp) {
    if (xp < 200) return 200;
    if (xp < 500) return 500;
    return 1000;
  }

  @override
  Widget build(BuildContext context) {
    final userStream =
        FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        title: const Text('Senior Fitness'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final int currentXp = (userData['xp'] ?? 0).toInt();
          final String userName = userData['name'] ?? 'Usuario';
          final String level = _determineLevel(currentXp);
          final int xpToNextLevel = _xpToNextLevel(currentXp);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💙 Header Sofi
                Container(
                  decoration: BoxDecoration(
                    color: AppPalette.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Lottie.asset(
                        'assets/animations/sofi_waving.json',
                        height: 80,
                        width: 80,
                        repeat: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¡Hola, $userName! 👋\nSoy Sofi 💙 tu entrenadora virtual.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🌟 Barra XP dinámica
                XpProgress(
                  currentXp: currentXp,
                  xpToNextLevel: xpToNextLevel,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Nivel actual: $level ⭐',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ⚙️ Menú principal
                _menuButton(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Mis Ejercicios',
                  color: Colors.blueAccent,
                  screen: ExercisesScreen(userId: userId),
                ),
                _menuButton(
                  context,
                  icon: Icons.local_fire_department,
                  title: 'Mi Progreso',
                  color: Colors.orange,
                  screen: ProgressScreen(userId: userId),
                ),
                _menuButton(
                  context,
                  icon: Icons.person,
                  title: 'Mi Perfil',
                  color: Colors.green,
                  screen: ProfileScreen(userId: userId),
                ),
                const SizedBox(height: 30),

                // 💬 Consejo de Sofi
                _buildAdviceCard(context, userName),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Consejo motivacional de Sofi
  Widget _buildAdviceCard(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Lottie.asset('assets/animations/sofi_waving.json', height: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🌞 ¡Hola, $userName! Hoy es un gran día para moverse un poquito y sonreír 💙',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Sofi está feliz de verte motivado! 💪'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🧭 Botón reutilizable
  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}
