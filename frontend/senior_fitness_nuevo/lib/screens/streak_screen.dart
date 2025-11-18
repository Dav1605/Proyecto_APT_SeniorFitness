import 'package:flutter/material.dart';
import 'package:senior_fitness_app/services/gemini_service.dart';
import 'package:senior_fitness_app/services/auth_service.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'package:senior_fitness_app/ui/widgets/sofi_header.dart';

class StreakScreen extends StatefulWidget {
  final String userId;
  final String token;

  const StreakScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final GeminiService _geminiService = GeminiService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  String _motivationalMessage = "💭 Sofi está preparando tu mensaje...";

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    try {
      // 1️⃣ Obtener datos de racha desde Firestore
      final streakData = await _authService.getCurrentStreak(widget.userId);
      final current = streakData['current_streak'] ?? 0;
      final longest = streakData['longest_streak'] ?? 0;

      // 2️⃣ Generar mensaje breve y motivacional
      final prompt = """
Eres Sofi, una entrenadora virtual motivadora para adultos mayores.
Genera un mensaje CORTO (máx. 3 frases) para un usuario que lleva $current días de racha 
y cuya racha más larga es de $longest días.
Debe sonar cálido, positivo y alentador (sin repetir muchas frases). 
Incluye 1 o 2 emojis naturales. 
Ejemplo: "¡Increíble trabajo! 🔥 Cada día constante fortalece tu cuerpo y tu ánimo. ¡Sigue así!"
""";

      final message = await _geminiService.generateDynamicResponse(
        prompt,
        userId: widget.userId,
      );

      setState(() {
        _currentStreak = current;
        _longestStreak = longest;
        _motivationalMessage = message.trim();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _motivationalMessage =
            "🔥 Sofi dice: ¡cada día cuenta, incluso si hoy vuelves a empezar! 💪";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              const SofiHeader(
                title: 'Tu racha diaria 🔥',
                subtitle: 'Sofi te acompaña en tu constancia 💙',
                asset: 'assets/images/sofi_exercise.png',
              ),
              const SizedBox(height: 20),

              // 💬 Mensaje IA motivacional
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/sofi_thinking.png',
                        height: 55,
                        width: 55,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _motivationalMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppPalette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🔥 Panel de racha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Progreso actual',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStreakStat(
                              'Racha actual',
                              _currentStreak.toString(),
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                            _buildStreakStat(
                              'Racha más larga',
                              _longestStreak.toString(),
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔁 Botón de recarga
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadStreakData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar mensaje'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
