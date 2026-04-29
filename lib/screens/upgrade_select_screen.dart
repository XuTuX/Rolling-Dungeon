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

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GameProgressController>();
    _cards = _ctrl.generateUpgradeChoices();
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

  void _selectCard(UpgradeCard card) {
    _ctrl.applyUpgrade(card);
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
                final cardH = isPortrait
                    ? (constraints.maxHeight * 0.24)
                        .clamp(188.0, 240.0)
                        .toDouble()
                    : (constraints.maxHeight * 0.54)
                        .clamp(compact ? 226.0 : 260.0, 330.0)
                        .toDouble();
                final gap = compact ? 14.0 : 20.0;

                return Column(
                  children: [
                    SizedBox(height: compact ? 10 : 20),

                    // ── Title ──
                    _buildTitle(titleSize, compact),
                    SizedBox(height: compact ? 6 : 12),

                    // ── Sub-title ──
                    _buildSubtitle(compact),
                    SizedBox(height: compact ? 12 : 22),

                    // ── Cards ──
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection:
                              isPortrait ? Axis.vertical : Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (context, _) {
                              final cardWidgets =
                                  List.generate(_cards.length, (i) {
                                final delay = i * 0.18;
                                final t = CurvedAnimation(
                                  parent: _animCtrl,
                                  curve: Interval(
                                    delay.clamp(0.0, 0.6),
                                    (delay + 0.55).clamp(0.0, 1.0),
                                    curve: Curves.easeOutBack,
                                  ),
                                );
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: !isPortrait && i < _cards.length - 1
                                        ? gap
                                        : 0,
                                    bottom: isPortrait && i < _cards.length - 1
                                        ? gap
                                        : 0,
                                  ),
                                  child: Transform.translate(
                                    offset: Offset(
                                        0,
                                        isPortrait
                                            ? 30 * (1 - t.value)
                                            : 50 * (1 - t.value)),
                                    child: Opacity(
                                      opacity: t.value.clamp(0.0, 1.0),
                                      child: _UpgradeCardWidget(
                                        card: _cards[i],
                                        index: i,
                                        width: cardW,
                                        height: cardH,
                                        compact: compact,
                                        isHovered: _hoveredIndex == i,
                                        onHover: (h) => setState(
                                            () => _hoveredIndex = h ? i : null),
                                        onTap: () => _selectCard(_cards[i]),
                                      ),
                                    ),
                                  ),
                                );
                              });

                              return isPortrait
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: cardWidgets,
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: cardWidgets,
                                    );
                            },
                          ),
                        ),
                      ),
                    ),

                    // ── Stats bar ──
                    _buildStatsBar(compact),
                  ],
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

  Widget _buildTitle(double fontSize, bool compact) {
    return Stack(
      children: [
        // Shadow
        Positioned(
          left: 6,
          top: 6,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 28,
              vertical: compact ? 8 : 10,
            ),
            color: AutoBattlePalette.ink,
            child: Text(
              '증강 선택',
              style: TextStyle(
                color: Colors.transparent,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 28,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutoBattlePalette.ink, width: 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  color: AutoBattlePalette.gold, size: compact ? 22 : 28),
              SizedBox(width: compact ? 8 : 12),
              Text(
                '증강 선택',
                style: TextStyle(
                  color: AutoBattlePalette.ink,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: AutoBattlePalette.mint,
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Text(
        'STAGE ${_ctrl.currentStage.value} CLEAR ★',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 12 : 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
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
                  icon: Icons.auto_fix_high,
                  label: 'WPN',
                  value: '${_ctrl.playerWeaponCount.value}',
                  color: const Color(0xFFAA44FF)),
              _StatChip(
                  icon: Icons.change_circle,
                  label: 'REF',
                  value: '${_ctrl.playerBulletReflectCount.value}',
                  color: const Color(0xFF38BDF8)),
              _StatChip(
                  icon: Icons.grain,
                  label: 'SHOT',
                  value: '${_ctrl.playerBulletsPerWeapon.value}',
                  color: const Color(0xFFBE123C)),
              _StatChip(
                  icon: Icons.radio_button_unchecked,
                  label: 'SIZE',
                  value: '${_ctrl.playerRadius.value.round()}',
                  color: const Color(0xFF0F766E)),
              _StatChip(
                  icon: Icons.security,
                  label: 'BAR',
                  value: '${_ctrl.playerBarrierMaxHp.value.round()}',
                  color: const Color(0xFF38BDF8)),
            ],
          )),
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
  final double height;
  final bool compact;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _UpgradeCardWidget({
    required this.card,
    required this.index,
    required this.width,
    required this.height,
    required this.compact,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  Color get _rarityColor {
    switch (card.rarity) {
      case 'epic':
        return const Color(0xFFAA44FF);
      case 'rare':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _rarityLabel {
    switch (card.rarity) {
      case 'epic':
        return '★★★ EPIC';
      case 'rare':
        return '★★ RARE';
      default:
        return '★ COMMON';
    }
  }

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
    final shadowOffset = isHovered ? 10.0 : 6.0;
    final lift = isHovered ? -4.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, lift, 0),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: isHovered ? _typeColor : AutoBattlePalette.ink,
                width: isHovered ? 5 : 4),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? _typeColor.withValues(alpha: 0.4)
                    : AutoBattlePalette.ink,
                offset: Offset(shadowOffset, shadowOffset),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 38 : 46,
                      height: compact ? 38 : 46,
                      decoration: BoxDecoration(
                        color: _typeColor,
                        border:
                            Border.all(color: AutoBattlePalette.ink, width: 3),
                      ),
                      child: Icon(_typeIcon,
                          color: Colors.white, size: compact ? 22 : 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rarityLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _rarityColor,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            card.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AutoBattlePalette.ink,
                              fontSize: compact ? 17 : 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 14),
                Expanded(
                  child: Text(
                    card.description.replaceAll('\\n', '\n'),
                    style: TextStyle(
                      color: AutoBattlePalette.inkSubtle,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 14,
                      vertical: compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    border: Border.all(color: _typeColor, width: 2.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          color: _typeColor, size: compact ? 16 : 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          card.statPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _typeColor,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
