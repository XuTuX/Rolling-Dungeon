import 'dart:math' as math;
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/game_snapshot.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';

class AutoBattleGame extends FlameGame {
  GameSnapshot? _snapshot;

  double _arenaScale = 1.0;
  Offset _arenaOffset = Offset.zero;
  EdgeInsets _viewportPadding = EdgeInsets.zero;

  final double _arenaWidth = 500;
  final double _arenaHeight = 500;

  // VFX State
  final List<_DamageNumber> _damageNumbers = [];
  final Map<String, double> _prevHp = {};
  double _shakeIntensity = 0;
  int _snapshotReceivedAt = 0;

  set viewportPadding(EdgeInsets padding) {
    if (_viewportPadding == padding) return;
    _viewportPadding = padding;
    _updateTransform();
  }

  void applySnapshot(GameSnapshot snapshot) {
    // Process Damage Events from Engine
    for (final e in snapshot.damageEvents) {
      final victim = snapshot.players
          .cast<PlayerSnapshot?>()
          .firstWhere((p) => p?.id == e.victimId, orElse: () => null);
      final isPlayer = victim?.isEnemy == false;
      _damageNumbers.add(_DamageNumber(
        pos: Offset(e.x, e.y - 15),
        value: e.damage.toInt(),
        color: isPlayer ? const Color(0xFFFF5252) : const Color(0xFFFFD54F),
      ));
      if (isPlayer) _shakeIntensity = 6.0;
    }

    _snapshot = snapshot;
    _snapshotReceivedAt = DateTime.now().millisecondsSinceEpoch;
    _updateTransform();
  }

