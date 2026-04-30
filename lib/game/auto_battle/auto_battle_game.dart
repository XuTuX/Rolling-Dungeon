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
          final bubblePos = pos + Offset(math.cos(angle) * spread, math.sin(angle) * spread);
          
          final bubbleR = (r * (0.7 + rand.nextDouble() * 0.5));
          
          canvas.drawCircle(
            bubblePos,
            bubbleR,
            Paint()
              ..color = AutoBattlePalette.mint.withValues(
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

    // Attacks (VFX)
    for (final a in _snapshot!.attacks) {
      // Ephemeral effects if any
    }

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

    if (player.characterType == 'gunner' ||
        (player.isEnemy && player.weaponCount > 0)) {
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

      canvas.drawLine(
        Offset(r * 0.42, 0),
        Offset(r * 1.62, 0),
        Paint()
          ..color = const Color(0xFF92400E)
          ..strokeWidth = 6 * _arenaScale
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(Offset(r * 0.42, 0), Offset(r * 1.62, 0), ink);
      canvas.restore();
    } else if (player.characterType == 'miner') {
      final weaponCount = math.max(1, player.weaponCount);
      final baseAngle = _weaponAngle(player);
      for (int i = 0; i < weaponCount; i++) {
        final a = baseAngle + math.pi * 2 * i / weaponCount;
        final minePos =
            pos + Offset(math.cos(a) * (r + 10), math.sin(a) * (r + 10));
        canvas.drawCircle(
          minePos,
          8 * _arenaScale,
          Paint()..color = const Color(0xFFEF4444),
        );
        canvas.drawCircle(minePos, 8 * _arenaScale, ink);
      }
    } else if (player.characterType == 'poison') {
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
      for (var i = 0; i < 4; i++) {
        final dist = (r * 1.15) + i * 4 * _arenaScale;
        final side = (i - 1.5) * 3 * _arenaScale;
        final bubble =
            nozzle + Offset(math.cos(rear) * dist, math.sin(rear) * dist);
        canvas.drawCircle(
          bubble + Offset(-math.sin(rear) * side, math.cos(rear) * side),
          2.2 * _arenaScale,
          Paint()..color = AutoBattlePalette.mint.withValues(alpha: 0.7),
        );
      }
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

    // Simplified Gun - Just a sturdy circle barrel
    final gunRect = Rect.fromLTWH(r * 0.7, -r * 0.2, r * 0.8, r * 0.4);
    canvas.drawOval(gunRect, Paint()..color = const Color(0xFF64748B));
    canvas.drawOval(gunRect, ink);

    // Tip detail
    canvas.drawCircle(
      Offset(r * 1.5, 0),
      r * 0.15,
      Paint()..color = AutoBattlePalette.gold,
    );

    canvas.restore();
  }

  Color _colorFromHex(String hex, {required Color fallback}) {
    final normalized = hex.replaceAll('#', '');
    final value = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.tryParse(value, radix: 16) ?? fallback.value);
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
