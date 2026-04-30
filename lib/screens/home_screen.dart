import 'dart:math' as math;
import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:circle_war/screens/meta_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Character display info per weapon ──
  static const _charInfo = <String, _CharDisplayInfo>{
    'gunner': _CharDisplayInfo(
      name: '거너',
      desc: '정밀한 사격으로 적을 제압',
      bodyColor: Color(0xFF3B82F6),
      accentColor: Color(0xFF60A5FA),
      icon: Icons.gps_fixed,
      emoji: '🔫',
    ),
    'minigun': _CharDisplayInfo(
      name: '미니거너',
      desc: '압도적 연사의 탄막 전사',
      bodyColor: Color(0xFF475569),
      accentColor: Color(0xFF94A3B8),
      icon: Icons.bolt,
      emoji: '🔫',
    ),
    'long_gun': _CharDisplayInfo(
      name: '스나이퍼',
      desc: '한 발의 무게가 다른 저격수',
      bodyColor: Color(0xFFDC2626),
      accentColor: Color(0xFFF87171),
      icon: Icons.center_focus_strong,
      emoji: '🎯',
    ),
    'poison': _CharDisplayInfo(
      name: '독술사',
      desc: '치명적인 독안개의 지배자',
      bodyColor: Color(0xFF16A34A),
      accentColor: Color(0xFF4ADE80),
      icon: Icons.bubble_chart,
      emoji: '☣️',
    ),
    'blade': _CharDisplayInfo(
      name: '검사',
      desc: '회전하는 칼날의 달인',
      bodyColor: Color(0xFF7C3AED),
      accentColor: Color(0xFFA78BFA),
      icon: Icons.autorenew,
      emoji: '⚔️',
    ),
    'miner': _CharDisplayInfo(
      name: '폭파병',
      desc: '전장을 지뢰밭으로 만드는 전략가',
      bodyColor: Color(0xFFEF4444),
      accentColor: Color(0xFFFCA5A5),
      icon: Icons.dangerous,
      emoji: '💣',
    ),
    'footsteps': _CharDisplayInfo(
      name: '불꽃술사',
      desc: '지나간 곳을 불태우는 방랑자',
      bodyColor: Color(0xFFF97316),
      accentColor: Color(0xFFFDBA74),
      icon: Icons.whatshot,
      emoji: '🔥',
    ),
    'burst': _CharDisplayInfo(
      name: '포격수',
      desc: '사방으로 퍼지는 탄환의 폭풍',
      bodyColor: Color(0xFFEAB308),
      accentColor: Color(0xFFFDE047),
      icon: Icons.flare,
      emoji: '💥',
    ),
    'heavy_blade': _CharDisplayInfo(
      name: '대검사',
      desc: '거대한 검으로 모든 것을 베어버린다',
      bodyColor: Color(0xFF0F172A),
      accentColor: Color(0xFF64748B),
      icon: Icons.gavel,
      emoji: '🗡️',
    ),
    'ricochet': _CharDisplayInfo(
      name: '도탄사',
      desc: '벽을 이용한 기묘한 사격의 명수',
      bodyColor: Color(0xFF0284C7),
      accentColor: Color(0xFF38BDF8),
      icon: Icons.keyboard_return,
      emoji: '✨',
    ),
    'aura': _CharDisplayInfo(
      name: '수호자',
      desc: '수호의 오라로 적을 제압',
      bodyColor: Color(0xFF9333EA),
      accentColor: Color(0xFFC084FC),
      icon: Icons.shield,
      emoji: '🌀',
    ),
  };

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are initialized
    if (!Get.isRegistered<MetaProgressController>()) {
      Get.put(MetaProgressController(), permanent: true);
    }
    if (!Get.isRegistered<GameProgressController>()) {
      Get.put(GameProgressController(), permanent: true);
    }
    final metaCtrl = Get.find<MetaProgressController>();
    final runCtrl = Get.find<GameProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SketchLinesPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final compact = h < 400;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Title ──
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: (w * 0.05).clamp(18.0, 36.0),
                                vertical: compact ? 6 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: AutoBattlePalette.ink, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                      color: AutoBattlePalette.ink,
                                      offset: Offset(6, 6)),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'ROLLING DUNGEON',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AutoBattlePalette.ink,
                                    fontSize: compact ? 28 : 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: compact ? 14 : 22),

                            // ── Character Preview with weapon switcher ──
                            Obx(() {
                              final equipped = metaCtrl.equippedWeapon.value;
                              final info = _charInfo[equipped] ??
                                  _charInfo['gunner']!;
                              final unlocked = metaCtrl.unlockedWeapons;
                              final idx = unlocked.indexOf(equipped);

                              return Column(
                                children: [
                                  // Character ball + info
                                  Container(
                                    width: (w * 0.75).clamp(280.0, 400.0),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: AutoBattlePalette.ink,
                                          width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AutoBattlePalette.ink,
                                            offset: Offset(5, 5)),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Character ball visual
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Left arrow
                                            if (unlocked.length > 1)
                                              _ArrowButton(
                                                icon: Icons.chevron_left,
                                                onTap: () {
                                                  final newIdx =
                                                      (idx - 1 + unlocked.length) %
                                                          unlocked.length;
                                                  metaCtrl.equipWeapon(
                                                      unlocked[newIdx]);
                                                },
                                              ),
                                            const SizedBox(width: 10),

                                            // Character ball
                                            _CharacterBallPreview(
                                              info: info,
                                              size: compact ? 80 : 100,
                                            ),

                                            const SizedBox(width: 10),
                                            // Right arrow
                                            if (unlocked.length > 1)
                                              _ArrowButton(
                                                icon: Icons.chevron_right,
                                                onTap: () {
                                                  final newIdx =
                                                      (idx + 1) % unlocked.length;
                                                  metaCtrl.equipWeapon(
                                                      unlocked[newIdx]);
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Name
                                        Text(
                                          info.name,
                                          style: const TextStyle(
                                            color: AutoBattlePalette.ink,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          info.desc,
                                          style: const TextStyle(
                                            color: AutoBattlePalette.inkSubtle,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Weapon count indicator
                                        Text(
                                          '${idx + 1} / ${unlocked.length} 무기 보유',
                                          style: const TextStyle(
                                            color: AutoBattlePalette.text3,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),

                            SizedBox(height: compact ? 14 : 20),

                            // ── Buttons Row ──
                            SizedBox(
                              width: (w * 0.75).clamp(280.0, 400.0),
                              child: Row(
                                children: [
                                  // START button
                                  Expanded(
                                    flex: 3,
                                    child: GestureDetector(
                                      onTap: () {
                                        runCtrl.startNewRun(
                                            metaCtrl.equippedWeapon.value);
                                        Get.to(() =>
                                            const AutoBattleGamePage());
                                      },
                                      child: Container(
                                        height: compact ? 52 : 60,
                                        decoration: BoxDecoration(
                                          color: AutoBattlePalette.primary,
                                          border: Border.all(
                                              color: AutoBattlePalette.ink,
                                              width: 4),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: AutoBattlePalette.ink,
                                                offset: Offset(5, 5)),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'START ➔',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // SHOP button
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: () => Get.to(
                                          () => const MetaShopScreen()),
                                      child: Container(
                                        height: compact ? 52 : 60,
                                        decoration: BoxDecoration(
                                          color: AutoBattlePalette.gold,
                                          border: Border.all(
                                              color: AutoBattlePalette.ink,
                                              width: 4),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: AutoBattlePalette.ink,
                                                offset: Offset(5, 5)),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '💎 SHOP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: compact ? 10 : 16),

                            // ── Stats bar ──
                            Obx(() => Container(
                                  width: (w * 0.75).clamp(280.0, 400.0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: AutoBattlePalette.ink,
                                        width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AutoBattlePalette.ink,
                                          offset: Offset(3, 3)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _MiniStat(
                                        icon: Icons.emoji_events,
                                        label: '최고 기록',
                                        value:
                                            'STAGE ${metaCtrl.highestStage.value}',
                                        color: AutoBattlePalette.gold,
                                      ),
                                      Container(
                                          width: 2,
                                          height: 28,
                                          color: AutoBattlePalette.ink
                                              .withValues(alpha: 0.15)),
                                      _MiniStat(
                                        icon: Icons.diamond,
                                        label: '크리스탈',
                                        value: '${metaCtrl.currency.value}',
                                        color: const Color(0xFF7C3AED),
                                      ),
                                      Container(
                                          width: 2,
                                          height: 28,
                                          color: AutoBattlePalette.ink
                                              .withValues(alpha: 0.15)),
                                      _MiniStat(
                                        icon: Icons.inventory_2,
                                        label: '무기',
                                        value:
                                            '${metaCtrl.unlockedWeapons.length}',
                                        color: AutoBattlePalette.secondary,
                                      ),
                                    ],
                                  ),
                                )),

                            const SizedBox(height: 12),
                            const Text(
                              'VERSION 5.0 // 굴러굴러 던전',
                              style: TextStyle(
                                color: AutoBattlePalette.text3,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Character Ball Preview (sketch style)
// ─────────────────────────────────────────────
class _CharacterBallPreview extends StatelessWidget {
  final _CharDisplayInfo info;
  final double size;

  const _CharacterBallPreview({required this.info, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CharBallPainter(info: info),
    );
  }
}

class _CharBallPainter extends CustomPainter {
  final _CharDisplayInfo info;
  _CharBallPainter({required this.info});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
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
      // White part
      canvas.drawCircle(
        Offset(cx + dx, eyeY),
        eyeR,
        Paint()..color = Colors.white,
      );
      // Pupil
      canvas.drawCircle(
        Offset(cx + dx + 1.5, eyeY + 1),
        eyeR * 0.55,
        Paint()..color = AutoBattlePalette.ink,
      );
      // Eye outline
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
      old.info.name != info.name;
}

// ─────────────────────────────────────────────
//  Arrow button for weapon switching
// ─────────────────────────────────────────────
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: AutoBattlePalette.ink, size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Mini stat display
// ─────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AutoBattlePalette.text3,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AutoBattlePalette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Character display info
// ─────────────────────────────────────────────
class _CharDisplayInfo {
  final String name;
  final String desc;
  final Color bodyColor;
  final Color accentColor;
  final IconData icon;
  final String emoji;

  const _CharDisplayInfo({
    required this.name,
    required this.desc,
    required this.bodyColor,
    required this.accentColor,
    required this.icon,
    required this.emoji,
  });
}

// ─────────────────────────────────────────────
//  Sketch Background
// ─────────────────────────────────────────────
class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 2;

    final random = math.Random(42);
    for (var i = 0; i < 20; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (random.nextDouble() - 0.5) * 40),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