  @override
  Color backgroundColor() => AutoBattlePalette.background;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateTransform();
  }

  void _updateTransform() {
    if (!hasLayout) return;
    final availW = math.max(
        100.0, size.x - _viewportPadding.left - _viewportPadding.right);
    final availH = math.max(
        100.0, size.y - _viewportPadding.top - _viewportPadding.bottom);
    final scaleX = availW / _arenaWidth;
    final scaleY = availH / _arenaHeight;
    _arenaScale = math.min(scaleX, scaleY) * 0.95;
    _arenaOffset = Offset(
      _viewportPadding.left + (availW - _arenaWidth * _arenaScale) / 2,
      _viewportPadding.top + (availH - _arenaHeight * _arenaScale) / 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeIntensity > 0) {
      _shakeIntensity = math.max(0, _shakeIntensity - dt * 20);
    }
    _damageNumbers.removeWhere((d) => d.life <= 0);
    for (final d in _damageNumbers) {
      d.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    if (_shakeIntensity > 0) {
      canvas.translate(
        (math.Random().nextDouble() - 0.5) * _shakeIntensity,
        (math.Random().nextDouble() - 0.5) * _shakeIntensity,
      );
    }

    _renderArena(canvas);
    _renderCombatEffects(canvas);
    _renderSnapshot(canvas);
    _renderVFX(canvas);

    canvas.restore();
  }

  void _renderArena(Canvas canvas) {
    final centerX = _arenaOffset.dx + (_arenaWidth * _arenaScale) / 2;
    final centerY = _arenaOffset.dy + (_arenaHeight * _arenaScale) / 2;
    final radius = (_arenaWidth * _arenaScale / 2) - 10.0 * _arenaScale;

    // 1. Calculate Hexagon Vertices
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;
      final vx = centerX + radius * math.cos(angle);
      final vy = centerY + radius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(vx, vy);
      } else {
        hexPath.lineTo(vx, vy);
      }
    }
    hexPath.close();

    // 2. Draw Shadow/Offset Layer
    canvas.drawPath(
      hexPath.shift(const Offset(8, 8)),
      Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.1),
    );

    // 3. Draw Background
    canvas.drawPath(hexPath, Paint()..color = AutoBattlePalette.arenaBg);

    // 4. Draw Hexagonal Grid
    final gridPaint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;

    const gridStep = 45.0;
    // We draw lines in 3 directions: 0, 60, 120 degrees
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      final nx = math.cos(angle);
      final ny = math.sin(angle);

      for (double d = -radius; d <= radius; d += gridStep * _arenaScale) {
        final lx = -ny;
        final ly = nx;

        canvas.save();
        canvas.clipPath(hexPath);
        canvas.drawLine(
          Offset(centerX + nx * d - lx * radius * 2,
              centerY + ny * d - ly * radius * 2),
          Offset(centerX + nx * d + lx * radius * 2,
              centerY + ny * d + ly * radius * 2),
          gridPaint,
        );
        canvas.restore();
      }
    }

    // 5. Draw Outline
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = AutoBattlePalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _renderCombatEffects(Canvas canvas) {
    if (_snapshot == null) return;

    // Hazards (Mines/Poison Clouds)
    for (final h in _snapshot!.hazards) {
      final pos = _toScreen(h.x, h.y);
      final r = h.radius * _arenaScale;

      if (h.type == 'mine') {
        canvas.drawCircle(
          pos,
          r,
          Paint()..color = AutoBattlePalette.primary.withValues(alpha: 0.2),
        );
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(
          pos,
          r * 0.42,
          Paint()..color = AutoBattlePalette.primary,
        );
        canvas.drawCircle(
          pos,
          r * 0.42,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          pos - Offset(r * 0.16, r * 0.18),
          r * 0.12,
          Paint()..color = const Color(0xFFFFD43B),
        );
      } else {
        final remaining =
            (h.expiresAt - _snapshot!.serverTime).clamp(0, 1000) / 1000.0;
        final rand = math.Random(h.id.hashCode);
        // Render as a soft fog cloud
        for (var i = 0; i < 4; i++) {
          final spread = rand.nextDouble() * r * 0.4;
          final angle = rand.nextDouble() * math.pi * 2;
          final bubblePos =
              pos + Offset(math.cos(angle) * spread, math.sin(angle) * spread);

          final bubbleR = (r * (0.7 + rand.nextDouble() * 0.5));

          final cloudColor = h.type == 'fire'
              ? const Color(0xFFFF922B)
              : AutoBattlePalette.mint;

          canvas.drawCircle(
            bubblePos,
            bubbleR,
            Paint()
              ..color = cloudColor.withValues(
                alpha: (0.15 + 0.45 * remaining) * (1.0 - (spread / (r * 0.5))),
              ),
          );

          canvas.drawCircle(
            bubblePos,
            bubbleR,
            Paint()
              ..color = AutoBattlePalette.ink.withValues(alpha: 0.1 * remaining)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5 * _arenaScale,
          );
        }
      }
    }

    // Attacks (VFX) - Placeholder for future effects

    // Projectiles (Bullets)
    for (final p in _snapshot!.projectiles) {
      final pos = _toScreen(p.x, p.y);
      final r = p.radius * _arenaScale;

      final canReflect = p.reflectsRemaining > 0;

      if (canReflect) {
        canvas.drawCircle(
          pos,
          r * 2.2,
          Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.15),
        );
      }

      final bulletColor = canReflect
          ? const Color(0xFF38BDF8)
          : _colorFromHex(p.color, fallback: AutoBattlePalette.ink);
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = bulletColor,
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = AutoBattlePalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _renderSnapshot(Canvas canvas) {
    if (_snapshot == null) return;

    for (final f in _snapshot!.foods) {
      final pos = _toScreen(f.x, f.y);
      final r = f.radius * _arenaScale;
      final color =
          f.kind == 'big' ? AutoBattlePalette.gold : AutoBattlePalette.mint;
      canvas.drawCircle(pos, r, Paint()..color = color);
      canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    for (final obs in _snapshot!.obstacles) {
      final pos = _toScreen(obs.x, obs.y);
      final r = obs.radius * _arenaScale;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(obs.rotation);

      final path = Path();
      path.moveTo(-r, -r * 0.8);
      path.lineTo(-r * 0.7, -r);
      path.lineTo(r * 0.8, -r * 0.9);
      path.lineTo(r, -r * 0.2);
      path.lineTo(r * 0.9, r * 0.8);
      path.lineTo(r * 0.2, r);
      path.lineTo(-r * 0.9, r * 0.7);
      path.close();

      canvas.drawPath(path, Paint()..color = const Color(0xFFD7CCC8));
      canvas.drawPath(
          path,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.restore();
    }

    for (final p in _snapshot!.players) {
      if (!p.alive) continue;
      final pos = _toScreen(p.x, p.y);
      final r = p.radius * _arenaScale;
      final bodyAngle = _bodyAngle(p);

      // Body Shadow
      canvas.drawPath(
        _getGlobalShapePath(p.characterShape, pos + const Offset(4, 4), r, bodyAngle),
        Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.1),
      );

      // Character Body
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(bodyAngle + math.pi / 2);
      final bodyPath = _getLocalShapePath(p.characterShape, r);
      canvas.drawPath(bodyPath, Paint()..color = p.flutterColor);
      canvas.drawPath(
        bodyPath,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            colors: [
              Colors.white.withValues(alpha: 0.32),
              Colors.white.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
      canvas.drawCircle(
        Offset(-r * 0.22, -r * 0.24),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      canvas.drawPath(
          bodyPath,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);

      // Face (Reactive Sketch Style)
      final prevHp = _prevHp[p.id] ?? p.hp;
      final isHurt = p.hp < prevHp;
      _prevHp[p.id] = p.hp;

      final eyeY = -r * 0.12;
      final eyeSpacing = r * 0.28;
      final eyeR = r * 0.14;

      if (isHurt) {
        // X Eyes
        final inkPaint = Paint()
          ..color = AutoBattlePalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        for (final dx in [-eyeSpacing, eyeSpacing]) {
          canvas.drawLine(Offset(dx - eyeR, eyeY - eyeR),
              Offset(dx + eyeR, eyeY + eyeR), inkPaint);
          canvas.drawLine(Offset(dx + eyeR, eyeY - eyeR),
              Offset(dx - eyeR, eyeY + eyeR), inkPaint);
        }
        // O Mouth
        canvas.drawCircle(Offset(0, r * 0.25), r * 0.15, inkPaint);
      } else {
        // Normal Face
        for (final dx in [-eyeSpacing, eyeSpacing]) {
          canvas.drawCircle(
              Offset(dx, eyeY), eyeR, Paint()..color = Colors.white);
          canvas.drawCircle(Offset(dx + 1.5, eyeY + 1), eyeR * 0.55,
              Paint()..color = AutoBattlePalette.ink);
          canvas.drawCircle(
              Offset(dx, eyeY),
              eyeR,
              Paint()
                ..color = AutoBattlePalette.ink
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
        final mouthPath = Path();
        mouthPath.moveTo(-r * 0.15, r * 0.22);
        mouthPath.quadraticBezierTo(0, r * 0.38, r * 0.15, r * 0.22);
        canvas.drawPath(
            mouthPath,
            Paint()
              ..color = AutoBattlePalette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round);
      }
      canvas.restore();

      if (p.shield > 0) {
        final shieldRatio =
            p.maxShield <= 0 ? 0.0 : (p.shield / p.maxShield).clamp(0.0, 1.0);
        canvas.drawCircle(
          pos,
          r + 7,
          Paint()
            ..color = const Color(0xFF38BDF8).withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: r + 7),
          -math.pi / 2,
          math.pi * 2 * shieldRatio,
          false,
          Paint()
            ..color = const Color(0xFF38BDF8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }

      if (p.barrierHp > 0) {
        final barrierRatio = p.barrierMaxHp <= 0
            ? 1.0
            : (p.barrierHp / p.barrierMaxHp).clamp(0.0, 1.0);
        final barrierR = r * 1.28;
        canvas.drawCircle(
          pos,
          barrierR,
          Paint()
            ..color = const Color(0xFF60A5FA).withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: barrierR),
          -math.pi / 2,
          math.pi * 2 * barrierRatio,
          false,
          Paint()
            ..color = const Color(0xFF2563EB).withValues(alpha: 0.78)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = StrokeCap.round,
        );
      }

      if (p.ownedWeapons.any((w) => w == 'aura')) {
        final pulse =
            (math.sin(DateTime.now().millisecondsSinceEpoch / 250) * 0.5 + 0.5);
        canvas.drawCircle(
          pos,
          r + AURA_RADIUS * _arenaScale,
          Paint()
            ..color =
                const Color(0xFFA855F7).withValues(alpha: 0.05 + 0.1 * pulse)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          r + AURA_RADIUS * _arenaScale,
          Paint()
            ..color = const Color(0xFFA855F7).withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Weapon Decoration (Simple indicator)
      _renderWeaponDecoration(canvas, pos, r, p);

      // HP Bar
      final barW = r * 2.5;
      final barRect = Rect.fromCenter(
          center: pos + Offset(0, -r - 18), width: barW, height: 8);
      canvas.drawRect(barRect, Paint()..color = Colors.white);
      canvas.drawRect(
          barRect,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawRect(
        Rect.fromLTWH(barRect.left, barRect.top,
            barRect.width * (p.hp / p.maxHp), barRect.height),
        Paint()
          ..color = p.hp / p.maxHp > 0.3
              ? AutoBattlePalette.mint
              : AutoBattlePalette.primary,
      );
    }
  }

  void _renderWeaponDecoration(
      Canvas canvas, Offset pos, double r, PlayerSnapshot player) {
    final ink = Paint()
      ..color = AutoBattlePalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (player.isEnemy && player.weaponCount > 0) {
      final weaponCount = math.max(1, player.weaponCount);
      final baseAngle = _weaponAngle(player);
      for (int i = 0; i < weaponCount; i++) {
        _renderGunDecoration(
          canvas,
          pos,
          r,
          baseAngle + math.pi * 2 * i / weaponCount,
          ink,
          player.flutterColor,
        );
      }
      return;
    }

    final angle = _weaponAngle(player);
    final weaponTypes = [
      player.characterType,
      ...player.ownedWeapons.where((weapon) => weapon != player.characterType),
    ];

    for (int i = 0; i < weaponTypes.length; i++) {
      final wType = weaponTypes[i];
      final wAngle = angle + (math.pi * 2 * i / weaponTypes.length);

      switch (wType) {
        case 'blade':
          _renderBlade(canvas, pos, r, wAngle, ink, player.flutterColor, false);
          break;
        case 'heavy_blade':
          _renderBlade(canvas, pos, r, wAngle, ink, player.flutterColor, true);
          break;
        case 'miner':
          _renderMiner(canvas, pos, r, wAngle, ink, player.flutterColor);
          break;
        case 'poison':
          _renderPoisonNozzle(canvas, pos, r, wAngle, ink, player.flutterColor);
          break;
        case 'footsteps':
          _renderFootstepsDecoration(
              canvas, pos, r, wAngle, ink, player.flutterColor);
          break;
        case 'minigun':
        case 'burst':
          _renderGunDecoration(canvas, pos, r, wAngle, ink, player.flutterColor,
              isMinigun: true);
          break;
        case 'long_gun':
        case 'ricochet':
        case 'gunner':
          _renderGunDecoration(
              canvas, pos, r, wAngle, ink, player.flutterColor);
          break;
      }
    }
  }

  void _drawHand(
      Canvas canvas, double r, Offset center, Color bodyColor, Paint ink) {
    final handR = r * 0.3;
    canvas.drawCircle(center + const Offset(3, 3), handR,
        Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.5));
    canvas.drawCircle(center, handR, Paint()..color = bodyColor);
    canvas.drawCircle(center, handR, ink);
  }

  void _renderBlade(Canvas canvas, Offset pos, double r, double angle,
      Paint ink, Color bodyColor, bool isHeavy) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final rangeMult = isHeavy ? 1.5 : 1.0;

    canvas.drawLine(
      Offset(r * 0.42, 0),
      Offset(r * 1.62 * rangeMult, 0),
      Paint()
        ..color = isHeavy ? const Color(0xFF475569) : const Color(0xFF92400E)
        ..strokeWidth = (isHeavy ? 10 : 6) * _arenaScale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(r * 0.42, 0), Offset(r * 1.62 * rangeMult, 0), ink);
    _drawHand(canvas, r, Offset(r * 0.6, r * 0.25), bodyColor, ink);
    canvas.restore();
  }

  void _renderMiner(Canvas canvas, Offset pos, double r, double angle,
      Paint ink, Color bodyColor) {
    final minePos =
        pos + Offset(math.cos(angle) * (r + 10), math.sin(angle) * (r + 10));
    canvas.drawCircle(
        minePos, 8 * _arenaScale, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(minePos, 8 * _arenaScale, ink);
  }

  void _renderPoisonNozzle(Canvas canvas, Offset pos, double r, double angle,
      Paint ink, Color bodyColor) {
    final rear = angle + math.pi;
    final nozzle = pos + Offset(math.cos(rear) * r, math.sin(rear) * r);
    canvas.drawLine(
      pos + Offset(math.cos(rear) * r * 0.35, math.sin(rear) * r * 0.35),
      nozzle,
      Paint()
        ..color = AutoBattlePalette.mint
        ..strokeWidth = 5 * _arenaScale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(nozzle, 4 * _arenaScale, ink);
  }

  void _renderFootstepsDecoration(Canvas canvas, Offset pos, double r,
      double angle, Paint ink, Color bodyColor) {
    final rear = angle + math.pi;
    final nozzle = pos + Offset(math.cos(rear) * r, math.sin(rear) * r);
    canvas.drawCircle(
        nozzle, 6 * _arenaScale, Paint()..color = const Color(0xFFFF922B));
    canvas.drawCircle(nozzle, 6 * _arenaScale, ink);
  }

  void _renderGunDecoration(
    Canvas canvas,
    Offset pos,
    double r,
    double angle,
    Paint ink,
    Color bodyColor, {
    bool isMinigun = false,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    // Simplified Gun - Just a sturdy circle barrel
    final gunWidth = isMinigun ? r * 0.5 : r * 0.8;
    final gunHeight = isMinigun ? r * 0.3 : r * 0.4;
    final gunRect = Rect.fromLTWH(r * 0.7, -gunHeight / 2, gunWidth, gunHeight);
    canvas.drawOval(
        gunRect,
        Paint()
          ..color =
              isMinigun ? const Color(0xFF475569) : const Color(0xFF64748B));
    canvas.drawOval(gunRect, ink);

    // Tip detail
    canvas.drawCircle(
      Offset(r * 1.5, 0),
      r * 0.15,
      Paint()..color = AutoBattlePalette.gold,
    );

    // Hand holding the gun
    _drawHand(canvas, r, Offset(r * 0.65, r * 0.25), bodyColor, ink);

    canvas.restore();
  }

  Color _colorFromHex(String hex, {required Color fallback}) {
    final normalized = hex.replaceAll('#', '');
    final value = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.tryParse(value, radix: 16) ?? fallback.toARGB32());
  }

  double _weaponAngle(PlayerSnapshot player) {
    if (player.characterType != 'gunner' && player.characterType != 'blade') {
      return player.targetAngle;
    }
    if (_snapshotReceivedAt == 0) return player.targetAngle;

    final elapsedMs =
        DateTime.now().millisecondsSinceEpoch - _snapshotReceivedAt;
    return _normalizeAngle(player.targetAngle + elapsedMs / 1000.0 * 6.2);
  }

  double _bodyAngle(PlayerSnapshot player) {
    final velocityLength =
        math.sqrt(player.vx * player.vx + player.vy * player.vy);
    if (velocityLength > 0.04) {
      return math.atan2(player.vy, player.vx);
    }
    return player.targetAngle;
  }

  Path _getGlobalShapePath(
      String shape, Offset center, double radius, double angle) {
    if (shape == 'circle') {
      return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    }

    final points = _getLocalShapePoints(shape, radius);
    final rotation = angle + math.pi / 2;
    final cosA = math.cos(rotation);
    final sinA = math.sin(rotation);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final rotated = Offset(
        center.dx + p.dx * cosA - p.dy * sinA,
        center.dy + p.dx * sinA + p.dy * cosA,
      );
      if (i == 0) {
        path.moveTo(rotated.dx, rotated.dy);
      } else {
        path.lineTo(rotated.dx, rotated.dy);
      }
    }
    return path..close();
  }

  Path _getLocalShapePath(String shape, double radius) {
    if (shape == 'circle') {
      return Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
    }
    final points = _getLocalShapePoints(shape, radius);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    return path..close();
  }

  List<Offset> _getLocalShapePoints(String shape, double radius) {
    if (shape == 'square') {
      final r = radius * 0.95;
      return [
        Offset(-r, -r),
        Offset(r, -r),
        Offset(r, r),
        Offset(-r, r),
      ];
    } else if (shape == 'triangle') {
      return [
        Offset(0, -radius * 1.16),
        Offset(radius * 1.05, radius * 0.7),
        Offset(-radius * 1.05, radius * 0.7),
      ];
    }
    return []; // Circle case handled separately in paths
  }

  double _normalizeAngle(double angle) {
    const fullTurn = math.pi * 2;
    final normalized = angle % fullTurn;
    return normalized < 0 ? normalized + fullTurn : normalized;
  }

  void _renderVFX(Canvas canvas) {
    for (final d in _damageNumbers) {
      final pos = _toScreen(d.pos.dx, d.pos.dy);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${d.value}',
          style: TextStyle(
            color: d.color,
            fontSize: 28 * _arenaScale * (1 + (1 - d.life) * 0.5),
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
              Shadow(color: AutoBattlePalette.ink, offset: Offset(-1, -1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  Offset _toScreen(double x, double y) => Offset(
      _arenaOffset.dx + x * _arenaScale, _arenaOffset.dy + y * _arenaScale);
}

class _DamageNumber {
  Offset pos;
  int value;
  Color color;
  double life = 1.0;

  _DamageNumber({required this.pos, required this.value, required this.color});

  void update(double dt) {
    pos += const Offset(0, -50) * dt;
    life -= dt * 1.5;
  }
}
