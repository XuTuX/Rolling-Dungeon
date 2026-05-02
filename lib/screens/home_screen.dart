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
          Positioned.fill(child: CustomPaint(painter: _SketchLinesPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                // UI adapts based on vertical space
                final isCompact = h < 600;
                final isTiny = h < 480;

                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isTiny ? 4 : (isCompact ? 8 : 32),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        _TapedHeader(
                          isCompact: isCompact,
                          child: Text(
                            'ROLLING DUNGEON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AutoBattlePalette.ink,
                              fontSize: isCompact ? 24 : 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 12 : 32),

                        // Character Preview & Equip (Flexible to prevent overflow)
                        Flexible(
                          child: Obx(() {
                            return _SketchbookPage(
                              width: (w * 0.95).clamp(320.0, 600.0),
                              isCompact: isCompact,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SectionTitle(title: 'SELECT CHARACTER', isCompact: isCompact),
                                  SizedBox(height: isCompact ? 4 : 12),
                                  
                                  // Character Selection Row (All 4 in a row)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: kAllCharacters.map((char) {
                                      final isUnlocked = metaCtrl.unlockedCharacters.contains(char.id);
                                      final isSelected = metaCtrl.selectedCharacter.value == char.id;
                                      final info = charDisplayInfoMap[char.shape] ?? charDisplayInfoMap['circle']!;
                                      
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: GestureDetector(
                                            onTap: isUnlocked ? () => metaCtrl.selectCharacter(char.id) : null,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: EdgeInsets.all(isCompact ? 4 : 8),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AutoBattlePalette.surfaceLight : Colors.white,
                                                border: Border.all(
                                                  color: isSelected ? AutoBattlePalette.primary : AutoBattlePalette.ink.withValues(alpha: 0.1),
                                                  width: isSelected ? 3 : 2,
                                                ),
                                                boxShadow: isSelected ? [
                                                  const BoxShadow(color: AutoBattlePalette.primary, offset: Offset(3, 3)),
                                                ] : null,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      CharacterBallPreview(
                                                        info: info,
                                                        size: isCompact ? 38 : 64,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        char.title,
                                                        style: TextStyle(
                                                          color: isSelected ? AutoBattlePalette.ink : AutoBattlePalette.ink.withValues(alpha: 0.4),
                                                          fontSize: isCompact ? 8 : 12,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (!isUnlocked)
                                                    Positioned.fill(
                                                      child: Container(
                                                        color: Colors.white.withValues(alpha: 0.6),
                                                        child: Center(
                                                          child: Icon(Icons.lock, size: isCompact ? 14 : 18, color: AutoBattlePalette.inkSubtle),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  SizedBox(height: isCompact ? 6 : 16),
                                  _SectionTitle(title: 'EQUIPMENT', isCompact: isCompact),
                                  SizedBox(height: isCompact ? 4 : 12),
                                  
                                  // Equipment Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: kEquipmentSlotLabels.keys.map((slot) {
                                      final equipment = metaCtrl.equippedDefForSlot(slot);
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: _EquipmentSlot(
                                            label: kEquipmentSlotLabels[slot]!,
                                            icon: equipment?.icon ?? '?',
                                            title: equipment?.title ?? '비어 있음',
                                            isEquipped: equipment != null,
                                            isCompact: isCompact,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: isTiny ? 16 : 24),

                        // Action Buttons
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _SketchButton(
                                  color: AutoBattlePalette.primary,
                                  isCompact: isCompact,
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
                                    'GO!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 18 : 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _SketchButton(
                                  color: AutoBattlePalette.gold,
                                  isCompact: isCompact,
                                  onTap: () => Get.to(() => const MetaShopScreen()),
                                  child: Text(
                                    'SHOP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 16 : 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!isCompact) ...[
                          const SizedBox(height: 16),
                          Obx(() => _StatsLedger(
                            maxWidth: (w * 0.9).clamp(320.0, 500.0),
                            stats: [
                              _StatItem(Icons.emoji_events, 'BEST', 'STAGE ${metaCtrl.highestStage.value}', AutoBattlePalette.gold),
                              _StatItem(Icons.diamond, 'CRYSTAL', '${metaCtrl.currency.value}', const Color(0xFF7C3AED)),
                              _StatItem(Icons.inventory_2, 'WEAPONS', '${metaCtrl.unlockedWeapons.length}', AutoBattlePalette.secondary),
                            ],
                          )),
                        ],

                        SizedBox(height: isCompact ? 4 : 16),
                        
                        Text(
                          'V.5.0 // ROLLING DUNGEON',
                          style: TextStyle(
                            color: AutoBattlePalette.ink.withValues(alpha: 0.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
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
  final bool isCompact;
  const _TapedHeader({required this.child, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 24 : 32, 
            vertical: isCompact ? 8 : 16
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutoBattlePalette.ink, width: isCompact ? 3 : 4),
            boxShadow: [
              BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 4 : 8, isCompact ? 4 : 8)),
            ],
          ),
          child: child,
        ),
        // Decorative masking tape
        Positioned(
          top: -12,
          left: 20,
          child: Transform.rotate(
            angle: -0.1,
            child: _MaskingTape(width: isCompact ? 40 : 60, height: isCompact ? 16 : 24),
          ),
        ),
        Positioned(
          bottom: -12,
          right: 20,
          child: Transform.rotate(
            angle: 0.1,
            child: _MaskingTape(width: isCompact ? 50 : 70, height: isCompact ? 18 : 28),
          ),
        ),
      ],
    );
  }
}

class _SketchbookPage extends StatelessWidget {
  final double width;
  final Widget child;
  final bool isCompact;
  const _SketchbookPage({required this.width, required this.child, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 12 : 24,
      ),
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
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isCompact;
  const _SectionTitle({required this.title, this.isCompact = false});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: AutoBattlePalette.ink.withValues(alpha: 0.5),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
    ),
  );
}


class _EquipmentSlot extends StatelessWidget {
  final String label;
  final String icon;
  final String title;
  final bool isEquipped;
  final bool isCompact;

  const _EquipmentSlot({
    required this.label,
    required this.icon,
    required this.title,
    this.isEquipped = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AutoBattlePalette.ink.withValues(alpha: 0.5),
            fontSize: isCompact ? 8 : 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: isCompact ? 2 : 4),
        Container(
          width: isCompact ? 40 : 56,
          height: isCompact ? 40 : 56,
          decoration: BoxDecoration(
            color: isEquipped ? AutoBattlePalette.paper : AutoBattlePalette.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AutoBattlePalette.ink, width: 2),
            boxShadow: [
              if (isEquipped)
                BoxShadow(
                  color: AutoBattlePalette.ink,
                  offset: Offset(isCompact ? 1 : 2, isCompact ? 1 : 2),
                ),
            ],
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(fontSize: isCompact ? 18 : 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AutoBattlePalette.ink,
            fontSize: isCompact ? 8 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SketchButton extends StatefulWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final bool isCompact;

  const _SketchButton({
    required this.color, 
    required this.child, 
    required this.onTap,
    this.isCompact = false,
  });

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
        height: widget.isCompact ? 48 : 64,
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

