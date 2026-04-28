import 'dart:math' as math;

import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/components/hp_bar_component.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerBallComponent extends PositionComponent {
  final String playerId;
  final HpBarComponent hpBar = HpBarComponent();

  Vector2 targetPosition;
  double ballRadius;
  double hp;
  double maxHp;
  Color ballColor;
  bool alive;
  bool isMine;
  int unspentUpgrades;
  String characterType;
  double _lastHp;
  double _hitFlash = 0;
  double _pulse = 0;
  double _facingAngle;
  double _motionEnergy = 0;
  bool _showLabel = false;

  PlayerBallComponent({
    required this.playerId,
    required Vector2 initialPosition,
    required this.ballRadius,
    required PlayerSnapshot snapshot,
    required this.isMine,
  })  : targetPosition = initialPosition.clone(),
        hp = snapshot.hp,
        maxHp = snapshot.maxHp,
        ballColor = snapshot.flutterColor,
        alive = snapshot.alive,
        unspentUpgrades = snapshot.unspentUpgrades,
        characterType = snapshot.characterType,
        _lastHp = snapshot.hp,
        _facingAngle = _directionFromVelocity(snapshot),
        super(
          position: initialPosition,
          size: Vector2.all(ballRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await add(hpBar);
    _layoutHpBar();
    hpBar.updateValues(
      hp: hp,
      maxHp: maxHp,
      alive: alive,
      visibleBar: false,
    );
  }

  void applySnapshot({
    required PlayerSnapshot snapshot,
    required Vector2 screenPosition,
    required double screenRadius,
    required bool isMine,
  }) {
    targetPosition = screenPosition;
    ballRadius = screenRadius;
    size = Vector2.all(ballRadius * 2);
    this.isMine = isMine;
    ballColor = snapshot.flutterColor;
    alive = snapshot.alive;
    maxHp = snapshot.maxHp;
    unspentUpgrades = snapshot.unspentUpgrades;
    characterType = snapshot.characterType;
    final velocityLength =
        math.sqrt(snapshot.vx * snapshot.vx + snapshot.vy * snapshot.vy);
    if (velocityLength > 0.04) {
      _facingAngle = math.atan2(snapshot.vy, snapshot.vx);
    }
    _motionEnergy = (velocityLength * snapshot.speed).clamp(0.0, 1.8);
    _showLabel = isMine || unspentUpgrades > 0;

    if (snapshot.hp < _lastHp) {
      _hitFlash = 1;
    }
    hp = snapshot.hp;
    _lastHp = snapshot.hp;

    _layoutHpBar();
    hpBar.updateValues(
      hp: hp,
      maxHp: maxHp,
      alive: alive,
      visibleBar: isMine || unspentUpgrades > 0 || hp / maxHp < 0.55,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    position += (targetPosition - position) * 0.25;
    _hitFlash = (_hitFlash - dt * 5.2).clamp(0, 1).toDouble();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final hpRatio = maxHp <= 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    final baseColor = _resolveBodyColor(hpRatio);
    final pendingPulse = 1 + math.sin(_pulse * 6) * 0.08;
    final stretch = 1 + _motionEnergy * 0.08;
    final squash = 1 - _motionEnergy * 0.04;

    if (isMine && alive) {
      canvas.drawCircle(
        center,
        ballRadius + 8 * pendingPulse,
        Paint()..color = AutoBattlePalette.strongAccent.withValues(alpha: 0.16),
      );
    }

    if (unspentUpgrades > 0 && alive) {
      canvas.drawCircle(
        center,
        ballRadius + 11 * pendingPulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.55),
      );
    }

    if (_hitFlash > 0) {
      canvas.drawCircle(
        center,
        ballRadius + 10 * _hitFlash,
        Paint()..color = Colors.white.withValues(alpha: 0.50 * _hitFlash),
      );
      canvas.drawCircle(
        center,
        ballRadius + 18 * (1 - _hitFlash),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFB7185).withValues(alpha: 0.38 * _hitFlash),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_facingAngle);
    canvas.scale(stretch, squash);

    canvas.drawCircle(
      Offset(0, ballRadius * 0.22),
      ballRadius * 1.02,
      Paint()..color = const Color(0xFF9DB5D3).withValues(alpha: 0.22),
    );
    canvas.drawCircle(Offset.zero, ballRadius, Paint()..color = baseColor);
    canvas.drawCircle(
      Offset.zero,
      ballRadius * 0.82,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Colors.white.withValues(alpha: alive ? 0.30 : 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: ballRadius),
        ),
    );
    canvas.drawCircle(
      Offset(-ballRadius * 0.28, -ballRadius * 0.30),
      ballRadius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: alive ? 0.20 : 0.08),
    );

    canvas.drawCircle(
      Offset.zero,
      ballRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMine ? 3 : 1.8
        ..color = isMine
            ? Colors.white.withValues(alpha: 0.96)
            : const Color(0xFF6C85A3).withValues(alpha: 0.45),
    );
    canvas.restore();

    _renderEquipment(canvas, center);
    if (_showLabel) {
      _renderLabel(canvas);
    }
    super.render(canvas);
  }

  Color _resolveBodyColor(double hpRatio) {
    if (!alive) {
      return const Color(0xFF6B7280).withValues(alpha: 0.55);
    }
    if (hpRatio <= 0.3) {
      return Color.lerp(ballColor, const Color(0xFFEF4444), 0.70)!;
    }
    if (hpRatio <= 0.6) {
      return Color.lerp(ballColor, const Color(0xFFF97316), 0.55)!;
    }
    return ballColor;
  }

  void _renderLabel(Canvas canvas) {
    final pendingLabel = unspentUpgrades > 0 ? ' +$unspentUpgrades' : '';
    final label = '${_characterLabel(characterType)}$pendingLabel';
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AutoBattlePalette.primaryText,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.x - painter.width) / 2,
      size.y + 7,
    );

    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx - 5,
        offset.dy - 2,
        painter.width + 10,
        painter.height + 4,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      background,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AutoBattlePalette.cardBorder,
    );
    painter.paint(canvas, offset);
  }

  String _characterLabel(String type) {
    switch (type) {
      case 'poison':
        return 'POI';
      case 'gunner':
        return 'GUN';
      case 'blade':
        return 'BLD';
      case 'miner':
        return 'MIN';
      default:
        return type.toUpperCase();
    }
  }

  void _layoutHpBar() {
    hpBar
      ..size = Vector2(ballRadius * 2.4, 6)
      ..position = Vector2(size.x / 2, -10);
  }

  static double _directionFromVelocity(PlayerSnapshot snapshot) {
    final velocityLength =
        math.sqrt(snapshot.vx * snapshot.vx + snapshot.vy * snapshot.vy);
    if (velocityLength <= 0.04) return 0;
    return math.atan2(snapshot.vy, snapshot.vx);
  }

  void _renderEquipment(Canvas canvas, Offset center) {
    if (!alive) return;

    final scale = (ballRadius / 18).clamp(0.72, 1.35).toDouble();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_facingAngle);

    final handOffset = Offset(ballRadius * 0.76, ballRadius * 0.20);
    canvas.drawCircle(
      handOffset,
      4.1 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
    canvas.drawCircle(
      handOffset,
      4.1 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale
        ..color = AutoBattlePalette.secondaryText.withValues(alpha: 0.34),
    );

    switch (characterType) {
      case 'poison':
        _renderPoisonVial(canvas, scale);
        break;
      case 'gunner':
        _renderGun(canvas, scale);
        break;
      case 'blade':
        _renderBlade(canvas, scale);
        break;
      case 'miner':
        _renderHeldMine(canvas, scale);
        break;
      default:
        break;
    }

    canvas.restore();
  }

  void _renderGun(Canvas canvas, double scale) {
    final outline = Paint()
      ..color = AutoBattlePalette.secondaryText.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final body = Paint()..color = const Color(0xFFE5E7EB);
    final dark = Paint()..color = const Color(0xFF475569);
    final accent = Paint()..color = const Color(0xFF38BDF8);

    final barrel = RRect.fromRectAndRadius(
      Rect.fromLTWH(ballRadius * 0.78, -5.5 * scale, 24 * scale, 8.5 * scale),
      Radius.circular(2.8 * scale),
    );
    canvas.drawRRect(barrel, outline);
    canvas.drawRRect(barrel, body);

    final chamber = RRect.fromRectAndRadius(
      Rect.fromLTWH(ballRadius * 0.66, -8.2 * scale, 15 * scale, 13 * scale),
      Radius.circular(3.2 * scale),
    );
    canvas.drawRRect(chamber, outline);
    canvas.drawRRect(chamber, dark);

    final gripPath = Path()
      ..moveTo(ballRadius * 0.75, 2 * scale)
      ..lineTo(ballRadius * 0.88, 2 * scale)
      ..lineTo(ballRadius * 0.82, 20 * scale)
      ..lineTo(ballRadius * 0.68, 19 * scale)
      ..close();
    canvas.drawPath(gripPath, outline);
    canvas.drawPath(gripPath, dark);

    canvas.drawCircle(
      Offset(ballRadius * 1.98, -1.1 * scale),
      2.8 * scale,
      accent,
    );
  }

  void _renderBlade(Canvas canvas, double scale) {
    final outline = Paint()
      ..color = AutoBattlePalette.secondaryText.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.1 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final bladePaint = Paint()..color = const Color(0xFFF8FAFC);
    final edgePaint = Paint()
      ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.85);
    final hiltPaint = Paint()..color = const Color(0xFFF59E0B);
    final handlePaint = Paint()..color = const Color(0xFF7C2D12);

    final bladePath = Path()
      ..moveTo(ballRadius * 0.83, -4.5 * scale)
      ..lineTo(ballRadius * 2.1, -2.2 * scale)
      ..lineTo(ballRadius * 2.28, 0)
      ..lineTo(ballRadius * 2.1, 2.2 * scale)
      ..lineTo(ballRadius * 0.83, 4.5 * scale)
      ..close();
    canvas.drawPath(bladePath, outline);
    canvas.drawPath(bladePath, bladePaint);

    final edgePath = Path()
      ..moveTo(ballRadius * 1.05, -1.4 * scale)
      ..lineTo(ballRadius * 2.02, -0.5 * scale)
      ..lineTo(ballRadius * 1.05, 1.4 * scale);
    canvas.drawPath(edgePath, edgePaint);

    canvas.drawLine(
      Offset(ballRadius * 0.74, -9 * scale),
      Offset(ballRadius * 0.74, 9 * scale),
      Paint()
        ..color = hiltPaint.color
        ..strokeWidth = 5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(ballRadius * 0.56, 0),
      Offset(ballRadius * 0.82, 0),
      Paint()
        ..color = handlePaint.color
        ..strokeWidth = 7 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _renderPoisonVial(Canvas canvas, double scale) {
    final outline = Paint()
      ..color = AutoBattlePalette.secondaryText.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final glass = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.94);
    final liquid = Paint()..color = const Color(0xFF22C55E);
    final cap = Paint()..color = const Color(0xFF475569);

    canvas.save();
    canvas.translate(ballRadius * 1.08, -2 * scale);
    canvas.rotate(-0.28);

    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(-7 * scale, -10 * scale, 18 * scale, 26 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(bottle, outline);
    canvas.drawRRect(bottle, glass);

    final liquidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5 * scale, 1 * scale, 14 * scale, 12 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(liquidRect, liquid);

    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(-2 * scale, -17 * scale, 8 * scale, 8 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(neck, outline);
    canvas.drawRRect(neck, cap);

    canvas.drawCircle(Offset(1 * scale, -1 * scale), 2 * scale,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(7 * scale, -20 * scale), 2.3 * scale, liquid);
    canvas.drawCircle(Offset(13 * scale, -26 * scale), 1.7 * scale, liquid);
    canvas.restore();
  }

  void _renderHeldMine(Canvas canvas, double scale) {
    final outline = Paint()
      ..color = AutoBattlePalette.secondaryText.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    final shell = Paint()..color = const Color(0xFF1F2937);
    final light = Paint()..color = const Color(0xFFFFD43B);

    final mineCenter = Offset(ballRadius * 1.23, -1 * scale);
    for (var i = 0; i < 8; i += 1) {
      final angle = i * math.pi / 4;
      final start =
          mineCenter + Offset(math.cos(angle), math.sin(angle)) * 8 * scale;
      final end =
          mineCenter + Offset(math.cos(angle), math.sin(angle)) * 13 * scale;
      canvas.drawLine(start, end, outline);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF64748B)
          ..strokeWidth = 2.4 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(mineCenter, 11 * scale, outline);
    canvas.drawCircle(mineCenter, 11 * scale, shell);
    canvas.drawCircle(mineCenter, 4.2 * scale, light);
    canvas.drawCircle(
      mineCenter,
      11 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }
}
