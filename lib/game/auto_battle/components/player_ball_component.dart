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

  void _drawRoughPath(Canvas canvas, Path path, Paint paint, {double jitter = 0.8}) {
    final metrics = path.computeMetrics();
    final roughPath = Path();
    final rand = math.Random(42); // Seed for consistency

    for (final metric in metrics) {
      const step = 4.0;
      for (var d = 0.0; d < metric.length; d += step) {
        final pos = metric.getTangentForOffset(d)!.position;
        final offset = Offset(
          (rand.nextDouble() - 0.5) * jitter,
          (rand.nextDouble() - 0.5) * jitter,
        );
        if (d == 0) {
          roughPath.moveTo(pos.dx + offset.dx, pos.dy + offset.dy);
        } else {
          roughPath.lineTo(pos.dx + offset.dx, pos.dy + offset.dy);
        }
      }
    }
    if (path.contains(const Offset(0,0))) roughPath.close(); // Approximation
    canvas.drawPath(roughPath, paint);
  }

  void _drawHatching(Canvas canvas, Rect rect, double angle, double spacing, Paint paint) {
    canvas.save();
    canvas.clipRect(rect);
    canvas.rotate(angle);
    final diagonal = math.sqrt(rect.width * rect.width + rect.height * rect.height);
    for (var i = -diagonal; i < diagonal; i += spacing) {
      canvas.drawLine(Offset(i, -diagonal), Offset(i + diagonal * 0.5, diagonal), paint);
    }
    canvas.restore();
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
        return 'SPR';
      case 'miner':
        return 'MIN';
      case 'laser':
        return 'CBW';
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
        _renderSpear(canvas, scale);
        break;
      case 'miner':
        _renderHeldMine(canvas, scale);
        break;
      case 'laser':
        _renderCrossbow(canvas, scale);
        break;
      default:
        break;
    }

    canvas.restore();
  }

  void _renderGun(Canvas canvas, double scale) {
    // ── Ultra Premium Rough Sketch Revolver ──
    final inkPaint = Paint()
      ..color = AutoBattlePalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    final recoil = _thrust * 15.0 * scale;
    final tilt = _thrust * 0.22;
    
    canvas.save();
    canvas.translate(-recoil, 0);
    canvas.rotate(-tilt);

    // Frame - Rough Path
    final framePath = Path()
      ..moveTo(ballRadius * 0.55, -9 * scale)
      ..lineTo(ballRadius * 1.15, -9 * scale)
      ..lineTo(ballRadius * 1.25, -4.5 * scale)
      ..lineTo(ballRadius * 2.3, -4.5 * scale)
      ..lineTo(ballRadius * 2.3, 4.5 * scale)
      ..lineTo(ballRadius * 0.55, 4.5 * scale)
      ..close();
    
    canvas.drawPath(framePath, Paint()..color = const Color(0xFF94A3B8));
    _drawRoughPath(canvas, framePath, inkPaint);

    // Hatching Shadow on Frame
    _drawHatching(canvas, Rect.fromLTWH(ballRadius * 0.6, -8 * scale, 20 * scale, 12 * scale), 0.5, 4 * scale, Paint()..color = Colors.black26..strokeWidth = 1);

    // Cylinder - More detailed
    final cylinderRect = Rect.fromLTWH(ballRadius * 0.7, -8 * scale, 14 * scale, 16 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(cylinderRect, Radius.circular(4 * scale)), Paint()..color = const Color(0xFF334155));
    _drawRoughPath(canvas, Path()..addRRect(RRect.fromRectAndRadius(cylinderRect, Radius.circular(4 * scale))), inkPaint);
    
    // Cylinder detail lines
    for (var i = 0; i < 3; i++) {
      final y = -4 * scale + i * 4 * scale;
      canvas.drawLine(Offset(ballRadius * 0.75, y), Offset(ballRadius * 0.75 + 10 * scale, y), Paint()..color = Colors.white24..strokeWidth = 2 * scale);
    }

    // Grip - Hand-drawn curve
    final gripPath = Path()
      ..moveTo(ballRadius * 0.6, 4 * scale)
      ..quadraticBezierTo(ballRadius * 0.9, 5 * scale, ballRadius * 0.8, 26 * scale)
      ..lineTo(ballRadius * 0.4, 24 * scale)
      ..quadraticBezierTo(ballRadius * 0.45, 10 * scale, ballRadius * 0.55, 4 * scale);
    canvas.drawPath(gripPath, Paint()..color = const Color(0xFF78350F));
    _drawRoughPath(canvas, gripPath, inkPaint);

    // Hammer & Trigger Guard
    _drawRoughPath(canvas, Path()..addOval(Rect.fromCircle(center: Offset(ballRadius * 0.8, 8 * scale), radius: 5 * scale)), inkPaint..strokeWidth = 2 * scale);
    
    if (_thrust > 0.7) {
      _renderMuzzleFlash(canvas, Offset(ballRadius * 2.35, 0), scale);
      _renderSmoke(canvas, Offset(ballRadius * 2.5, -5 * scale), scale);
    }

    canvas.restore();
  }

  void _renderSmoke(Canvas canvas, Offset pos, double scale) {
    final t = (_pulse * 5) % 1.0;
    final ink = Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 1.5 * scale;
    for (var i = 0; i < 3; i++) {
      final r = (5 + i * 8) * scale * t;
      canvas.drawCircle(pos + Offset(i * 10 * scale * t, -i * 5 * scale * t), r, ink);
    }
  }

  void _renderMuzzleFlash(Canvas canvas, Offset muzzle, double scale) {
    final flashPaint = Paint()..color = AutoBattlePalette.gold;
    final size = 16 * scale * _thrust;
    
    final path = Path();
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final r = i % 3 == 0 ? size : size * 0.4;
      final x = muzzle.dx + math.cos(angle) * r;
      final y = muzzle.dy + math.sin(angle) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, flashPaint);
    _drawRoughPath(canvas, path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5 * scale, jitter: 1.2);
  }

  void _renderSpear(Canvas canvas, double scale) {
    // ── Ultra Premium Rough Sketch Spear ──
    final inkPaint = Paint()
      ..color = AutoBattlePalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    final thrustExt = 22.0 * _thrust * scale;
    final shaftStart = ballRadius * 0.2;
    final shaftEnd = ballRadius * 2.8 + thrustExt;
    
    // Shaft with jitter
    final shaftPath = Path()..moveTo(shaftStart, 0)..lineTo(shaftEnd, 0);
    canvas.drawLine(Offset(shaftStart, 0), Offset(shaftEnd, 0), Paint()..color = const Color(0xFF451A03)..strokeWidth = 6 * scale);
    _drawRoughPath(canvas, shaftPath, inkPaint..strokeWidth = 2.8 * scale);

    // Wrapped grip area - Hatching
    final gripRect = Rect.fromLTWH(ballRadius * 0.4, -4 * scale, 12 * scale, 8 * scale);
    canvas.drawRect(gripRect, Paint()..color = const Color(0xFF92400E));
    _drawHatching(canvas, gripRect, 0.8, 3 * scale, Paint()..color = Colors.black26..strokeWidth = 1);
    _drawRoughPath(canvas, Path()..addRect(gripRect), inkPaint..strokeWidth = 2 * scale);

    // Spear Head - More organic shape
    final headStart = shaftEnd;
    final headPath = Path()
      ..moveTo(headStart, -9 * scale)
      ..quadraticBezierTo(headStart + 12 * scale, -8 * scale, headStart + 32 * scale, 0)
      ..quadraticBezierTo(headStart + 12 * scale, 8 * scale, headStart, 9 * scale)
      ..lineTo(headStart - 4 * scale, 0)
      ..close();
    
    canvas.drawPath(headPath, Paint()..color = const Color(0xFFCBD5E1));
    _drawRoughPath(canvas, headPath, inkPaint..strokeWidth = 3.5 * scale, jitter: 1.2);
    
    // Shading on head
    _drawHatching(canvas, Rect.fromLTWH(headStart, -5 * scale, 20 * scale, 10 * scale), 0.7, 2.5 * scale, Paint()..color = Colors.black12);

    // Animated Multi-Strand Tassel
    final tasselWave = math.sin(_pulse * 12 + _motionEnergy * 8);
    for (var i = 0; i < 4; i++) {
      final off = i * 2.0 - 4.0;
      final tasselPath = Path()
        ..moveTo(headStart - 2 * scale, off * scale)
        ..quadraticBezierTo(
          headStart - 15 * scale, (off + 10 * tasselWave + i * 2) * scale,
          headStart - 35 * scale, (off + 15 * tasselWave + i * 5) * scale,
        );
      canvas.drawPath(tasselPath, Paint()..color = AutoBattlePalette.primary..style = PaintingStyle.stroke..strokeWidth = 2.5 * scale..strokeCap = StrokeCap.round);
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
    // ── Ultra Premium Rough Sketch TNT ──
    final inkPaint = Paint()
      ..color = AutoBattlePalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    final center = Offset(ballRadius * 1.2, -4 * scale);
    final shake = math.sin(_pulse * 30) * 1.5 * _motionEnergy * scale;

    canvas.save();
    canvas.translate(shake, shake);

    // Sticks with Jitter
    for (var i = -1; i <= 1; i++) {
      final x = center.dx + i * 7 * scale;
      final y = center.dy + (i.abs() * 3 * scale);
      final stickPath = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 8 * scale, height: 28 * scale), Radius.circular(2 * scale)));
      canvas.drawPath(stickPath, Paint()..color = AutoBattlePalette.primary);
      _drawRoughPath(canvas, stickPath, inkPaint);
      
      // Vertical hatching on sticks
      _drawHatching(canvas, Rect.fromLTWH(x - 3 * scale, y - 10 * scale, 6 * scale, 20 * scale), 1.5, 3 * scale, Paint()..color = Colors.black26);
    }

    // Binding Straps - Bold
    for (var yOff in [-6, 6]) {
      final strap = Rect.fromLTWH(center.dx - 12 * scale, center.dy + yOff * scale - 2 * scale, 24 * scale, 4 * scale);
      canvas.drawRect(strap, Paint()..color = AutoBattlePalette.ink);
    }

    // Fuse - Hand-drawn
    final fusePath = Path()
      ..moveTo(center.dx, center.dy - 14 * scale)
      ..quadraticBezierTo(center.dx + 12 * scale, center.dy - 24 * scale, center.dx + 6 * scale, center.dy - 36 * scale);
    _drawRoughPath(canvas, fusePath, inkPaint..strokeWidth = 2.2 * scale);

    _renderSpark(canvas, Offset(center.dx + 6 * scale, center.dy - 36 * scale), scale);
    canvas.restore();
  }

  void _renderSpark(Canvas canvas, Offset pos, double scale) {
    final t = (_pulse * 20) % 1.0;
    final sparkPaint = Paint()..color = AutoBattlePalette.gold..strokeWidth = 2 * scale..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi * 2 / 8 + _pulse * 15;
      final dist = (8 + math.sin(t * 15) * 8) * scale;
      canvas.drawLine(pos, pos + Offset(math.cos(a) * dist, math.sin(a) * dist), sparkPaint);
    }
    canvas.drawCircle(pos, 4 * scale, Paint()..color = Colors.white);
  }

  void _renderCrossbow(Canvas canvas, double scale) {
    // ── Ultra Premium Rough Sketch Crossbow ──
    final inkPaint = Paint()
      ..color = AutoBattlePalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    final stringPull = _thrust * 14 * scale;
    final basePos = ballRadius * 0.7;
    
    // Detailed Stock - Rough Path
    final stockPath = Path()
      ..moveTo(basePos, -6 * scale)
      ..lineTo(basePos + 26 * scale, -5 * scale)
      ..lineTo(basePos + 28 * scale, 0)
      ..lineTo(basePos + 26 * scale, 5 * scale)
      ..lineTo(basePos, 6 * scale)
      ..close();
    canvas.drawPath(stockPath, Paint()..color = const Color(0xFF451A03));
    _drawRoughPath(canvas, stockPath, inkPaint);
    
    // Hatching on Stock
    _drawHatching(canvas, Rect.fromLTWH(basePos + 5 * scale, -4 * scale, 15 * scale, 8 * scale), 0.5, 3 * scale, Paint()..color = Colors.black26);

    // Flexible Limbs
    final limbsPath = Path()
      ..moveTo(basePos + 18 * scale, -32 * scale)
      ..quadraticBezierTo(basePos + 8 * scale + stringPull * 0.3, 0, basePos + 18 * scale, 32 * scale);
    
    canvas.drawPath(limbsPath, Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 8 * scale..strokeCap = StrokeCap.round);
    _drawRoughPath(canvas, limbsPath, inkPaint..strokeWidth = 2.5 * scale);

    // Bowstring
    final stringPath = Path()
      ..moveTo(basePos + 18 * scale, -31 * scale)
      ..lineTo(basePos + 6 * scale + stringPull, 0)
      ..lineTo(basePos + 18 * scale, 31 * scale);
    canvas.drawPath(stringPath, Paint()..color = const Color(0xFFF1F5F9)..style = PaintingStyle.stroke..strokeWidth = 1.8 * scale);

    // Bolt
    if (_thrust < 0.25) {
      final boltPath = Path()..moveTo(basePos + 4 * scale, 0)..lineTo(basePos + 36 * scale, 0);
      canvas.drawPath(boltPath, Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.stroke..strokeWidth = 4 * scale..strokeCap = StrokeCap.round);
      
      final tip = Path()
        ..moveTo(basePos + 36 * scale, -4.5 * scale)
        ..lineTo(basePos + 46 * scale, 0)
        ..lineTo(basePos + 36 * scale, 4.5 * scale)
        ..close();
      canvas.drawPath(tip, Paint()..color = const Color(0xFF0F172A));
      _drawRoughPath(canvas, tip, inkPaint..strokeWidth = 2 * scale);
    }
  }
}
