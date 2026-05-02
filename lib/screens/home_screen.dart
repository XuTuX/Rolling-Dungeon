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
          // Background texture/lines
          Positioned.fill(child: CustomPaint(painter: _SketchLinesPainter())),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final compact = h < 450;

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Title: Taped Sign Style ──
                          _TapedHeader(
                            child: Text(
                              'ROLLING DUNGEON',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AutoBattlePalette.ink,
                                fontSize: compact ? 32 : 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),

                          SizedBox(height: compact ? 20 : 32),

                          // ── Main Content: Sketchbook Page ──
                          Obx(() {
                            final charDef = metaCtrl.currentCharacterDef;
                            final shape = charDef.shape;
                            final info = charDisplayInfoMap[shape] ?? charDisplayInfoMap['circle']!;
                            final unlocked = metaCtrl.unlockedCharacters;
                            final idx = unlocked.indexOf(metaCtrl.selectedCharacter.value);

                            return _SketchbookPage(
                              width: (w * 0.85).clamp(320.0, 500.0),
                              child: Column(
                                children: [
                                  // Character Selection Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (unlocked.length > 1)
                                        _ArrowButton(
                                          icon: Icons.arrow_back_ios_new,
                                          onTap: () {
                                            final newIdx = (idx - 1 + unlocked.length) % unlocked.length;
                                            metaCtrl.selectCharacter(unlocked[newIdx]);
                                          },
                                        )
                                      else
                                        const SizedBox(width: 44),
                                      
                                      Column(
                                        children: [
                                          CharacterBallPreview(
                                            info: info,
                                            size: compact ? 90 : 120,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            charDef.title,
                                            style: const TextStyle(
                                              color: AutoBattlePalette.ink,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (unlocked.length > 1)
                                        _ArrowButton(
                                          icon: Icons.arrow_forward_ios,
                                          onTap: () {
                                            final newIdx = (idx + 1) % unlocked.length;
                                            metaCtrl.selectCharacter(unlocked[newIdx]);
                                          },
                                        )
                                      else
                                        const SizedBox(width: 44),
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    child: Text(
                                      charDef.description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AutoBattlePalette.inkSubtle,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  
                                  // Character indicator
                                  Text(
                                    'NO. ${idx + 1} / ${unlocked.length}',
                                    style: TextStyle(
                                      color: AutoBattlePalette.ink.withValues(alpha: 0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  
                                  // Equipment Grid
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.center,
                                    children: kEquipmentSlotLabels.keys.map((slot) {
                                      final equipment = metaCtrl.equippedDefForSlot(slot);
                                      return _EquipmentSlot(
                                        label: kEquipmentSlotLabels[slot]!,
                                        icon: equipment?.icon ?? '?',
                                        title: equipment?.title ?? 'Empty',
                                        isEquipped: equipment != null,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),

                          SizedBox(height: compact ? 24 : 32),

                          // ── Action Buttons ──
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Row(
                              children: [
                                // START
                                Expanded(
                                  flex: 3,
                                  child: _SketchButton(
                                    color: AutoBattlePalette.primary,
                                    onTap: () {
                                      final charDef = metaCtrl.currentCharacterDef;
                                      runCtrl.startNewRun(
                                        metaCtrl.selectedCharacter.value,
                                        charDef.shape,
                                        unlockedWeapons: metaCtrl.unlockedWeapons,
                                        equippedEquipment: metaCtrl.equippedEquipment,
                                      );
                                      Get.to(() => const AutoBattleGamePage());
                                    },
                                    child: Text(
                                      'DUNGEON ENTER ➔',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // SHOP
                                Expanded(
                                  flex: 2,
                                  child: _SketchButton(
                                    color: AutoBattlePalette.gold,
                                    onTap: () => Get.to(() => const MetaShopScreen()),
                                    child: Text(
                                      '💎 SHOP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: compact ? 20 : 24),

                          // ── Stats Ledger ──
                          Obx(() => _StatsLedger(
                            maxWidth: (w * 0.85).clamp(320.0, 500.0),
                            stats: [
                              _StatItem(Icons.emoji_events, 'BEST', 'STAGE ${metaCtrl.highestStage.value}', AutoBattlePalette.gold),
                              _StatItem(Icons.diamond, 'CRYSTAL', '${metaCtrl.currency.value}', const Color(0xFF7C3AED)),
                              _StatItem(Icons.inventory_2, 'WEAPONS', '${metaCtrl.unlockedWeapons.length}', AutoBattlePalette.secondary),
                            ],
                          )),

                          const SizedBox(height: 24),
                          
                          Text(
                            'V.5.0 // ROLLING DUNGEON PROJECT',
                            style: TextStyle(
                              color: AutoBattlePalette.ink.withValues(alpha: 0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
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
//  Styled Components
// ─────────────────────────────────────────────

class _TapedHeader extends StatelessWidget {
  final Widget child;
  const _TapedHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutoBattlePalette.ink, width: 4),
            boxShadow: const [
              BoxShadow(color: AutoBattlePalette.ink, offset: Offset(8, 8)),
            ],
          ),
          child: child,
        ),
        // "Tape" effects
        Positioned(
          top: -10,
          left: 20,
          child: Transform.rotate(
            angle: -0.1,
            child: const _MaskingTape(width: 50, height: 20),
          ),
        ),
        Positioned(
          bottom: -10,
          right: 20,
          child: Transform.rotate(
            angle: -0.1,
            child: const _MaskingTape(width: 60, height: 22),
          ),
        ),
      ],
    );
  }
}

class _SketchbookPage extends StatelessWidget {
  final double width;
  final Widget child;
  const _SketchbookPage({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(6, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _MaskingTape extends StatelessWidget {
  final double width;
  final double height;
  const _MaskingTape({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A).withValues(alpha: 0.8),
        border: Border.all(color: AutoBattlePalette.ink.withValues(alpha: 0.1), width: 1),
      ),
    );
  }
}

class _EquipmentSlot extends StatelessWidget {
  final String label;
  final String icon;
  final String title;
  final bool isEquipped;

  const _EquipmentSlot({
    required this.label,
    required this.icon,
    required this.title,
    required this.isEquipped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isEquipped ? const Color(0xFFF0F9FF) : Colors.transparent,
        border: Border.all(
          color: isEquipped ? AutoBattlePalette.secondary : AutoBattlePalette.ink.withValues(alpha: 0.2),
          width: 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AutoBattlePalette.ink.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isEquipped ? AutoBattlePalette.ink : AutoBattlePalette.ink.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchButton extends StatefulWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  const _SketchButton({required this.color, required this.child, required this.onTap});

  @override
  State<_SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<_SketchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: 64,
        transform: _pressed ? Matrix4.translationValues(3, 3, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: AutoBattlePalette.ink, width: 4),
          boxShadow: _pressed 
            ? null 
            : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(6, 6))],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
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

class _StatsLedger extends StatelessWidget {
  final double maxWidth;
  final List<_StatItem> stats;
  const _StatsLedger({required this.maxWidth, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stats.map((s) {
          final isLast = stats.last == s;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 18),
                      const SizedBox(height: 4),
                      Text(s.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AutoBattlePalette.text3)),
                      Text(s.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AutoBattlePalette.ink)),
                    ],
                  ),
                ),
                if (!isLast) Container(width: 2, height: 30, color: AutoBattlePalette.ink.withValues(alpha: 0.1)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _StatItem(this.icon, this.label, this.value, this.color);
}

class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 1.5;

    // Horizontal notebook lines
    for (var y = 60.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Vertical "margin" line
    final marginPaint = Paint()
      ..color = AutoBattlePalette.primary.withValues(alpha: 0.1)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

