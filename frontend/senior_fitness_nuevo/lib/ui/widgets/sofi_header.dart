import 'package:flutter/material.dart';

class SofiHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String asset;
  final Widget? trailing; // ✅ opcional (para XP o medalla)

  const SofiHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.asset,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, size.height * 0.06, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen o animación de Sofi
          Hero(
            tag: 'sofi-avatar',
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Texto principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Ícono o XP (opcional)
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
