import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class DamagePopupComponent extends TextComponent {
  final double amount;
  final bool isPlayer;
  final double initialX;
  final double initialY;

  double _timer = 0;
  static const double duration = 0.8;
  Color get _baseColor =>
      isPlayer ? const Color(0xFFFF5252) : const Color(0xFFFFD54F);

  DamagePopupComponent({
    required this.amount,
    required this.isPlayer,
    required this.initialX,
    required this.initialY,
  }) : super(
          text: amount.toInt().toString(),
          position: Vector2(initialX, initialY),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    textRenderer = TextPaint(
      style: TextStyle(
        fontSize: isPlayer ? 18 : 22,
        fontWeight: FontWeight.bold,
        color: _baseColor,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
        fontFamily: 'Outfit', // Or any bold font available
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Float upwards and fade out
    position.y -= dt * 40;

    // Slight side drift
    position.x += math.sin(_timer * 10) * dt * 10;

    final progress = _timer / duration;
    textRenderer = TextPaint(
      style: TextStyle(
        fontSize: isPlayer ? 18 : 22,
        fontWeight: FontWeight.bold,
        color: _baseColor.withValues(alpha: (1.0 - progress).clamp(0, 1)),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: (1.0 - progress).clamp(0, 1)),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
        fontFamily: 'Outfit',
      ),
    );

    if (_timer >= duration) {
      removeFromParent();
    }
  }
}
