import 'package:flutter/material.dart';

/// Widget de insignia/medalla con animación y gradiente Sofi.
/// Compatible con temas claros y oscuros.
/// Usado en StreakScreen, ProfileScreen y futuras vistas de logros.
class BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEarned;
  final double elevation;
  final double iconSize;

  const BadgeChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF3B82F6),
    this.isEarned = true,
    this.elevation = 4,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        gradient: isEarned
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEarned ? null : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEarned ? color.withValues(alpha: 0.4) : Colors.grey[300]!,
          width: 1.4,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: elevation,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: isEarned ? 1.1 : 0.9,
            child: Icon(
              icon,
              color: isEarned ? color : Colors.grey,
              size: iconSize,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isEarned ? color : Colors.grey[600],
            ),
          ),
          if (isEarned)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            ),
        ],
      ),
    );
  }
}
