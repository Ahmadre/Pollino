import 'package:flutter/material.dart';

class PollinoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const PollinoLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoIcon(),
          const SizedBox(width: 8),
          Text(
            'Pollino',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      );
    }
    return _buildLogoIcon();
  }

  Widget _buildLogoIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0175C2), Color(0xFF0056A3)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bar 1 - Tallest
            Container(
              width: size * 0.12,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
            // Bar 2 - Medium
            Container(
              width: size * 0.12,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
            // Bar 3 - Shorter
            Container(
              width: size * 0.12,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
            // Bar 4 - Shortest
            Container(
              width: size * 0.12,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
