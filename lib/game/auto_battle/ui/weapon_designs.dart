import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../auto_battle_palette.dart';
import '../engine/weapon_visual_config.dart';

/// 🎨 Sketch Drawing Utilities
/// Reusable functions for the hand-drawn look.
class SketchUtils {
  static void drawRoughPath(Canvas canvas, Path path, Paint paint,
      {double? jitter}) {
    final metrics = path.computeMetrics();
    final roughPath = Path();
    final rand = math.Random(42);
    final j = jitter ?? WeaponVisualConfig.globalJitter;

    for (final metric in metrics) {
      const step = 4.0;
      for (var d = 0.0; d < metric.length; d += step) {
        final pos = metric.getTangentForOffset(d)!.position;
        final offset = Offset(
          (rand.nextDouble() - 0.5) * j,
          (rand.nextDouble() - 0.5) * j,
        );
        if (d == 0) {
          roughPath.moveTo(pos.dx + offset.dx, pos.dy + offset.dy);
        } else {
          roughPath.lineTo(pos.dx + offset.dx, pos.dy + offset.dy);
        }
      }
    }
    if (path.contains(const Offset(0, 0))) roughPath.close();
    canvas.drawPath(roughPath, paint);
  }

  static void drawHatching(
      Canvas canvas, Rect rect, double angle, double? spacing, Paint paint) {
    canvas.save();
    canvas.clipRect(rect);
    canvas.rotate(angle);
    final s = spacing ?? WeaponVisualConfig.hatchingSpacing;
    final diagonal =
        math.sqrt(rect.width * rect.width + rect.height * rect.height);
    for (var i = -diagonal; i < diagonal; i += s) {
      canvas.drawLine(
          Offset(i, -diagonal), Offset(i + diagonal * 0.5, diagonal), paint);
    }
    canvas.restore();
  }

  static void renderMuzzleFlash(
      Canvas canvas, Offset muzzle, double scale, double thrust) {
    final flashPaint = Paint()..color = AutoBattlePalette.gold;
    final size = 16 * scale * thrust;
    final path = Path();
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final r = i % 3 == 0 ? size : size * 0.4;
      final x = muzzle.dx + math.cos(angle) * r;
      final y = muzzle.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, flashPaint);
    drawRoughPath(
        canvas,
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * scale,
        jitter: 1.2);
  }

  static void renderSmoke(
      Canvas canvas, Offset pos, double scale, double pulse) {
    final t = (pulse * 5) % 1.0;
    final ink = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    for (var i = 0; i < 3; i++) {
      final r = (5 + i * 8) * scale * t;
      canvas.drawCircle(
          pos + Offset(i * 10 * scale * t, -i * 5 * scale * t), r, ink);
    }
  }
}

