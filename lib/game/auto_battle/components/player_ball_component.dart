import 'dart:math' as math;

import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/components/hp_bar_component.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:circle_war/game/auto_battle/ui/weapon_designs.dart';
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
  int weaponCount = 1;

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
        weaponCount = math.min(PLAYER_MAX_WEAPON_COUNT, snapshot.weaponCount),
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
    weaponCount = math.min(PLAYER_MAX_WEAPON_COUNT, snapshot.weaponCount);
    final velocityLength =
        math.sqrt(snapshot.vx * snapshot.vx + snapshot.vy * snapshot.vy);

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
    _hitFlash = (_hitFlash - dt * 5).clamp(0, 1).toDouble();
    _thrust = (_thrust - dt * 6.5).clamp(0, 1).toDouble();
    _pulse = (_pulse + dt) % (math.pi * 2);
    _facingAngle = _lerpAngle(_facingAngle, _targetAngle, 0.25);
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
    canvas.rotate(_facingAngle + math.pi / 2);
    canvas.scale(stretch, squash);

    final bodyPath = _localTrianglePath(ballRadius);
    canvas.drawPath(
      bodyPath.shift(Offset(0, ballRadius * 0.16)),
      Paint()..color = const Color(0xFF9DB5D3).withValues(alpha: 0.22),
    );
    canvas.drawPath(bodyPath, Paint()..color = baseColor);
    canvas.drawPath(
      bodyPath,
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

    // ── Eyes and Mouth (Sketchy Style) ──
    if (alive) {
      final eyeSize = ballRadius * 0.16;
      final eyeOffset = ballRadius * 0.35;
      final isHurt = _hitFlash > 0.5;
      final eyeY = -ballRadius * 0.12;

      final inkPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * (ballRadius / 18).clamp(0.8, 1.2)
        ..strokeCap = StrokeCap.round;

      if (isHurt) {
        // X Eyes
        for (final xOff in [eyeOffset, -eyeOffset]) {
          canvas.drawLine(
            Offset(xOff - eyeSize * 0.8, eyeY - eyeSize * 0.8),
            Offset(xOff + eyeSize * 0.8, eyeY + eyeSize * 0.8),
            inkPaint,
          );
          canvas.drawLine(
            Offset(xOff + eyeSize * 0.8, eyeY - eyeSize * 0.8),
            Offset(xOff - eyeSize * 0.8, eyeY + eyeSize * 0.8),
            inkPaint,
          );
        }
        // O Mouth
        canvas.drawCircle(
            Offset(0, ballRadius * 0.25), ballRadius * 0.15, inkPaint);
      } else {
        // Normal Eyes
        canvas.drawCircle(
            Offset(eyeOffset, eyeY), eyeSize, Paint()..color = Colors.black);
        canvas.drawCircle(
            Offset(eyeOffset + eyeSize * 0.3, eyeY - eyeSize * 0.3),
            eyeSize * 0.3,
            Paint()..color = Colors.white);

        canvas.drawCircle(
            Offset(-eyeOffset, eyeY), eyeSize, Paint()..color = Colors.black);
        canvas.drawCircle(
            Offset(-eyeOffset + eyeSize * 0.3, eyeY - eyeSize * 0.3),
            eyeSize * 0.3,
            Paint()..color = Colors.white);

        // Smile
        final mouthPath = Path()
          ..moveTo(-ballRadius * 0.22, ballRadius * 0.22)
          ..quadraticBezierTo(
              0, ballRadius * 0.42, ballRadius * 0.22, ballRadius * 0.22);
        canvas.drawPath(mouthPath, inkPaint);
      }
    }

    canvas.drawPath(
      bodyPath,
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

  Path _localTrianglePath(double radius) {
    return Path()
      ..moveTo(0, -radius * 1.16)
      ..lineTo(radius * 0.96, radius * 0.76)
      ..lineTo(-radius * 0.96, radius * 0.76)
      ..close();
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

    for (int i = 0; i < math.max(1, weaponCount); i++) {
      final weaponAngle =
          _facingAngle + math.pi * 2 * i / math.max(1, weaponCount);
      final thrustOffset = 10.0 * _thrust * scale;

      canvas.save();
      canvas.translate(
        center.dx + math.cos(weaponAngle) * thrustOffset,
        center.dy + math.sin(weaponAngle) * thrustOffset,
      );
      canvas.rotate(weaponAngle);

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
          WeaponDesigns.renderGun(canvas, scale, _thrust, ballRadius, _pulse);
          break;
        case 'blade':
          WeaponDesigns.renderSpear(
              canvas, scale, _thrust, ballRadius, _pulse, _motionEnergy);
          break;
        case 'miner':
          WeaponDesigns.renderTNT(
              canvas, scale, ballRadius, _pulse, _motionEnergy);
          break;
        case 'laser':
          WeaponDesigns.renderCrossbow(canvas, scale, _thrust, ballRadius);
          break;
        default:
          break;
      }

      canvas.restore();
    }
  }

  void _renderPoisonVial(Canvas canvas, double scale) {
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(ballRadius * 1.08, -1 * scale);
    canvas.rotate(-0.22);
    canvas.drawCircle(Offset(2 * scale, 6 * scale), 12 * scale,
        Paint()..color = const Color(0xFFD1FAE5).withValues(alpha: 0.9));
    canvas.drawCircle(Offset(2 * scale, 6 * scale), 12 * scale, inkPaint);
    final liquidPath = Path()
      ..addArc(
          Rect.fromCircle(
              center: Offset(2 * scale, 6 * scale), radius: 10 * scale),
          0.3,
          math.pi - 0.6)
      ..close();
    canvas.drawPath(liquidPath, Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(Offset(-2 * scale, 4 * scale), 2.2 * scale,
        Paint()..color = const Color(0xFF86EFAC));
    final neckRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-2 * scale, -14 * scale, 8 * scale, 12 * scale),
        Radius.circular(2 * scale));
    canvas.drawRRect(neckRect,
        Paint()..color = const Color(0xFFD1FAE5).withValues(alpha: 0.85));
    canvas.drawRRect(neckRect, inkPaint);
    final corkRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-3 * scale, -19 * scale, 10 * scale, 6 * scale),
        Radius.circular(3 * scale));
    canvas.drawRRect(corkRect, Paint()..color = const Color(0xFF92400E));
    canvas.drawRRect(corkRect, inkPaint);
    canvas.restore();
  }
}
