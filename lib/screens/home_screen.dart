import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';
import 'package:circle_war/screens/achievement_screen.dart';
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
                final isNarrow = w < 390;
                final isCompact = h < 620 || isNarrow;
                final isTiny = h < 520;
                final isWide = w >= 860 && h >= 520;
                final horizontalPadding =
                    isNarrow ? 10.0 : (isCompact ? 14.0 : 20.0);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isTiny ? 8 : (isCompact ? 10 : 16),
                  ),
                  child: Column(
                    children: [
                      _TapedHeader(
                        isCompact: isCompact,
                        child: Text(
                          'ROLLING DUNGEON',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: isTiny ? 20 : (isCompact ? 24 : 34),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 10 : 16),
                      Expanded(
                        child: Obx(() {
                          final character = metaCtrl.currentCharacterDef;
                          final characterInfo =
                              charDisplayInfoMap[character.shape] ??
                                  charDisplayInfoMap['circle']!;
                          final loadoutStats = metaCtrl.currentLoadoutStats;

                          final buildPanel = _SketchbookPage(
                            isCompact: isCompact,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SectionTitle(
                                  title: 'LOADOUT',
                                  isCompact: isCompact,
                                ),
                                SizedBox(height: isCompact ? 4 : 8),
                                _LoadoutSummaryRow(
                                  character: character,
                                  info: characterInfo,
                                  isCompact: isCompact,
                                ),
                                SizedBox(height: isCompact ? 8 : 12),
                                _SectionTitle(
                                  title: 'CHARACTER STATS',
                                  isCompact: isCompact,
                                ),
                                SizedBox(height: isCompact ? 4 : 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: _LoadoutStatsPanel(
                                      stats: loadoutStats,
                                      isCompact: isCompact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          return buildPanel;
                        }),
                      ),
                      SizedBox(height: isCompact ? 10 : 14),
                      _HomeActionPanel(
                        isCompact: isCompact,
                        isWide: isWide,
                        onStart: () {
                          final charDef = metaCtrl.currentCharacterDef;
                          runCtrl.startNewRun(
                            metaCtrl.selectedCharacter.value,
                            charDef.shape,
                            unlockedWeapons: metaCtrl.unlockedWeapons,
                            equippedEquipment: metaCtrl.equippedEquipment,
                            statLevels: metaCtrl.statLevels,
                          );
                          Get.to(() => const AutoBattleGamePage());
                        },
                      ),
                      if (!isTiny) ...[
                        SizedBox(height: isCompact ? 8 : 10),
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
                    ],
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
  final Widget child;
  final bool isCompact;
  const _SketchbookPage({
    required this.child,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 18,
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
  final bool isEquipped;
  final bool isCompact;

  const _EquipmentSlot({
    required this.label,
    required this.icon,
    this.isEquipped = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AutoBattlePalette.ink.withValues(alpha: 0.18),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 34 : 42,
            height: isCompact ? 34 : 42,
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
                style: TextStyle(fontSize: isCompact ? 16 : 20),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: isCompact ? 7 : 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterBadge extends StatelessWidget {
  final CharacterShopDef character;
  final CharDisplayInfo info;
  final bool isCompact;

  const _CharacterBadge({
    required this.character,
    required this.info,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 38 : 46,
            height: isCompact ? 38 : 46,
            decoration: BoxDecoration(
              color: AutoBattlePalette.surfaceLight,
              border: Border.all(color: AutoBattlePalette.ink, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CharacterBallPreview(
                info: info,
                size: isCompact ? 30 : 36,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 4),
            child: Text(
              character.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: isCompact ? 8 : 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadoutSummaryRow extends StatelessWidget {
  final CharacterShopDef character;
  final CharDisplayInfo info;
  final bool isCompact;

  const _LoadoutSummaryRow({
    required this.character,
    required this.info,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final metaCtrl = Get.find<MetaProgressController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: _CharacterBadge(
              character: character,
              info: info,
              isCompact: isCompact,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 8 : 10),
        Expanded(
          flex: 4,
          child: Row(
            children: kEquipmentSlotLabels.keys.map<Widget>((slot) {
              final equipment = metaCtrl.equippedDefForSlot(slot);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 3),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _EquipmentSlot(
                      label: kEquipmentSlotLabels[slot]!.split('/').first,
                      icon: equipment?.icon ?? '?',
                      isEquipped: equipment != null,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
        mainAxisSize: MainAxisSize.min,
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

class _HomeActionPanel extends StatelessWidget {
  final bool isCompact;
  final bool isWide;
  final VoidCallback onStart;

  const _HomeActionPanel({
    required this.isCompact,
    required this.isWide,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryHeight = isCompact ? 40.0 : 46.0;
    final primaryButton = _SketchButton(
      color: AutoBattlePalette.primary,
      isCompact: isCompact,
      height: isCompact ? 48 : 58,
      onTap: onStart,
      child: Text(
        'START RUN!',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 17 : 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final shopButton = _SketchButton(
      color: AutoBattlePalette.gold,
      isCompact: isCompact,
      height: secondaryHeight,
      onTap: () => Get.to(() => const MetaShopScreen()),
      child: Text(
        'SHOP',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 14 : 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final achievementButton = _SketchButton(
      color: const Color(0xFF7C3AED),
      isCompact: isCompact,
      height: secondaryHeight,
      onTap: () => Get.to(() => const AchievementScreen()),
      child: Text(
        'ACHIEVES',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 14 : 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 3, child: primaryButton),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: shopButton),
                const SizedBox(width: 12),
                Expanded(child: achievementButton),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(width: double.infinity, child: primaryButton),
        SizedBox(height: isCompact ? 8 : 10),
        Row(
          children: [
            Expanded(child: shopButton),
            const SizedBox(width: 12),
            Expanded(child: achievementButton),
          ],
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

class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 1.5;

    for (var y = 60.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final marginPaint = Paint()
      ..color = AutoBattlePalette.primary.withValues(alpha: 0.1)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
