import 'dart:math' as math;
import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';
import 'package:circle_war/screens/meta_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                              final info = charDisplayInfoMap[equipped] ??
                                  charDisplayInfoMap['gunner']!;
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
                                                  final newIdx = (idx -
                                                          1 +
                                                          unlocked.length) %
                                                      unlocked.length;
                                                  metaCtrl.equipWeapon(
                                                      unlocked[newIdx]);
                                                },
                                              ),
                                            const SizedBox(width: 10),

                                            // Character ball
                                            CharacterBallPreview(
                                              info: info,
                                              size: compact ? 80 : 100,
                                            ),

                                            const SizedBox(width: 10),
                                            // Right arrow
                                            if (unlocked.length > 1)
                                              _ArrowButton(
                                                icon: Icons.chevron_right,
                                                onTap: () {
                                                  final newIdx = (idx + 1) %
                                                      unlocked.length;
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
                                          '시작 무기 ${idx + 1} / ${unlocked.length}',
                                          style: const TextStyle(
                                            color: AutoBattlePalette.text3,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: kEquipmentSlotLabels.keys
                                              .map((slot) {
                                            final equipment = metaCtrl
                                                .equippedDefForSlot(slot);
                                            return _LoadoutSlotChip(
                                              label:
                                                  kEquipmentSlotLabels[slot]!,
                                              icon: equipment?.icon ?? '＋',
                                              title:
                                                  equipment?.title ?? '비어 있음',
                                              equipped: equipment != null,
                                            );
                                          }).toList(),
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
                                          metaCtrl.equippedWeapon.value,
                                          unlockedWeapons:
                                              metaCtrl.unlockedWeapons,
                                          equippedEquipment:
                                              metaCtrl.equippedEquipment,
                                        );
                                        Get.to(
                                            () => const AutoBattleGamePage());
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
                                      onTap: () =>
                                          Get.to(() => const MetaShopScreen()),
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

class _LoadoutSlotChip extends StatelessWidget {
  final String label;
  final String icon;
  final String title;
  final bool equipped;

  const _LoadoutSlotChip({
    required this.label,
    required this.icon,
    required this.title,
    required this.equipped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: equipped ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        border: Border.all(
          color:
              equipped ? AutoBattlePalette.secondary : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AutoBattlePalette.text3,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
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
