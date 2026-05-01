import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';

class CharDisplayInfo {
  final String name;
  final String desc;
  final Color bodyColor;
  final Color accentColor;
  final IconData icon;
  final String emoji;

  const CharDisplayInfo({
    required this.name,
    required this.desc,
    required this.bodyColor,
    required this.accentColor,
    required this.icon,
    required this.emoji,
  });
}

const Map<String, CharDisplayInfo> charDisplayInfoMap = {
  'gunner': CharDisplayInfo(
    name: '거너',
    desc: '정밀한 사격으로 적을 제압',
    bodyColor: Color(0xFF3B82F6),
    accentColor: Color(0xFF60A5FA),
    icon: Icons.gps_fixed,
    emoji: '🔫',
  ),
  'minigun': CharDisplayInfo(
    name: '미니거너',
    desc: '압도적 연사의 탄막 전사',
    bodyColor: Color(0xFF475569),
    accentColor: Color(0xFF94A3B8),
    icon: Icons.bolt,
    emoji: '🔫',
  ),
  'long_gun': CharDisplayInfo(
    name: '스나이퍼',
    desc: '한 발의 무게가 다른 저격수',
    bodyColor: Color(0xFFDC2626),
    accentColor: Color(0xFFF87171),
    icon: Icons.center_focus_strong,
    emoji: '🎯',
  ),
  'poison': CharDisplayInfo(
    name: '독술사',
    desc: '치명적인 독안개의 지배자',
    bodyColor: Color(0xFF16A34A),
    accentColor: Color(0xFF4ADE80),
    icon: Icons.bubble_chart,
    emoji: '☣️',
  ),
  'blade': CharDisplayInfo(
    name: '검사',
    desc: '회전하는 칼날의 달인',
    bodyColor: Color(0xFF7C3AED),
    accentColor: Color(0xFFA78BFA),
    icon: Icons.autorenew,
    emoji: '⚔️',
  ),
  'miner': CharDisplayInfo(
    name: '폭파병',
    desc: '전장을 지뢰밭으로 만드는 전략가',
    bodyColor: Color(0xFFEF4444),
    accentColor: Color(0xFFFCA5A5),
    icon: Icons.dangerous,
    emoji: '💣',
  ),
  'footsteps': CharDisplayInfo(
    name: '불꽃술사',
    desc: '지나간 곳을 불태우는 방랑자',
    bodyColor: Color(0xFFF97316),
    accentColor: Color(0xFFFDBA74),
    icon: Icons.whatshot,
    emoji: '🔥',
  ),
  'burst': CharDisplayInfo(
    name: '포격수',
    desc: '사방으로 퍼지는 탄환의 폭풍',
    bodyColor: Color(0xFFEAB308),
    accentColor: Color(0xFFFDE047),
    icon: Icons.flare,
    emoji: '💥',
  ),
  'heavy_blade': CharDisplayInfo(
    name: '대검사',
    desc: '거대한 검으로 모든 것을 베어버린다',
    bodyColor: Color(0xFF0F172A),
    accentColor: Color(0xFF64748B),
    icon: Icons.gavel,
    emoji: '🗡️',
  ),
  'ricochet': CharDisplayInfo(
    name: '도탄사',
    desc: '벽을 이용한 기묘한 사격의 명수',
    bodyColor: Color(0xFF0284C7),
    accentColor: Color(0xFF38BDF8),
    icon: Icons.keyboard_return,
    emoji: '✨',
  ),
  'aura': CharDisplayInfo(
    name: '수호자',
    desc: '수호의 오라로 적을 제압',
    bodyColor: Color(0xFF9333EA),
    accentColor: Color(0xFFC084FC),
    icon: Icons.shield,
    emoji: '🌀',
  ),
};

class CharacterBallPreview extends StatefulWidget {
  final CharDisplayInfo info;
  final double size;

  const CharacterBallPreview({super.key, required this.info, required this.size});

  @override
  State<CharacterBallPreview> createState() => _CharacterBallPreviewState();
}

class _CharacterBallPreviewState extends State<CharacterBallPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sine wave for smooth floating effect (-4.0 to +4.0)
        final floatOffset = math.sin(_controller.value * math.pi) * 4.0;

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CharBallPainter(info: widget.info, floatOffset: floatOffset),
        );
      },
    );
  }
}

class _CharBallPainter extends CustomPainter {
  final CharDisplayInfo info;
  final double floatOffset;

  _CharBallPainter({required this.info, this.floatOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + floatOffset;
    final r = size.width * 0.42;

    // Shadow (offset)
    canvas.drawCircle(
      Offset(cx + 4, cy + 4),
      r,
      Paint()..color = AutoBattlePalette.ink.withValues(alpha: 0.2),
    );

    // Body fill
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = info.bodyColor,
    );

    // Inner highlight
    canvas.drawCircle(
      Offset(cx - r * 0.2, cy - r * 0.2),
      r * 0.35,
      Paint()..color = info.accentColor.withValues(alpha: 0.4),
    );

    // Ink outline
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AutoBattlePalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Eyes (two small white circles)
    final eyeY = cy - r * 0.12;
    final eyeSpacing = r * 0.28;
    final eyeR = r * 0.14;
    for (final dx in [-eyeSpacing, eyeSpacing]) {
      canvas.drawCircle(
        Offset(cx + dx, eyeY),
        eyeR,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx + dx + 1.5, eyeY + 1),
        eyeR * 0.55,
        Paint()..color = AutoBattlePalette.ink,
      );
      canvas.drawCircle(
        Offset(cx + dx, eyeY),
        eyeR,
        Paint()
          ..color = AutoBattlePalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Mouth (small curved line)
    final mouthPath = Path();
    mouthPath.moveTo(cx - r * 0.15, cy + r * 0.22);
    mouthPath.quadraticBezierTo(
        cx, cy + r * 0.38, cx + r * 0.15, cy + r * 0.22);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = AutoBattlePalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Weapon icon (bottom right)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cx + r * 0.6, cy + r * 0.55),
      r * 0.3,
      Paint()..color = AutoBattlePalette.ink,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.6, cy + r * 0.55),
      r * 0.3,
      iconPaint..color = info.accentColor,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.6, cy + r * 0.55),
      r * 0.3,
      Paint()
        ..color = AutoBattlePalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CharBallPainter old) =>
      old.info.name != info.name || old.floatOffset != floatOffset;
}
