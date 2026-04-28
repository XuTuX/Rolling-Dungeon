import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GameProgressController>();
    _cards = _ctrl.generateUpgradeChoices();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          // Background sketch lines
          Positioned.fill(
            child: CustomPaint(painter: _SketchLinesPainter()),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 420 || constraints.maxWidth < 760;
                final titleSize = compact ? 24.0 : 32.0;
                final cardW = (constraints.maxWidth * 0.27)
                    .clamp(compact ? 170.0 : 200.0, 240.0)
                    .toDouble();
                final cardH = (constraints.maxHeight * 0.68)
                    .clamp(compact ? 240.0 : 300.0, 380.0)
                    .toDouble();
                final gap = compact ? 16.0 : 28.0;

                return Column(
                  children: [
                    SizedBox(height: compact ? 12 : 24),

                    // ── Title ──
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 20 : 32,
                        vertical: compact ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: AutoBattlePalette.ink, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AutoBattlePalette.ink,
                            offset: Offset(8, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'SELECT AUGMENT',
                        style: TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),

                    // ── Sub-title ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AutoBattlePalette.gold,
                        border: Border.all(
                            color: AutoBattlePalette.ink, width: 2),
                      ),
                      child: Text(
                        'STAGE ${_ctrl.currentStage.value} CLEARED!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 16 : 28),

                    // ── Cards ──
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (context, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: List.generate(
                                    _cards.length, (i) {
                                  final delay = i * 0.15;
                                  final t = CurvedAnimation(
                                    parent: _animCtrl,
                                    curve: Interval(
                                      delay.clamp(0.0, 0.7),
                                      (delay + 0.6).clamp(0.0, 1.0),
                                      curve: Curves.easeOutBack,
                                    ),
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right:
                                            i < _cards.length - 1
                                                ? gap
                                                : 0),
                                    child: Transform.translate(
                                      offset: Offset(
                                          0, 40 * (1 - t.value)),
                                      child: Opacity(
                                        opacity: t.value
                                            .clamp(0.0, 1.0),
                                        child:
                                            _UpgradeCardWidget(
                                          card: _cards[i],
                                          width: cardW,
                                          height: cardH,
                                          compact: compact,
                                          onTap: () =>
                                              _selectCard(
                                                  _cards[i]),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // ── Stats bar ──
                    Container(
                      margin: EdgeInsets.only(
                          bottom: compact ? 8 : 16,
                          left: 24,
                          right: 24),
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 20,
                          vertical: compact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: AutoBattlePalette.ink, width: 2),
                      ),
                      child: Obx(() => Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatChip(
                                  label: 'HP',
                                  value:
                                      '${_ctrl.playerMaxHp.value.round()}',
                                  color: AutoBattlePalette.mint),
                              _StatChip(
                                  label: 'ATK',
                                  value:
                                      _ctrl.playerAtk.value.toStringAsFixed(1),
                                  color: AutoBattlePalette.primary),
                              _StatChip(
                                  label: 'DEF',
                                  value:
                                      _ctrl.playerDef.value.toStringAsFixed(1),
                                  color: AutoBattlePalette.secondary),
                              _StatChip(
                                  label: 'SPD',
                                  value:
                                      _ctrl.playerSpd.value.toStringAsFixed(2),
                                  color: AutoBattlePalette.gold),
                            ],
                          )),
                    ),
                  ],
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
//  Single Upgrade Card Widget
// ─────────────────────────────────────────────
class _UpgradeCardWidget extends StatelessWidget {
  final UpgradeCard card;
  final double width;
  final double height;
  final bool compact;
  final VoidCallback onTap;

  const _UpgradeCardWidget({
    required this.card,
    required this.width,
    required this.height,
    required this.compact,
    required this.onTap,
  });

  Color get _rarityColor {
    switch (card.rarity) {
      case 'epic':
        return const Color(0xFFAA44FF);
      case 'rare':
        return AutoBattlePalette.secondary;
      default:
        return AutoBattlePalette.inkSubtle;
    }
  }

  Color get _cardColor {
    switch (card.type) {
      case 'assault':
        return AutoBattlePalette.primary;
      case 'guard':
        return AutoBattlePalette.secondary;
      case 'haste':
        return AutoBattlePalette.gold;
      case 'vitality':
        return AutoBattlePalette.mint;
      case 'mastery':
        return const Color(0xFFAA44FF);
      default:
        return AutoBattlePalette.inkSubtle;
    }
  }

  IconData get _cardIcon {
    switch (card.type) {
      case 'assault':
        return Icons.flash_on;
      case 'guard':
        return Icons.shield;
      case 'haste':
        return Icons.speed;
      case 'vitality':
        return Icons.favorite;
      case 'mastery':
        return Icons.auto_awesome;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 4),
          boxShadow: const [
            BoxShadow(
              color: AutoBattlePalette.ink,
              offset: Offset(8, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Rarity Badge ──
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.symmetric(vertical: compact ? 5 : 6),
              decoration: BoxDecoration(
                color: _rarityColor,
                border: const Border(
                  bottom:
                      BorderSide(color: AutoBattlePalette.ink, width: 3),
                ),
              ),
              child: Center(
                child: Text(
                  card.rarity.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // ── Icon Area ──
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: _cardColor,
                child: Center(
                  child: Icon(
                    _cardIcon,
                    size: compact ? 52 : 68,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                          color: AutoBattlePalette.ink,
                          offset: Offset(3, 3)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Divider ──
            Container(
              height: 4,
              color: AutoBattlePalette.ink,
            ),

            // ── Info Area ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(compact ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Expanded(
                      child: Text(
                        card.description,
                        style: TextStyle(
                          color: AutoBattlePalette.inkSubtle,
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    // ── Stat Preview ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: _cardColor.withValues(alpha: 0.12),
                        border: Border.all(color: _cardColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          card.statPreview,
                          style: TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: compact ? 13 : 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stat chip for bottom bar
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
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
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AutoBattlePalette.ink, width: 2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 4),
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
//  Background Sketch Lines
// ─────────────────────────────────────────────
class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 2;

    final random = math.Random(456);
    for (var i = 0; i < 30; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (random.nextDouble() - 0.5) * 50),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
