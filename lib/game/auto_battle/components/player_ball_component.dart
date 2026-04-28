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
  int _lastAttackAt = 0;
  double _thrust = 0;
  double _targetAngle = 0;

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
        _targetAngle = snapshot.targetAngle,
        _lastAttackAt = snapshot.lastAttackAt,
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
    
    // Smoothly update facing angle towards targetAngle
    _targetAngle = snapshot.targetAngle;
    
    _motionEnergy = (velocityLength * snapshot.speed).clamp(0.0, 1.8);
    _showLabel = isMine || unspentUpgrades > 0;

    if (snapshot.hp < _lastHp) {
      _hitFlash = 1;
    }
    hp = snapshot.hp;
    _lastHp = snapshot.hp;

    if (snapshot.lastAttackAt > _lastAttackAt) {
      _thrust = 1.0;
    }
    _lastAttackAt = snapshot.lastAttackAt;

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
    
    // Decay animations
    _hitFlash = (_hitFlash - dt * 5).clamp(0, 1).toDouble();
    _thrust = (_thrust - dt * 6.5).clamp(0, 1).toDouble();
    _pulse = (_pulse + dt) % (math.pi * 2);

    // Smoothly lerp facing angle to target angle
    _facingAngle = _lerpAngle(_facingAngle, _targetAngle, 0.25);

    // Smooth position interpolation
    position.lerp(targetPosition, 0.22);
  }

  double _lerpAngle(double start, double end, double t) {
    double diff = (end - start) % (math.pi * 2);
    if (diff > math.pi) diff -= math.pi * 2;
    if (diff < -math.pi) diff += math.pi * 2;
    return start + diff * t;
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
      case 'laser':
        return 'LAS';
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
    
    // Apply thrust: lunge forward along the facing angle
    // Increase distance to 14.0 for better visibility
    final thrustOffset = 14.0 * _thrust * scale;
    canvas.translate(
      center.dx + math.cos(_facingAngle) * thrustOffset,
      center.dy + math.sin(_facingAngle) * thrustOffset,
    );
    canvas.rotate(_facingAngle);

    final handOffset = Offset(ballRadius * 0.76, ballRadius * 0.20);
    canvas.drawCircle(
      handOffset,
      4.1 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      handOffset,
      4.1 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.5),
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
      case 'laser':
        _renderLaserCannon(canvas, scale);
        break;
      default:
        break;
    }

    canvas.restore();
  }

  void _renderGun(Canvas canvas, double scale) {
    // ── Chunky Cartoon Revolver ──
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Barrel – thick rounded rectangle
    // Stretch barrel forward based on thrust
    final barrelExtension = 6.0 * _thrust * scale;
    final barrelPath = Path()
      ..moveTo(ballRadius * 0.72, -3.5 * scale)
      ..lineTo(ballRadius * 2.2 + barrelExtension, -3 * scale)
      ..lineTo(ballRadius * 2.3 + barrelExtension, 0)
      ..lineTo(ballRadius * 2.2 + barrelExtension, 3 * scale)
      ..lineTo(ballRadius * 0.72, 3.5 * scale)
      ..close();
    canvas.drawPath(barrelPath, Paint()..color = const Color(0xFF374151));
    canvas.drawPath(barrelPath, inkPaint);

    // Barrel Highlight
    canvas.drawLine(
      Offset(ballRadius * 0.85, -1 * scale),
      Offset(ballRadius * 2.0, -0.5 * scale),
      Paint()
        ..color = const Color(0xFF9CA3AF)
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Chamber/Cylinder – bold circle
    canvas.drawCircle(
      Offset(ballRadius * 0.78, 0),
      8.5 * scale,
      Paint()..color = const Color(0xFF1F2937),
    );
    canvas.drawCircle(
      Offset(ballRadius * 0.78, 0),
      8.5 * scale,
      inkPaint,
    );
    // Cylinder detail dots
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 - math.pi / 2;
      canvas.drawCircle(
        Offset(ballRadius * 0.78 + math.cos(a) * 5 * scale,
            math.sin(a) * 5 * scale),
        1.5 * scale,
        Paint()..color = const Color(0xFF6B7280),
      );
    }

    // Grip – bold trapezoid
    final gripPath = Path()
      ..moveTo(ballRadius * 0.68, 5 * scale)
      ..lineTo(ballRadius * 0.88, 5 * scale)
      ..lineTo(ballRadius * 0.82, 22 * scale)
      ..lineTo(ballRadius * 0.62, 21 * scale)
      ..close();
    canvas.drawPath(gripPath, Paint()..color = const Color(0xFF92400E));
    canvas.drawPath(gripPath, inkPaint);

    // Muzzle Flash – bright yellow star
    final muzzle = Offset(ballRadius * 2.35 + barrelExtension, 0);
    canvas.drawCircle(muzzle, 5.5 * scale,
        Paint()..color = const Color(0xFFFFD43B).withValues(alpha: 0.7));
    canvas.drawCircle(muzzle, 3 * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Flash lines
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(
        muzzle + Offset(math.cos(a) * 4 * scale, math.sin(a) * 4 * scale),
        muzzle + Offset(math.cos(a) * 9 * scale, math.sin(a) * 9 * scale),
        Paint()
          ..color = const Color(0xFFFFD43B)
          ..strokeWidth = 1.8 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderBlade(Canvas canvas, double scale) {
    // ── Bold Cartoon Katana ──
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Blade body – long sharp triangle
    // Stretch blade forward based on thrust
    final bladeStretch = 10.0 * _thrust * scale;
    final bladePath = Path()
      ..moveTo(ballRadius * 0.82, -5.5 * scale)
      ..lineTo(ballRadius * 2.6 + bladeStretch, -1 * scale)
      ..lineTo(ballRadius * 2.7 + bladeStretch, 0.5 * scale)
      ..lineTo(ballRadius * 2.5 + bladeStretch, 1.5 * scale)
      ..lineTo(ballRadius * 0.82, 5.5 * scale)
      ..close();
    canvas.drawPath(bladePath, Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawPath(bladePath, inkPaint);

    // Blade edge glow – bright green slash line
    final edgePath = Path()
      ..moveTo(ballRadius * 0.95, -3 * scale)
      ..lineTo(ballRadius * 2.45, -0.3 * scale)
      ..lineTo(ballRadius * 2.55, 0.5 * scale);
    canvas.drawPath(
      edgePath,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Blade inner shine
    canvas.drawLine(
      Offset(ballRadius * 1.2, -1.5 * scale),
      Offset(ballRadius * 2.1, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Guard / Tsuba – bold perpendicular bar
    final tsubaRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(ballRadius * 0.78, 0),
          width: 4 * scale,
          height: 22 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(tsubaRect, Paint()..color = const Color(0xFFEAB308));
    canvas.drawRRect(tsubaRect, inkPaint);

    // Handle – wrapped grip
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          ballRadius * 0.48, -3.5 * scale, ballRadius * 0.28, 7 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(handleRect, Paint()..color = const Color(0xFF7C2D12));
    canvas.drawRRect(handleRect, inkPaint);

    // Handle wrap lines
    for (var i = 0; i < 3; i++) {
      final y = -2 * scale + i * 2 * scale;
      canvas.drawLine(
        Offset(ballRadius * 0.50, y),
        Offset(ballRadius * 0.74, y),
        Paint()
          ..color = const Color(0xFFD97706)
          ..strokeWidth = 1.2 * scale,
      );
    }
  }

  void _renderPoisonVial(Canvas canvas, double scale) {
    // ── Cartoon Bubble Flask ──
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(ballRadius * 1.08, -1 * scale);
    canvas.rotate(-0.22);

    // Flask body – round bottom
    canvas.drawCircle(
        Offset(2 * scale, 6 * scale), 12 * scale, Paint()..color = const Color(0xFFD1FAE5).withValues(alpha: 0.9));
    canvas.drawCircle(
        Offset(2 * scale, 6 * scale), 12 * scale, inkPaint);

    // Liquid fill – green with bubbles
    final liquidPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(2 * scale, 6 * scale), radius: 10 * scale),
        0.3,
        math.pi - 0.6,
      )
      ..close();
    canvas.drawPath(liquidPath, Paint()..color = const Color(0xFF22C55E));

    // Bubbles
    canvas.drawCircle(Offset(-2 * scale, 4 * scale), 2.2 * scale,
        Paint()..color = const Color(0xFF86EFAC));
    canvas.drawCircle(Offset(5 * scale, 2 * scale), 1.6 * scale,
        Paint()..color = const Color(0xFFBBF7D0));
    canvas.drawCircle(Offset(1 * scale, 8 * scale), 1.8 * scale,
        Paint()..color = const Color(0xFF86EFAC));

    // Neck
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-2 * scale, -14 * scale, 8 * scale, 12 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(neckRect, Paint()..color = const Color(0xFFD1FAE5).withValues(alpha: 0.85));
    canvas.drawRRect(neckRect, inkPaint);

    // Cork
    final corkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-3 * scale, -19 * scale, 10 * scale, 6 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(corkRect, Paint()..color = const Color(0xFF92400E));
    canvas.drawRRect(corkRect, inkPaint);

    // Skull icon on flask
    canvas.drawCircle(
      Offset(2 * scale, 4 * scale),
      3 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    // Skull eyes
    canvas.drawCircle(Offset(0.5 * scale, 3 * scale), 0.8 * scale,
        Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(Offset(3.5 * scale, 3 * scale), 0.8 * scale,
        Paint()..color = const Color(0xFF1A1A1A));

    // Drip from cork
    canvas.drawCircle(Offset(6 * scale, -22 * scale), 2.2 * scale,
        Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(Offset(10 * scale, -27 * scale), 1.5 * scale,
        Paint()..color = const Color(0xFF22C55E));

    canvas.restore();
  }

  void _renderHeldMine(Canvas canvas, double scale) {
    // ── TNT Dynamite Bundle ──
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    final center = Offset(ballRadius * 1.25, -1 * scale);

    // Three dynamite sticks (red cylinders)
    for (var i = -1; i <= 1; i++) {
      final stickX = center.dx + i * 5 * scale;
      final stickRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(stickX, center.dy),
            width: 6.5 * scale,
            height: 22 * scale),
        Radius.circular(3 * scale),
      );
      canvas.drawRRect(stickRect, Paint()..color = const Color(0xFFEF4444));
      canvas.drawRRect(stickRect, inkPaint);

      // Label band
      canvas.drawLine(
        Offset(stickX - 2.5 * scale, center.dy + 3 * scale),
        Offset(stickX + 2.5 * scale, center.dy + 3 * scale),
        Paint()
          ..color = const Color(0xFFFFD43B)
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    // Binding rope
    canvas.drawLine(
      Offset(center.dx - 7 * scale, center.dy - 2 * scale),
      Offset(center.dx + 7 * scale, center.dy - 2 * scale),
      Paint()
        ..color = const Color(0xFF92400E)
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(center.dx - 7 * scale, center.dy + 5 * scale),
      Offset(center.dx + 7 * scale, center.dy + 5 * scale),
      Paint()
        ..color = const Color(0xFF92400E)
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Fuse – wavy line going up
    final fusePath = Path()
      ..moveTo(center.dx, center.dy - 12 * scale)
      ..cubicTo(
        center.dx + 5 * scale, center.dy - 18 * scale,
        center.dx - 3 * scale, center.dy - 24 * scale,
        center.dx + 2 * scale, center.dy - 28 * scale,
      );
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Fuse spark – bright orange/yellow glow
    final sparkPos = Offset(center.dx + 2 * scale, center.dy - 28 * scale);
    canvas.drawCircle(sparkPos, 5 * scale,
        Paint()..color = const Color(0xFFFF6B00).withValues(alpha: 0.5));
    canvas.drawCircle(sparkPos, 3 * scale,
        Paint()..color = const Color(0xFFFFD43B).withValues(alpha: 0.8));
    canvas.drawCircle(sparkPos, 1.5 * scale,
        Paint()..color = Colors.white);

    // Spark rays
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + _pulse * 8;
      canvas.drawLine(
        sparkPos + Offset(math.cos(a) * 3 * scale, math.sin(a) * 3 * scale),
        sparkPos + Offset(math.cos(a) * 7 * scale, math.sin(a) * 7 * scale),
        Paint()
          ..color = const Color(0xFFFFD43B)
          ..strokeWidth = 1.2 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderLaserCannon(Canvas canvas, double scale) {
    // ── Sci-fi Sketch Laser Cannon ──
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Cannon body
    // Stretch cannon forward based on thrust
    final cannonStretch = 8.0 * _thrust * scale;
    final cannonPath = Path()
      ..moveTo(ballRadius * 0.72, -8 * scale)
      ..lineTo(ballRadius * 2.4 + cannonStretch, -10 * scale)
      ..lineTo(ballRadius * 2.5 + cannonStretch, 0)
      ..lineTo(ballRadius * 2.4 + cannonStretch, 10 * scale)
      ..lineTo(ballRadius * 0.72, 8 * scale)
      ..close();
    canvas.drawPath(cannonPath, Paint()..color = const Color(0xFF1E293B));
    canvas.drawPath(cannonPath, inkPaint);

    // Tech panel lines
    canvas.drawLine(
      Offset(ballRadius * 0.9, -4 * scale),
      Offset(ballRadius * 0.9, 4 * scale),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 1.5 * scale,
    );
    canvas.drawLine(
      Offset(ballRadius * 1.4, -3 * scale),
      Offset(ballRadius * 1.4, 3 * scale),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 1.5 * scale,
    );

    // Energy core – glowing circle in the center
    final corePos = Offset(ballRadius * 1.1, 0);
    canvas.drawCircle(corePos, 6 * scale,
        Paint()..color = const Color(0xFFFF4B4B).withValues(alpha: 0.3));
    canvas.drawCircle(corePos, 4 * scale,
        Paint()..color = const Color(0xFFFF4B4B));
    canvas.drawCircle(corePos, 4 * scale, inkPaint);
    canvas.drawCircle(corePos, 2 * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Energy rings (pulsing)
    final ringSize = 1 + math.sin(_pulse * 6) * 0.3;
    canvas.drawCircle(
      corePos,
      7 * scale * ringSize,
      Paint()
        ..color = const Color(0xFFFF4B4B).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );

    // Emitter tip – bright glow at barrel end
    final emitter = Offset(ballRadius * 2.35, 0);
    canvas.drawCircle(emitter, 4.5 * scale,
        Paint()..color = const Color(0xFFFF4B4B).withValues(alpha: 0.5));
    canvas.drawCircle(emitter, 2.5 * scale,
        Paint()..color = const Color(0xFFFF8888).withValues(alpha: 0.8));
    canvas.drawCircle(emitter, 1.2 * scale,
        Paint()..color = Colors.white);

    // Grip / stock
    final gripPath = Path()
      ..moveTo(ballRadius * 0.58, 3 * scale)
      ..lineTo(ballRadius * 0.72, 3 * scale)
      ..lineTo(ballRadius * 0.68, 18 * scale)
      ..lineTo(ballRadius * 0.52, 17 * scale)
      ..close();
    canvas.drawPath(gripPath, Paint()..color = const Color(0xFF374151));
    canvas.drawPath(gripPath, inkPaint);
  }
}
