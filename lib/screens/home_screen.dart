import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';
import 'package:circle_war/screens/meta_shop_screen.dart';
import 'package:circle_war/screens/achievement_screen.dart';
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
                final isNarrow = w < 390;
                // UI adapts based on vertical and horizontal space.
                final isCompact = h < 600 || isNarrow;
                final isTiny = h < 480;
                final showLedger = h >= 760;
                final horizontalPadding =
                    isNarrow ? 12.0 : (isTiny ? 14.0 : 20.0);
                final contentWidth =
                    (w - horizontalPadding * 2).clamp(280.0, 560.0);

                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isTiny ? 4 : (isCompact ? 8 : 16),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: contentWidth,
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
                                  fontSize: isCompact ? 22 : 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),

                            SizedBox(height: isCompact ? 10 : 32),

                            // Character Preview & Equip
                            Obx(() {
                              final loadoutStats = metaCtrl.currentLoadoutStats;
                              final character = metaCtrl.currentCharacterDef;
                              final characterInfo =
                                  charDisplayInfoMap[character.shape] ??
                                      charDisplayInfoMap['circle']!;

                              return _SketchbookPage(
                                width: contentWidth,
                                isCompact: isCompact,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _SectionTitle(
                                        title: 'CHARACTER',
                                        isCompact: isCompact),
                                    SizedBox(height: isCompact ? 4 : 8),
                                    _SelectedCharacterCard(
                                      character: character,
                                      info: characterInfo,
                                      isCompact: isCompact,
                                    ),

                                    SizedBox(height: isCompact ? 8 : 12),
                                    _SectionTitle(
                                        title: 'EQUIPMENT',
                                        isCompact: isCompact),
                                    SizedBox(height: isCompact ? 3 : 8),

                                    // Equipment Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: kEquipmentSlotLabels.keys
                                          .map<Widget>((slot) {
                                        final equipment =
                                            metaCtrl.equippedDefForSlot(slot);
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: _EquipmentSlot(
                                              label:
                                                  kEquipmentSlotLabels[slot]!,
                                              icon: equipment?.icon ?? '?',
                                              title:
                                                  equipment?.title ?? '비어 있음',
                                              isEquipped: equipment != null,
                                              isCompact: isCompact,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    SizedBox(height: isCompact ? 8 : 12),
                                    _SectionTitle(
                                        title: 'CHARACTER STATS',
                                        isCompact: isCompact),
                                    SizedBox(height: isCompact ? 4 : 8),
                                    _LoadoutStatsPanel(
                                      stats: loadoutStats,
                                      isCompact: isCompact,
                                    ),
                                  ],
                                ),
                              );
                            }),

                            SizedBox(height: isTiny ? 10 : 14),

                            // Action Buttons
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: contentWidth.clamp(280.0, 440.0)),
                              child: Column(
                                children: [
                                  _SketchButton(
                                    color: AutoBattlePalette.primary,
                                    isCompact: isCompact,
                                    height: isCompact ? 42 : 56,
                                    onTap: () {
                                      final charDef =
                                          metaCtrl.currentCharacterDef;
                                      runCtrl.startNewRun(
                                        metaCtrl.selectedCharacter.value,
                                        charDef.shape,
                                        unlockedWeapons:
                                            metaCtrl.unlockedWeapons,
                                        equippedEquipment:
                                            metaCtrl.equippedEquipment,
                                        statLevels: metaCtrl.statLevels,
                                      );
                                      Get.to(() => const AutoBattleGamePage());
                                    },
                                    child: Text(
                                      'START RUN!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 16 : 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 7 : 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SketchButton(
                                          color: AutoBattlePalette.gold,
                                          isCompact: isCompact,
                                          height: isCompact ? 36 : 46,
                                          onTap: () => Get.to(
                                              () => const MetaShopScreen()),
                                          child: Text(
                                            'SHOP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompact ? 14 : 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _SketchButton(
                                          color: const Color(0xFF7C3AED),
                                          isCompact: isCompact,
                                          height: isCompact ? 36 : 46,
                                          onTap: () => Get.to(
                                              () => const AchievementScreen()),
                                          child: Text(
                                            'ACHIEVES',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompact ? 14 : 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (showLedger) ...[
                              const SizedBox(height: 12),
                              Obx(() => _StatsLedger(
                                    maxWidth: contentWidth.clamp(280.0, 500.0),
                                    stats: [
                                      _StatItem(
                                          Icons.emoji_events,
                                          'BEST',
                                          'STAGE ${metaCtrl.highestStage.value}',
                                          AutoBattlePalette.gold),
                                      _StatItem(
                                          Icons.diamond,
                                          'CRYSTAL',
                                          '${metaCtrl.currency.value}',
                                          const Color(0xFF7C3AED)),
                                      _StatItem(
                                          Icons.inventory_2,
                                          'WEAPONS',
                                          '${metaCtrl.unlockedWeapons.length}',
                                          AutoBattlePalette.secondary),
                                    ],
                                  )),
                            ],

                            SizedBox(height: isCompact ? 6 : 10),

                            Text(
                              'V.5.0 // ROLLING DUNGEON',
                              style: TextStyle(
                                color: AutoBattlePalette.ink
                                    .withValues(alpha: 0.3),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
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
              horizontal: isCompact ? 24 : 32, vertical: isCompact ? 8 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: AutoBattlePalette.ink, width: isCompact ? 3 : 4),
            boxShadow: [
              BoxShadow(
                  color: AutoBattlePalette.ink,
                  offset: Offset(isCompact ? 4 : 8, isCompact ? 4 : 8)),
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
            child: _MaskingTape(
                width: isCompact ? 40 : 60, height: isCompact ? 16 : 24),
          ),
        ),
        Positioned(
          bottom: -12,
          right: 20,
          child: Transform.rotate(
            angle: 0.1,
            child: _MaskingTape(
                width: isCompact ? 50 : 70, height: isCompact ? 18 : 28),
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
  const _SketchbookPage(
      {required this.width, required this.child, this.isCompact = false});

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
        border: Border.all(
            color: AutoBattlePalette.ink.withValues(alpha: 0.1), width: 1),
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
            color: isEquipped
                ? AutoBattlePalette.paper
                : AutoBattlePalette.ink.withValues(alpha: 0.05),
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

class _SelectedCharacterCard extends StatelessWidget {
  final CharacterShopDef character;
  final CharDisplayInfo info;
  final bool isCompact;

  const _SelectedCharacterCard({
    required this.character,
    required this.info,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AutoBattlePalette.surfaceLight,
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 48 : 64,
            height: isCompact ? 48 : 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutoBattlePalette.ink, width: 2),
            ),
            child: Center(
              child: CharacterBallPreview(
                info: info,
                size: isCompact ? 40 : 56,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  character.trait,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AutoBattlePalette.secondary,
                    fontSize: isCompact ? 10 : 12,
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

class _LoadoutStatsPanel extends StatelessWidget {
  final LoadoutStatProfile stats;
  final bool isCompact;

  const _LoadoutStatsPanel({
    required this.stats,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _LoadoutStatItem(
          Icons.favorite, '체력', '${stats.hpScore}', AutoBattlePalette.primary),
      _LoadoutStatItem(
          Icons.flash_on, '공격', '${stats.atkScore}', const Color(0xFFFF6B00)),
      _LoadoutStatItem(
          Icons.shield, '방어', '${stats.defScore}', AutoBattlePalette.secondary),
      _LoadoutStatItem(
          Icons.speed, '속도', '${stats.speedScore}', AutoBattlePalette.gold),
      _LoadoutStatItem(Icons.center_focus_strong, '치명',
          '${(stats.critChance * 100).round()}%', const Color(0xFFE11D48)),
      _LoadoutStatItem(Icons.auto_fix_high, '회복',
          stats.regen.toStringAsFixed(1), const Color(0xFF16A34A)),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: AutoBattlePalette.background.withValues(alpha: 0.65),
        border: Border.all(
            color: AutoBattlePalette.ink.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: isCompact ? 5 : 8,
            spacing: isCompact ? 5 : 8,
            children: items.map((item) {
              return _LoadoutStatTile(item: item, isCompact: isCompact);
            }).toList(),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            '체력/공격/방어/속도는 100 기준',
            style: TextStyle(
              color: AutoBattlePalette.ink.withValues(alpha: 0.45),
              fontSize: isCompact ? 8 : 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadoutStatTile extends StatelessWidget {
  final _LoadoutStatItem item;
  final bool isCompact;

  const _LoadoutStatTile({
    required this.item,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 58 : 64,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 6,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: item.color, size: isCompact ? 13 : 15),
          SizedBox(height: isCompact ? 2 : 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AutoBattlePalette.text3,
              fontSize: isCompact ? 8 : 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadoutStatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LoadoutStatItem(this.icon, this.label, this.value, this.color);
}

class _SketchButton extends StatefulWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final bool isCompact;
  final double? height;

  const _SketchButton({
    required this.color,
    required this.child,
    required this.onTap,
    this.isCompact = false,
    this.height,
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
        height: widget.height ?? (widget.isCompact ? 48 : 64),
        transform:
            _pressed ? Matrix4.translationValues(3, 3, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: AutoBattlePalette.ink, width: 4),
          boxShadow: _pressed
              ? null
              : const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(6, 6))
                ],
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
        children: stats.map<Widget>((s) {
          final isLast = stats.last == s;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 18),
                      const SizedBox(height: 4),
                      Text(s.label,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AutoBattlePalette.text3)),
                      Text(s.value,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AutoBattlePalette.ink)),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                      width: 2,
                      height: 30,
                      color: AutoBattlePalette.ink.withValues(alpha: 0.1)),
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
