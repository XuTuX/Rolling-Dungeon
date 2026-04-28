import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HpBarComponent extends PositionComponent {
  double hpRatio = 1;
  bool alive = true;
  bool visibleBar = true;

  HpBarComponent()
      : super(
          size: Vector2(48, 6),
          anchor: Anchor.center,
        );

  void updateValues({
    required double hp,
    required double maxHp,
    required bool alive,
    required bool visibleBar,
  }) {
    final ratio = maxHp <= 0 ? 0 : hp / maxHp;
    hpRatio = ratio.clamp(0, 1).toDouble();
    this.alive = alive;
    this.visibleBar = visibleBar;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!visibleBar) return;

    final background = RRect.fromRectAndRadius(
      Offset.zero & Size(size.x, size.y),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      background,
      Paint()..color = const Color(0xFFE4ECF8),
    );

    final foregroundWidth = size.x * hpRatio;
    if (foregroundWidth <= 0) return;

    final color = !alive
        ? const Color(0xFF9CA3AF)
        : hpRatio > 0.6
            ? const Color(0xFF22C55E)
            : hpRatio > 0.3
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Offset(-1, -1) & Size(foregroundWidth + 2, size.y + 2),
        const Radius.circular(4),
      ),
      Paint()..color = color.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size(foregroundWidth, size.y),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }
}
