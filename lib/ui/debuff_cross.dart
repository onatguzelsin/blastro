import 'package:flutter/material.dart';

/// Dims its child and strikes it with a bold red cross (a debuffed joker).
class DebuffCross extends StatelessWidget {
  const DebuffCross({super.key, required this.child, required this.active});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const ColoredBox(color: Color(0x99000000)),
        ),
        const IgnorePointer(child: CustomPaint(painter: _CrossPainter())),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF1744)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(size.shortestSide * 0.18);
    canvas.drawLine(r.topLeft, r.bottomRight, paint);
    canvas.drawLine(r.topRight, r.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => false;
}