/// ⚔️ Weapon Blueprint Designs
/// Modify the PATHS and SHAPES here to change the weapon forms.
class WeaponDesigns {
  // ── 🔫 GUN (Revolver) ──
  static void renderGun(Canvas canvas, double scale, double thrust,
      double ballRadius, double pulse) {
    final inkPaint = _getInkPaint(scale);
    final recoil = thrust * WeaponVisualConfig.gunRecoilMult * scale;
    final tilt = thrust * WeaponVisualConfig.gunTiltMult;

    canvas.save();
    canvas.translate(-recoil, 0);
    canvas.rotate(-tilt);

    // [SHAPE] Main Frame
    final framePath = Path()
      ..moveTo(ballRadius * 0.55, -WeaponVisualConfig.gunFrameScaleY * scale)
      ..lineTo(ballRadius * 1.15, -WeaponVisualConfig.gunFrameScaleY * scale)
      ..lineTo(ballRadius * 1.25, -4.5 * scale)
      ..lineTo(ballRadius * WeaponVisualConfig.gunFrameScaleX, -4.5 * scale)
      ..lineTo(ballRadius * WeaponVisualConfig.gunFrameScaleX, 4.5 * scale)
      ..lineTo(ballRadius * 0.55, 4.5 * scale)
      ..close();
    canvas.drawPath(
        framePath, Paint()..color = WeaponVisualConfig.gunFrameColor);
    SketchUtils.drawRoughPath(canvas, framePath, inkPaint);

    // [DETAIL] Shading
    SketchUtils.drawHatching(
        canvas,
        Rect.fromLTWH(ballRadius * 0.6, -8 * scale, 20 * scale, 12 * scale),
        0.5,
        null,
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 1);

    // [SHAPE] Cylinder
    final cylinderRect =
        Rect.fromLTWH(ballRadius * 0.7, -8 * scale, 14 * scale, 16 * scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(cylinderRect, Radius.circular(4 * scale)),
        Paint()..color = WeaponVisualConfig.gunCylinderColor);
    SketchUtils.drawRoughPath(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              cylinderRect, Radius.circular(4 * scale))),
        inkPaint);

    // [SHAPE] Grip
    final gripPath = Path()
      ..moveTo(ballRadius * 0.6, 4 * scale)
      ..quadraticBezierTo(ballRadius * 0.9, 5 * scale, ballRadius * 0.8,
          WeaponVisualConfig.gunGripLength * scale)
      ..lineTo(ballRadius * 0.4, 24 * scale)
      ..quadraticBezierTo(
          ballRadius * 0.45, 10 * scale, ballRadius * 0.55, 4 * scale);
    canvas.drawPath(gripPath, Paint()..color = WeaponVisualConfig.gunGripColor);
    SketchUtils.drawRoughPath(canvas, gripPath, inkPaint);

    if (thrust > 0.7) {
      SketchUtils.renderMuzzleFlash(
          canvas,
          Offset(ballRadius * WeaponVisualConfig.gunFrameScaleX + 2 * scale, 0),
          scale,
          thrust);
      SketchUtils.renderSmoke(
          canvas, Offset(ballRadius * 2.5, -5 * scale), scale, pulse);
    }
    canvas.restore();
  }

  // ── 🔱 SPEAR ──
  static void renderSpear(Canvas canvas, double scale, double thrust,
      double ballRadius, double pulse, double motionEnergy) {
    final inkPaint = _getInkPaint(scale);
    final thrustExt = WeaponVisualConfig.spearThrustExt * thrust * scale;
    final shaftStart = ballRadius * 0.2;
    final shaftEnd =
        ballRadius * WeaponVisualConfig.spearShaftLength + thrustExt;

    // [SHAPE] Shaft
    final shaftPath = Path()
      ..moveTo(shaftStart, 0)
      ..lineTo(shaftEnd, 0);
    canvas.drawLine(
        Offset(shaftStart, 0),
        Offset(shaftEnd, 0),
        Paint()
          ..color = WeaponVisualConfig.spearShaftColor
          ..strokeWidth = 6 * scale);
    SketchUtils.drawRoughPath(
        canvas, shaftPath, inkPaint..strokeWidth = 2.8 * scale);

    // [SHAPE] Grip Wrap
    final gripRect =
        Rect.fromLTWH(ballRadius * 0.4, -4 * scale, 12 * scale, 8 * scale);
    canvas.drawRect(
        gripRect, Paint()..color = WeaponVisualConfig.spearGripColor);
    SketchUtils.drawRoughPath(
        canvas, Path()..addRect(gripRect), inkPaint..strokeWidth = 2 * scale);

    // [SHAPE] Spear Head
    final headStart = shaftEnd;
    final headPath = Path()
      ..moveTo(headStart, -9 * scale)
      ..quadraticBezierTo(headStart + 12 * scale, -8 * scale,
          headStart + WeaponVisualConfig.spearHeadSize * scale, 0)
      ..quadraticBezierTo(
          headStart + 12 * scale, 8 * scale, headStart, 9 * scale)
      ..lineTo(headStart - 4 * scale, 0)
      ..close();
    canvas.drawPath(
        headPath, Paint()..color = WeaponVisualConfig.spearHeadColor);
    SketchUtils.drawRoughPath(
        canvas, headPath, inkPaint..strokeWidth = 3.5 * scale,
        jitter: 1.2);

    // [ANIM] Tassel
    final tasselWave = math.sin(pulse * 12 + motionEnergy * 8);
    for (var i = 0; i < WeaponVisualConfig.spearTasselStrands; i++) {
      final off = i * 2.0 - (WeaponVisualConfig.spearTasselStrands * 1.0);
      final tasselPath = Path()
        ..moveTo(headStart - 2 * scale, off * scale)
        ..quadraticBezierTo(
          headStart - 15 * scale,
          (off +
                  WeaponVisualConfig.spearTasselWave * 0.8 * tasselWave +
                  i * 2) *
              scale,
          headStart - 35 * scale,
          (off +
                  WeaponVisualConfig.spearTasselWave * 1.2 * tasselWave +
                  i * 5) *
              scale,
        );
      canvas.drawPath(
          tasselPath,
          Paint()
            ..color = AutoBattlePalette.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * scale
            ..strokeCap = StrokeCap.round);
    }
  }

  // ── 🏹 CROSSBOW ──
  static void renderCrossbow(
      Canvas canvas, double scale, double thrust, double ballRadius) {
    final inkPaint = _getInkPaint(scale);
    final stringPull = thrust * WeaponVisualConfig.crossbowStringPull * scale;
    final basePos = ballRadius * 0.7;

    // [SHAPE] Stock
    final stockPath = Path()
      ..moveTo(basePos, -6 * scale)
      ..lineTo(
          basePos + WeaponVisualConfig.crossbowStockLength * scale, -5 * scale)
      ..lineTo(
          basePos + (WeaponVisualConfig.crossbowStockLength + 2) * scale, 0)
      ..lineTo(
          basePos + WeaponVisualConfig.crossbowStockLength * scale, 5 * scale)
      ..lineTo(basePos, 6 * scale)
      ..close();
    canvas.drawPath(
        stockPath, Paint()..color = WeaponVisualConfig.crossbowBodyColor);
    SketchUtils.drawRoughPath(canvas, stockPath, inkPaint);

    // [SHAPE] Flexible Limbs
    final limbsPath = Path()
      ..moveTo(
          basePos + 18 * scale, -WeaponVisualConfig.crossbowLimbSpan * scale)
      ..quadraticBezierTo(basePos + 8 * scale + stringPull * 0.3, 0,
          basePos + 18 * scale, WeaponVisualConfig.crossbowLimbSpan * scale);
    canvas.drawPath(
        limbsPath,
        Paint()
          ..color = WeaponVisualConfig.crossbowLimbColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * scale
          ..strokeCap = StrokeCap.round);
    SketchUtils.drawRoughPath(
        canvas, limbsPath, inkPaint..strokeWidth = 2.5 * scale);

    // [SHAPE] Bowstring
    final stringPath = Path()
      ..moveTo(basePos + 18 * scale,
          -(WeaponVisualConfig.crossbowLimbSpan - 1) * scale)
      ..lineTo(basePos + 6 * scale + stringPull, 0)
      ..lineTo(basePos + 18 * scale,
          (WeaponVisualConfig.crossbowLimbSpan - 1) * scale);
    canvas.drawPath(
        stringPath,
        Paint()
          ..color = const Color(0xFFF1F5F9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * scale);

    // [SHAPE] Bolt
    if (thrust < 0.25) {
      final boltPath = Path()
        ..moveTo(basePos + 4 * scale, 0)
        ..lineTo(basePos + WeaponVisualConfig.crossbowBoltLength * scale, 0);
      canvas.drawPath(
          boltPath,
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * scale
            ..strokeCap = StrokeCap.round);
      final tip = Path()
        ..moveTo(basePos + WeaponVisualConfig.crossbowBoltLength * scale,
            -4.5 * scale)
        ..lineTo(
            basePos + (WeaponVisualConfig.crossbowBoltLength + 10) * scale, 0)
        ..lineTo(basePos + WeaponVisualConfig.crossbowBoltLength * scale,
            4.5 * scale)
        ..close();
      canvas.drawPath(tip, Paint()..color = const Color(0xFF0F172A));
      SketchUtils.drawRoughPath(canvas, tip, inkPaint..strokeWidth = 2 * scale);
    }
  }

  // ── 🧨 TNT ──
  static void renderTNT(Canvas canvas, double scale, double ballRadius,
      double pulse, double motionEnergy) {
    final inkPaint = _getInkPaint(scale);
    final center = Offset(ballRadius * 1.2, -4 * scale);
    final shake = math.sin(pulse * 30) *
        WeaponVisualConfig.tntShakeMult *
        motionEnergy *
        scale;

    canvas.save();
    canvas.translate(shake, shake);

    // [SHAPE] Sticks
    for (var i = -1; i <= 1; i++) {
      final x = center.dx + i * 7 * scale;
      final y = center.dy + (i.abs() * 3 * scale);
      final stickPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(x, y),
                width: WeaponVisualConfig.tntStickWidth * scale,
                height: WeaponVisualConfig.tntStickHeight * scale),
            Radius.circular(2 * scale)));
      canvas.drawPath(stickPath, Paint()..color = WeaponVisualConfig.tntColor);
      SketchUtils.drawRoughPath(canvas, stickPath, inkPaint);
    }

    // [SHAPE] Straps
    for (var yOff in [-6, 6]) {
      final strap = Rect.fromLTWH(center.dx - 12 * scale,
          center.dy + yOff * scale - 2 * scale, 24 * scale, 4 * scale);
      canvas.drawRect(strap, Paint()..color = WeaponVisualConfig.tntStrapColor);
    }

    // [SHAPE] Fuse & Spark
    final fusePath = Path()
      ..moveTo(center.dx, center.dy - 14 * scale)
      ..quadraticBezierTo(
          center.dx + 12 * scale,
          center.dy - 24 * scale,
          center.dx + 6 * scale,
          center.dy - WeaponVisualConfig.tntFuseLength * 2.5 * scale);
    SketchUtils.drawRoughPath(
        canvas, fusePath, inkPaint..strokeWidth = 2.2 * scale);
    _renderSpark(
        canvas,
        Offset(center.dx + 6 * scale,
            center.dy - WeaponVisualConfig.tntFuseLength * 2.5 * scale),
        scale,
        pulse);

    canvas.restore();
  }

  static void _renderSpark(
      Canvas canvas, Offset pos, double scale, double pulse) {
    final t = (pulse * 20) % 1.0;
    final sparkPaint = Paint()
      ..color = AutoBattlePalette.gold
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi * 2 / 8 + pulse * 15;
      final dist =
          (WeaponVisualConfig.tntSparkSize + math.sin(t * 15) * 8) * scale;
      canvas.drawLine(pos, pos + Offset(math.cos(a) * dist, math.sin(a) * dist),
          sparkPaint);
    }
    canvas.drawCircle(pos, 4 * scale, Paint()..color = Colors.white);
  }

  static Paint _getInkPaint(double scale) {
    return Paint()
      ..color = WeaponVisualConfig.inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = WeaponVisualConfig.inkStrokeWidth * scale
      ..strokeCap = StrokeCap.round;
  }
}
