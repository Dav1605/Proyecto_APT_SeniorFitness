import 'package:flutter/material.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'package:lottie/lottie.dart';

/// 🌟 Barra de experiencia animada con efecto "+XP"
class XpProgress extends StatefulWidget {
  final int currentXp;
  final int xpToNextLevel;

  const XpProgress({
    super.key,
    required this.currentXp,
    required this.xpToNextLevel,
  });

  @override
  State<XpProgress> createState() => _XpProgressState();
}

class _XpProgressState extends State<XpProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _oldProgress = 0;
  bool _showXpGain = false;
  int _xpDifference = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _updateProgress();
  }

  @override
  void didUpdateWidget(covariant XpProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentXp != oldWidget.currentXp) {
      _xpDifference = widget.currentXp - oldWidget.currentXp;
      _showXpGain = _xpDifference > 0;
      _updateProgress();
      _controller.forward(from: 0);
      if (_showXpGain) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _showXpGain = false);
          }
        });
      }
    }
  }

  void _updateProgress() {
    final newProgress =
        (widget.currentXp / widget.xpToNextLevel).clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(
      begin: _oldProgress,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _oldProgress = newProgress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progreso de experiencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppPalette.primary,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppPalette.primary),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.currentXp} XP'),
                  Text('${widget.xpToNextLevel} XP para subir'),
                ],
              ),
            ],
          ),
        ),

        // ✨ Animación flotante "+XP"
        if (_showXpGain)
          Positioned(
            top: -10,
            right: 40,
            child: AnimatedOpacity(
              opacity: _showXpGain ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 0, end: -50),
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: _xpDifference >= 10
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+$_xpDifference XP',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/xp_star.json',
                            width: 40,
                            height: 40,
                            repeat: false,
                          ),
                        ],
                      )
                    : Text(
                        '+$_xpDifference XP',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
