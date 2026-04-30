import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:circle_war/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class UpgradeSelectScreen extends StatefulWidget {
  const UpgradeSelectScreen({super.key});

  @override
  State<UpgradeSelectScreen> createState() => _UpgradeSelectScreenState();
}

class _UpgradeSelectScreenState extends State<UpgradeSelectScreen>
    with SingleTickerProviderStateMixin {
  late final GameProgressController _ctrl;
  late final List<UpgradeCard> _cards;
  late final AnimationController _animCtrl;
  int? _hoveredIndex;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GameProgressController>();
    _cards = _ctrl.generateUpgradeChoices();
    _ctrl.generateShopItems();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onCardTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _proceedToNextStage() {
    if (_selectedIndex == null) return;
    _ctrl.applyUpgrade(_cards[_selectedIndex!]);
    _ctrl.nextStage();
    Get.off(() => const AutoBattleGamePage());
  }

  void _returnHome() {
    Get.offAll(() => const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          // Background sketch lines
          Positioned.fill(
            child: CustomPaint(painter: _SketchPaperPainter()),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 420 || constraints.maxWidth < 760;
                final isPortrait = constraints.maxHeight > constraints.maxWidth;
                final titleSize = compact ? 22.0 : 28.0;
                final cardW = isPortrait
                    ? (constraints.maxWidth * 0.86)
                        .clamp(260.0, 420.0)
                        .toDouble()
                    : (constraints.maxWidth * 0.29)
                        .clamp(compact ? 210.0 : 240.0, 310.0)
                        .toDouble();
                final gap = compact ? 14.0 : 20.0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 10 : 20),

                      // ── Title ──
                      _buildTitle(titleSize, compact),
                      SizedBox(height: compact ? 6 : 12),

                      // ── Sub-title ──
                      _buildSubtitle(compact),
                      SizedBox(height: compact ? 12 : 18),

                      // ── Cards (Simplified) ──
                      _buildUpgradeSection(isPortrait, cardW, gap),

                      const SizedBox(height: 20),

                      // ── Shop Section ──
                      _buildShopSection(compact),

                      const SizedBox(height: 12),

                      // ── Stats bar ──
                      _buildStatsBar(compact),

                      const SizedBox(height: 16),

                      // ── Proceed Button ──
                      _buildProceedButton(compact),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: _SketchExitButton(onTap: _returnHome),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(double titleSize, bool compact) {
    return Text(
      'AUGMENT SELECT',
      style: TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w900,
        color: AutoBattlePalette.ink,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildSubtitle(bool compact) {
    return Text(
      '강력한 능력을 선택하여 더 깊은 던전으로 향하세요',
      style: TextStyle(
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w800,
        color: AutoBattlePalette.inkSubtle,
      ),
    );
  }

  Widget _buildUpgradeSection(bool isPortrait, double cardW, double gap) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final cardWidgets = List.generate(_cards.length, (i) {
          final delay = i * 0.12;
          final t = CurvedAnimation(
            parent: _animCtrl,
            curve: Interval(
              delay.clamp(0.0, 0.6),
              (delay + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          );
          return Padding(
            padding: EdgeInsets.only(
              right: !isPortrait && i < _cards.length - 1 ? gap : 0,
              bottom: isPortrait && i < _cards.length - 1 ? gap : 0,
            ),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - t.value)),
              child: Opacity(
                opacity: t.value.clamp(0.0, 1.0),
                child: _UpgradeCardWidget(
                  card: _cards[i],
                  index: i,
                  width: cardW,
                  isHovered: _hoveredIndex == i,
                  isSelected: _selectedIndex == i,
                  onHover: (h) => setState(() => _hoveredIndex = h ? i : null),
                  onTap: () => _onCardTapped(i),
                ),
              ),
            ),
          );
        });

        return isPortrait
            ? Column(mainAxisSize: MainAxisSize.min, children: cardWidgets)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: cardWidgets);
      },
    );
  }

  Widget _buildShopSection(bool compact) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart,
                      color: AutoBattlePalette.ink, size: compact ? 16 : 20),
                  const SizedBox(width: 8),
                  Text('무기 상점',
                      style: TextStyle(
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w900,
                          color: AutoBattlePalette.ink)),
                ],
              ),
              Obx(() => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 3 : 4),
                    decoration: BoxDecoration(
                      color: AutoBattlePalette.gold,
                      border: Border.all(color: AutoBattlePalette.ink, width: 2),
                    ),
                    child: Text('💰 ${_ctrl.gold.value.round()}',
                        style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  )),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Obx(() => Row(
                children: _ctrl.shopItems.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ShopItemWidget(
                        item: item,
                        compact: compact,
                        isOwned: _ctrl.ownedWeapons.contains(item.weaponType),
                        canAfford: _ctrl.gold.value >= item.price,
                        onBuy: () => _ctrl.buyWeapon(item),
                      ),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  Widget _buildProceedButton(bool compact) {
    final enabled = _selectedIndex != null;
    return GestureDetector(
      onTap: enabled ? _proceedToNextStage : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? AutoBattlePalette.primary : Colors.grey,
            border: Border.all(color: AutoBattlePalette.ink, width: 3),
            boxShadow: enabled
                ? const [
                    BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))
                  ]
                : null,
          ),
          child: const Center(
            child: Text(
              'NEXT STAGE ➔',
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
    );
  }

  Widget _buildStatsBar(bool compact) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 14, left: 20, right: 20),
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Obx(() => Wrap(
            alignment: WrapAlignment.spaceEvenly,
            runSpacing: 8,
            spacing: compact ? 10 : 18,
            children: [
              _StatChip(
                  icon: Icons.favorite,
                  label: 'HP',
                  value: '${_ctrl.playerMaxHp.value.round()}',
                  color: AutoBattlePalette.primary),
              _StatChip(
                  icon: Icons.flash_on,
                  label: 'ATK',
                  value: _ctrl.playerAtk.value.toStringAsFixed(1),
                  color: const Color(0xFFFF6B00)),
              _StatChip(
                  icon: Icons.shield,
                  label: 'DEF',
                  value: _ctrl.playerDef.value.toStringAsFixed(1),
                  color: AutoBattlePalette.secondary),
              _StatChip(
                  icon: Icons.speed,
                  label: 'SPD',
                  value: _ctrl.playerSpd.value.toStringAsFixed(2),
                  color: AutoBattlePalette.gold),
              _StatChip(
                  icon: Icons.inventory_2,
                  label: 'WPNs',
                  value: '${_ctrl.ownedWeapons.length + 1}',
                  color: const Color(0xFFAA44FF)),
              _StatChip(
                  icon: Icons.change_circle,
                  label: 'REF',
                  value: '${_ctrl.playerBulletReflectCount.value}',
                  color: const Color(0xFF38BDF8)),
            ],
          )),
    );
  }
}

