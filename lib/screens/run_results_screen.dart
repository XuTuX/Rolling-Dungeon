import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:circle_war/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown after a run ends (player death). Displays run stats,
/// newly completed achievements, and currency earned.
class RunResultsScreen extends StatefulWidget {
  const RunResultsScreen({super.key});

  @override
  State<RunResultsScreen> createState() => _RunResultsScreenState();
}

class _RunResultsScreenState extends State<RunResultsScreen>
    with SingleTickerProviderStateMixin {
  late final GameProgressController _runCtrl;
  late final MetaProgressController _metaCtrl;
  late final List<AchievementDef> _newAchievements;
  late final int _currencyEarned;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _runCtrl = Get.find<GameProgressController>();
    _metaCtrl = Get.find<MetaProgressController>();

    // End run → accumulate stats → check achievements
    final prevCurrency = _metaCtrl.currency.value;
    _newAchievements = _metaCtrl.endRun(
      enemiesKilled: _runCtrl.runEnemiesKilled.value,
      bossesDefeated: _runCtrl.runBossesDefeated.value,
      damageDealt: _runCtrl.runDamageDealt.value,
      stageReached: _runCtrl.totalStageNumber.value,
      cycleReached: _runCtrl.currentCycle.value,
    );
    _currencyEarned = _metaCtrl.currency.value - prevCurrency;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SketchBgPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _animCtrl.value)),
                      child: Opacity(
                        opacity: _animCtrl.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          border: Border.all(
                              color: AutoBattlePalette.ink, width: 4),
                          boxShadow: const [
                            BoxShadow(
                                color: AutoBattlePalette.ink,
                                offset: Offset(6, 6)),
                          ],
                        ),
                        child: const Text(
                          'RUN OVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Card
                      _buildStatsCard(),
                      const SizedBox(height: 16),

                      // Achievements
                      if (_newAchievements.isNotEmpty) ...[
                        _buildAchievementsCard(),
                        const SizedBox(height: 16),
                      ],

                      // Currency Earned
                      if (_currencyEarned > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.gold,
                            border: Border.all(
                                color: AutoBattlePalette.ink, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: AutoBattlePalette.ink,
                                  offset: Offset(4, 4)),
                            ],
                          ),
                          child: Text(
                            '💰 +$_currencyEarned 크리스탈 획득!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Return Home Button
                      GestureDetector(
                        onTap: () =>
                            Get.offAll(() => const HomeScreen()),
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.primary,
                            border: Border.all(
                                color: AutoBattlePalette.ink, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: AutoBattlePalette.ink,
                                  offset: Offset(4, 4)),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'RETURN HOME',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RUN STATS',
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _statRow('도달 사이클', '${_runCtrl.currentCycle.value}'),
          _statRow('도달 스테이지', '${_runCtrl.totalStageNumber.value}'),
          _statRow('처치한 적', '${_runCtrl.runEnemiesKilled.value}'),
          _statRow('처치한 보스', '${_runCtrl.runBossesDefeated.value}'),
          _statRow('총 피해량',
              _runCtrl.runDamageDealt.value.toStringAsFixed(0)),
          const Divider(color: AutoBattlePalette.ink, thickness: 2),
          _statRow('최고 기록 스테이지', '${_metaCtrl.highestStage.value}',
              highlight: true),
          _statRow('총 보유 크리스탈', '${_metaCtrl.currency.value}',
              highlight: true),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? AutoBattlePalette.primary : AutoBattlePalette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AutoBattlePalette.primary : AutoBattlePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: AutoBattlePalette.gold, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: AutoBattlePalette.gold, size: 22),
              SizedBox(width: 8),
              Text(
                '업적 달성!',
                style: TextStyle(
                  color: AutoBattlePalette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._newAchievements.map((ach) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AutoBattlePalette.gold,
                        border: Border.all(
                            color: AutoBattlePalette.ink, width: 2),
                      ),
                      child: Text(
                        '+${ach.currencyReward}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ach.title,
                            style: const TextStyle(
                              color: AutoBattlePalette.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            ach.description,
                            style: const TextStyle(
                              color: AutoBattlePalette.inkSubtle,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SketchBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;

    for (var y = 28.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
