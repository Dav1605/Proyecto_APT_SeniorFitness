import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:senior_fitness_app/screens/exercises_screen.dart';
import 'package:senior_fitness_app/services/gemini_service.dart';

class ProgressScreen extends StatefulWidget {
  final String userId;
  const ProgressScreen({super.key, required this.userId});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _geminiService = GeminiService();

  String _sofiMessage = "";
  bool _loadingMessage = true;

  @override
  void initState() {
    super.initState();
    _generateSofiMessage();
  }

  Future<void> _generateSofiMessage() async {
    try {
      final snap =
          await _firestore.collection('users').doc(widget.userId).get();

      if (!snap.exists) {
        if (!mounted) return;
        setState(() {
          _sofiMessage = "⚠️ No se encontró información de progreso.";
          _loadingMessage = false;
        });
        return;
      }

      final data = snap.data()!;
      final int xp = (data['xp'] ?? 0) as int;
      final int streak = (data['streak'] ?? 0) as int;
      final int bestStreak = (data['best_streak'] ?? streak) as int;
      final String level = _determineLevel(xp);

      final prompt = """
Eres Sofi 💙, una entrenadora virtual amable y breve.
Tu misión: generar un MENSAJE ULTRA CORTO (máximo 18 PALABRAS, máximo 1 línea).
Debe ser motivador y alegre, con máximo 2 emojis.
❌ NO incluyas explicaciones ni listas.
✅ SOLO saludo + frase corta + progreso.

Ejemplos:
"¡Hola! 🌞 Llevas $streak días seguidos, ¡qué constancia! 💪"
"¡Excelente! Ya alcanzaste $xp XP, sigue así 💙"
"¡Súper! $bestStreak días de esfuerzo, ¡orgullosa de ti! ✨"

Usuario: $xp XP, nivel $level, mejor racha $bestStreak días.
Responde ÚNICAMENTE con el mensaje final.
""";

      final message = await _geminiService.generateDynamicResponse(prompt,
          userId: widget.userId);

      if (!mounted) return;

      String clean = message
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('\n', ' ')
          .replaceAll('*', '');

      if (clean.split(' ').length > 18) {
        clean = clean.split(' ').take(18).join(' ') + '…';
      }

      if (clean.contains('.')) {
        clean = clean.split('.').first.trim() + ' ✨';
      }

      setState(() {
        _sofiMessage = clean;
        _loadingMessage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sofiMessage =
            "💬 Sofi no logró cargar tu progreso. Intenta más tarde 💙";
        _loadingMessage = false;
      });
    }
  }

  String _determineLevel(int xp) {
    if (xp < 200) return 'Principiante';
    if (xp < 500) return 'Intermedio';
    return 'Avanzado';
  }

  double _calculateProgress(int xp) {
    if (xp < 200) return xp / 200;
    if (xp < 500) return (xp - 200) / 300;
    return 1.0;
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        title: const Text('Mi Progreso'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final int xp = (data['xp'] ?? 0) as int;
          final int streak = (data['streak'] ?? 0) as int;
          final int bestStreak = (data['best_streak'] ?? streak) as int;
          final String level = _determineLevel(xp);
          final double progressToNextLevel = _calculateProgress(xp);

          return RefreshIndicator(
            onRefresh: _generateSofiMessage,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  child: _loadingMessage
                      ? _buildThinkingCard()
                      : _buildSofiMessageCard(),
                ),
                const SizedBox(height: 20),
                _buildProgressCard(
                  title: '🔥 Tu Racha',
                  child: Column(
                    children: [
                      Text(
                        '$streak Días Seguidos',
                        style: const TextStyle(
                          color: Color(0xFFFFA726),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Racha más larga: $bestStreak días',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildProgressCard(
                  title: '🎖 Nivel Actual: $level',
                  child: Column(
                    children: [
                      Text(
                        '$xp XP',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progressToNextLevel,
                        color: const Color(0xFFFFA726),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        level == 'Avanzado'
                            ? '🌟 Nivel máximo alcanzado'
                            : 'Progreso hacia el siguiente nivel',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildProgressCard(
                  title: '🏅 Tus Logros',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBadge('Constancia', Icons.star, Colors.orange),
                      _buildBadge('Racha Fuerte', Icons.local_fire_department,
                          Colors.redAccent),
                      _buildBadge('Disciplina', Icons.spa, Colors.green),
                      _buildBadge('Leyenda', Icons.emoji_events, Colors.purple),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.fitness_center, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExercisesScreen(userId: widget.userId),
                        ),
                      );
                    },
                    label: const Text(
                      'Registrar Actividad de Hoy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThinkingCard() {
    return Container(
      key: const ValueKey('thinking'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Lottie.asset('assets/animations/sofi_thinking.json',
              width: 80, height: 80),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sofi está revisando tu progreso 💭...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSofiMessageCard() {
    const String extraMessage =
        "💙 Sofi te anima hoy: ¡vamos por otro gran día!";

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 30, end: 0),
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset),
          child: AnimatedOpacity(
            opacity: _loadingMessage ? 0 : 1,
            duration: const Duration(milliseconds: 700),
            child: Container(
              key: const ValueKey('message'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Lottie.asset(
                    'assets/animations/sofi_waving.json',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sofiMessage,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 1200),
                          child: const Text(
                            extraMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
