import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:senior_fitness_app/models/exercise_model.dart';
import 'package:senior_fitness_app/services/exercise_service.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';

class ExercisesScreen extends StatefulWidget {
  final String userId;
  const ExercisesScreen({super.key, required this.userId});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _exercises = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final result =
          await _exerciseService.recommendedForUser(userId: widget.userId);

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() {
          _error = true;
          _loading = false;
        });
      } else {
        setState(() {
          _exercises = result;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error cargando ejercicios: $e");
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Color _getCardColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'media':
        return Colors.orange.shade100;
      case 'alta':
      case 'difícil':
        return Colors.red.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getButtonColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'media':
        return Colors.orange;
      case 'alta':
      case 'difícil':
        return Colors.red;
      default:
        return Colors.blueAccent;
    }
  }

  int _getXpGain(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'media':
        return 20;
      case 'alta':
      case 'difícil':
        return 30;
      default:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppPalette.primary,
        title: const Text('Mis Ejercicios'),
        foregroundColor: Colors.white,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _loading
            ? _buildLoading()
            : _error
                ? _buildError()
                : _exercises.isEmpty
                    ? _buildEmptyState()
                    : _buildExerciseList(),
      ),
    );
  }

  /// 💭 Sofi pensando
  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/sofi_thinking.json', height: 180),
          const SizedBox(height: 12),
          const Text(
            "💭 Sofi está pensando en nuevos ejercicios para ti...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildRequestButton(),
        ],
      ),
    );
  }

  /// 😔 Error al generar ejercicios
  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/sofi_sad.json', height: 140),
          const SizedBox(height: 16),
          const Text(
            '😔 Sofi no pudo generar los ejercicios ahora.\nIntenta nuevamente.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildRequestButton(),
        ],
      ),
    );
  }

  /// 📭 Sin ejercicios disponibles
  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/sofi_waving.json', height: 150),
          const SizedBox(height: 16),
          const Text(
            '¡Has completado todos tus ejercicios por hoy! 🧘‍♀️',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          _buildRequestButton(),
        ],
      ),
    );
  }

  /// 🟠 Botón para pedir nuevos ejercicios
  Widget _buildRequestButton() {
    return ElevatedButton.icon(
      onPressed: _loadExercises,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.fitness_center_rounded),
      label: const Text(
        '💪 Pídele a Sofi más ejercicios',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 🏋️‍♀️ Lista con tarjetas coloreadas + botón completar
  Widget _buildExerciseList() {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        final color = _getCardColor(exercise.difficultyLevel);
        final buttonColor = _getButtonColor(exercise.difficultyLevel);
        final xpGain = _getXpGain(exercise.difficultyLevel);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "⏱ ${exercise.durationMinutes} min | Nivel: ${exercise.difficultyLevel}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _exerciseService.completeExercise(
                            widget.userId, exercise);

                        if (!mounted) return;

                        setState(() {
                          _exercises.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '🎉 ¡Ejercicio "${exercise.title}" completado! +$xpGain XP 🌟'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'COMPLETAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
