import 'dart:math' as math;
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/game_snapshot.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

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
    // Detect Damage for Popups
    for (final p in snapshot.players) {
      final prev = _prevHp[p.id];
      if (prev != null && p.hp < prev) {
        final diff = (prev - p.hp).toInt();
        if (diff > 0) {
          _damageNumbers.add(_DamageNumber(
            pos: Offset(p.x, p.y - 20),
            value: diff,
            color: p.flutterColor,
          ));
          _shakeIntensity = 5.0;
        }
      }
      _prevHp[p.id] = p.hp;
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
    final rect = Rect.fromLTWH(_arenaOffset.dx, _arenaOffset.dy,
        _arenaWidth * _arenaScale, _arenaHeight * _arenaScale);

    final gridPaint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 50.0;

    // Paper first, then sketch lines. Drawing this in the opposite order hid the grid.
    canvas.drawRect(
      rect.shift(const Offset(8, 8)),
      Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.1),
    );

    canvas.drawRect(rect, Paint()..color = AutoBattlePalette.arenaBg);

    for (var x = 0.0; x <= _arenaWidth; x += step) {
      canvas.drawLine(_toScreen(x, 0), _toScreen(x, _arenaHeight), gridPaint);
    }
    for (var y = 0.0; y <= _arenaHeight; y += step) {
      canvas.drawLine(_toScreen(0, y), _toScreen(_arenaWidth, y), gridPaint);
    }

    canvas.drawRect(
      rect,
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
        // Sketch Mine – bold circles with spikes
        canvas.drawCircle(pos, r,
            Paint()..color = AutoBattlePalette.primary.withValues(alpha: 0.15));
        canvas.drawCircle(
            pos,
            r,
            Paint()
              ..color = AutoBattlePalette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        // Spike lines
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          canvas.drawLine(
            pos + Offset(math.cos(angle) * r * 0.7, math.sin(angle) * r * 0.7),
            pos + Offset(math.cos(angle) * r * 1.2, math.sin(angle) * r * 1.2),
            Paint()
              ..color = AutoBattlePalette.ink
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round,
          );
        }
        // Core
        canvas.drawCircle(
            pos, r * 0.35, Paint()..color = AutoBattlePalette.primary);
        canvas.drawCircle(
            pos,
            r * 0.35,
            Paint()
              ..color = AutoBattlePalette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        // Blink light
        canvas.drawCircle(
            pos, r * 0.15, Paint()..color = const Color(0xFFFFD43B));
      } else {
        // Poison cloud – sketchy with bubbles
        canvas.drawCircle(pos, r,
            Paint()..color = AutoBattlePalette.mint.withValues(alpha: 0.18));
        canvas.drawCircle(
            pos,
            r,
            Paint()
              ..color = AutoBattlePalette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        // Skull indicator
        canvas.drawCircle(pos, r * 0.3,
            Paint()..color = AutoBattlePalette.mint.withValues(alpha: 0.5));
      }
    }

    // Attacks (Blade Swings)
    for (final a in _snapshot!.attacks) {
      if (a.type == 'blade') {
        final pos = _toScreen(a.x, a.y);
        final r = a.radius * _arenaScale * 1.5;

        // Outer glow arc
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: r + 4),
          a.angle - 0.9,
          1.8,
          false,
          Paint()
            ..color = const Color(0xFF4ADE80).withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round,
        );

        // Main blade arc – thick ink
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: r),
          a.angle - 0.8,
          1.6,
          false,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );

        // Inner white highlight arc
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: r - 2),
          a.angle - 0.6,
          1.2,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );

        // Slash impact lines
        for (var i = 0; i < 3; i++) {
          final slashAngle = a.angle - 0.5 + i * 0.5;
          final slashStart = pos +
              Offset(math.cos(slashAngle) * r * 0.6,
                  math.sin(slashAngle) * r * 0.6);
          final slashEnd = pos +
              Offset(math.cos(slashAngle) * r * 1.15,
                  math.sin(slashAngle) * r * 1.15);
          canvas.drawLine(
            slashStart,
            slashEnd,
            Paint()
              ..color = AutoBattlePalette.ink.withValues(alpha: 0.4)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (a.type == 'laser') {
        final pos = _toScreen(a.x, a.y);
        final r = a.radius * _arenaScale;
        final beamWidth = 4 * a.scale;
        final endPos =
            pos + Offset(math.cos(a.angle) * r, math.sin(a.angle) * r);

        // Outer glow beam
        canvas.drawLine(
          pos,
          endPos,
          Paint()
            ..color = AutoBattlePalette.primary.withValues(alpha: 0.2)
            ..strokeWidth = beamWidth * 3
            ..strokeCap = StrokeCap.round,
        );

        // Main beam – vibrant red
        canvas.drawLine(
          pos,
          endPos,
          Paint()
            ..color = AutoBattlePalette.primary
            ..strokeWidth = beamWidth
            ..strokeCap = StrokeCap.round,
        );

        // Core beam – white hot center
        canvas.drawLine(
          pos,
          endPos,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = beamWidth * 0.35
            ..strokeCap = StrokeCap.round,
        );

        // Impact burst at end
        canvas.drawCircle(endPos, beamWidth * 1.5,
            Paint()..color = AutoBattlePalette.primary.withValues(alpha: 0.35));
        canvas.drawCircle(endPos, beamWidth * 0.8,
            Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
    }

    // Projectiles (Bullets)
    for (final p in _snapshot!.projectiles) {
      final pos = _toScreen(p.x, p.y);
      final r = p.radius * _arenaScale;

      final angle = math.atan2(p.vy, p.vx);
      final canReflect = p.reflectsRemaining > 0;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      // Motion trail lines
      final trailPaint = Paint()
        ..color = AutoBattlePalette.ink.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(-r * 2.5, -r * 0.6), Offset(-r * 5, -r * 0.6), trailPaint);
      canvas.drawLine(Offset(-r * 2, 0), Offset(-r * 4.5, 0), trailPaint);
      canvas.drawLine(
          Offset(-r * 2.5, r * 0.6), Offset(-r * 5, r * 0.6), trailPaint);

      // Bullet body – elongated with bright color
      final bulletColor = canReflect
          ? const Color(0xFF38BDF8) // Blue for reflecting bullets
          : AutoBattlePalette.ink;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 3.5, height: r * 1.8),
        Paint()..color = bulletColor,
      );
      // Ink outline
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 3.5, height: r * 1.8),
        Paint()
          ..color = AutoBattlePalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Bright tip
      canvas.drawCircle(
        Offset(r * 1.2, 0),
        r * 0.6,
        Paint()
          ..color =
              canReflect ? const Color(0xFF7DD3FC) : const Color(0xFFFFD43B),
      );

      // Reflect glow
      if (canReflect) {
        canvas.drawCircle(
          Offset.zero,
          r * 2.2,
          Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.15),
        );
      }

      canvas.restore();
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

    for (final p in _snapshot!.players) {
      if (!p.alive) continue;
      final pos = _toScreen(p.x, p.y);
      final r = p.radius * _arenaScale;

      // Body Shadow
      canvas.drawCircle(pos + const Offset(4, 4), r,
          Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.1));

      // Character Body
      canvas.drawCircle(pos, r, Paint()..color = p.flutterColor);
      canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = AutoBattlePalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);

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

    if (player.weaponCount > 0 || player.characterType == 'gunner') {
      final weaponCount = math.max(1, player.weaponCount);
      final baseAngle = _weaponAngle(player);
      for (int i = 0; i < weaponCount; i++) {
        _renderGunDecoration(
          canvas,
          pos,
          r,
          baseAngle + math.pi * 2 * i / weaponCount,
          ink,
        );
      }
      return;
    }

    final angle = _weaponAngle(player);
    if (player.characterType == 'blade') {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 2.25),
        -0.62,
        0.82,
        false,
        Paint()
          ..color = const Color(0xFF4ADE80).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.38
          ..strokeCap = StrokeCap.round,
      );

      final handle = RRect.fromRectAndRadius(
        Rect.fromLTWH(r * 0.44, -r * 0.11, r * 0.68, r * 0.22),
        Radius.circular(r * 0.07),
      );
      canvas.drawRRect(handle, Paint()..color = const Color(0xFF7C2D12));
      canvas.drawRRect(handle, ink);

      canvas.drawLine(
        Offset(r * 1.02, -r * 0.52),
        Offset(r * 1.02, r * 0.52),
        Paint()
          ..color = const Color(0xFFEAB308)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );

      final bladePath = Path()
        ..moveTo(r * 1.06, -r * 0.24)
        ..quadraticBezierTo(r * 2.18, -r * 0.34, r * 3.32, -r * 0.04)
        ..lineTo(r * 3.58, 0)
        ..quadraticBezierTo(r * 2.18, r * 0.34, r * 1.06, r * 0.24)
        ..close();
      canvas.drawPath(bladePath, Paint()..color = const Color(0xFFF1F5F9));
      canvas.drawPath(
        bladePath,
        Paint()
          ..color = AutoBattlePalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawLine(
        Offset(r * 1.2, -r * 0.06),
        Offset(r * 2.95, -r * 0.02),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
          Offset(r * 0.2, 0), r * 0.13, Paint()..color = AutoBattlePalette.ink);
      canvas.restore();
    } else if (player.characterType == 'miner') {
      // Mini TNT
      canvas.drawCircle(pos + Offset(r + 5, -r + 5), 5,
          Paint()..color = const Color(0xFFEF4444));
      canvas.drawCircle(pos + Offset(r + 5, -r + 5), 5, ink);
    } else if (player.characterType == 'laser') {
      // Mini laser indicator
      canvas.drawLine(
          pos + Offset(r - 2, 0),
          pos + Offset(r + 14, 0),
          Paint()
            ..color = AutoBattlePalette.primary
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(pos + Offset(r + 14, 0), 3,
          Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  void _renderGunDecoration(
    Canvas canvas,
    Offset pos,
    double r,
    double angle,
    Paint ink,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final barrel = Rect.fromLTWH(r * 0.65, -r * 0.18, r * 1.35, r * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrel, Radius.circular(r * 0.08)),
      Paint()..color = const Color(0xFF374151),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrel, Radius.circular(r * 0.08)),
      ink,
    );
    canvas.drawCircle(Offset(r * 2.08, 0), r * 0.16,
        Paint()..color = const Color(0xFFFFD43B));
    canvas.drawLine(
      Offset(r * 0.92, r * 0.2),
      Offset(r * 1.14, r * 0.5),
      Paint()
        ..color = AutoBattlePalette.ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
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
            color: Colors.white,
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