class _ShopItemWidget extends StatelessWidget {
  final ShopItem item;
  final bool isOwned;
  final bool canAfford;
  final bool compact;
  final VoidCallback onBuy;

  const _ShopItemWidget({
    required this.item,
    required this.isOwned,
    required this.canAfford,
    required this.compact,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOwned ? null : onBuy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 6 : 10),
        decoration: BoxDecoration(
          color: isOwned ? const Color(0xFFE2E8F0) : Colors.white,
          border: Border.all(
            color: isOwned ? const Color(0xFF94A3B8) : AutoBattlePalette.ink,
            width: compact ? 2 : 3,
          ),
          boxShadow: isOwned
              ? null
              : [
                  BoxShadow(
                      color: AutoBattlePalette.ink,
                      offset: Offset(compact ? 3 : 4, compact ? 3 : 4))
                ],
        ),
        child: Row(
          children: [
            Text(item.icon, style: TextStyle(fontSize: compact ? 18 : 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                    color: AutoBattlePalette.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isOwned
                    ? const Color(0xFF94A3B8)
                    : (canAfford
                        ? AutoBattlePalette.gold
                        : const Color(0xFFEF4444)),
                border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
              ),
              child: Text(
                isOwned ? 'OWNED' : '${item.price}G',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SketchExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AutoBattlePalette.ink,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Single Upgrade Card Widget
// ─────────────────────────────────────────────
class _UpgradeCardWidget extends StatelessWidget {
  final UpgradeCard card;
  final int index;
  final double width;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _UpgradeCardWidget({
    required this.card,
    required this.index,
    required this.width,
    required this.isHovered,
    required this.isSelected,
    required this.onHover,
    required this.onTap,
  });

  Color get _typeColor {
    switch (card.type) {
      case 'attack_up':
        return const Color(0xFFEF4444);
      case 'defense_up':
        return const Color(0xFF3B82F6);
      case 'body_small':
        return const Color(0xFFFF9500);
      case 'body_big':
        return const Color(0xFF22C55E);
      case 'weapon_count':
        return const Color(0xFF7C3AED);
      case 'bullet_burst':
        return const Color(0xFFBE123C);
      case 'bullet_reflect':
        return const Color(0xFF0284C7);
      case 'barrier':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _typeIcon {
    switch (card.type) {
      case 'attack_up':
        return Icons.local_fire_department;
      case 'defense_up':
        return Icons.shield_rounded;
      case 'body_small':
        return Icons.bolt;
      case 'body_big':
        return Icons.radio_button_unchecked;
      case 'weapon_count':
        return Icons.auto_fix_high;
      case 'bullet_burst':
        return Icons.grain;
      case 'bullet_reflect':
        return Icons.change_circle;
      case 'barrier':
        return Icons.security;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shadowOffset = (isHovered || isSelected) ? 8.0 : 4.0;
    final lift = (isHovered || isSelected) ? -3.0 : 0.0;
    final borderColor = isSelected
        ? AutoBattlePalette.primary
        : (isHovered ? _typeColor : AutoBattlePalette.ink);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, lift, 0),
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: isSelected ? 4 : 3),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AutoBattlePalette.primary.withValues(alpha: 0.4)
                    : (isHovered
                        ? _typeColor.withValues(alpha: 0.4)
                        : AutoBattlePalette.ink),
                offset: Offset(shadowOffset, shadowOffset),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_typeIcon, color: _typeColor, size: 24),
              const SizedBox(height: 6),
              Text(
                card.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AutoBattlePalette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.statPreview,
                style: TextStyle(
                  color: _typeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stat chip for bottom bar
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AutoBattlePalette.ink, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AutoBattlePalette.inkSubtle,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Background Paper + Sketch Lines
// ─────────────────────────────────────────────
class _SketchPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal ruled lines (notebook paper)
    final linePaint = Paint()
      ..color = const Color(0xFF87CEEB).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 28) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Vertical margin line
    canvas.drawLine(
      const Offset(40, 0),
      Offset(40, size.height),
      Paint()
        ..color = const Color(0xFFFF9999).withValues(alpha: 0.15)
        ..strokeWidth = 2,
    );

    // Random sketch doodles
    final rand = math.Random(789);
    final doodlePaint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.03)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final cx = rand.nextDouble() * size.width;
      final cy = rand.nextDouble() * size.height;
      final r = 15 + rand.nextDouble() * 30;
      canvas.drawCircle(Offset(cx, cy), r, doodlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
