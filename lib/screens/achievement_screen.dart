import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  String _selectedCategory = 'all';

  static const _categoryInfo = <String, _AchCategoryInfo>{
    'all': _AchCategoryInfo(
        title: '전체', icon: Icons.apps, color: AutoBattlePalette.ink),
    'kill': _AchCategoryInfo(
        title: '전투', icon: Icons.my_location, color: AutoBattlePalette.primary),
    'stage': _AchCategoryInfo(
        title: '모험', icon: Icons.explore, color: AutoBattlePalette.secondary),
    'boss': _AchCategoryInfo(
        title: '보스', icon: Icons.shield, color: Color(0xFF7C3AED)),
    'damage': _AchCategoryInfo(
        title: '기록', icon: Icons.whatshot, color: AutoBattlePalette.gold),
  };

  @override
  Widget build(BuildContext context) {
    final metaCtrl = Get.find<MetaProgressController>();
    final mediaQuery = MediaQuery.of(context);
    final isCompact =
        mediaQuery.size.height < 560 || mediaQuery.size.width < 420;
    final isNarrow = mediaQuery.size.width < 760;

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: isCompact ? 8 : 16,
          ),
          child: Column(
            children: [
              // Header
              _AchievementHeader(isCompact: isCompact),
              const SizedBox(height: 12),

              // Content Area
              Expanded(
                child: _AchievementPageFrame(
                  isCompact: isCompact,
                  child: Obx(() {
                    final completedCount = kAllAchievements
                        .where((a) => metaCtrl.achievements[a.id] == true)
                        .length;
                    final earnedReward = kAllAchievements
                        .where((a) => metaCtrl.achievements[a.id] == true)
                        .fold<int>(0, (sum, a) => sum + a.currencyReward);
                    final totalReward = kAllAchievements.fold<int>(
                        0, (sum, a) => sum + a.currencyReward);

                    final grouped = <String, List<AchievementDef>>{};
                    if (_selectedCategory == 'all') {
                      for (final a in kAllAchievements) {
                        grouped.putIfAbsent(a.category, () => []).add(a);
                      }
                    } else {
                      grouped[_selectedCategory] = kAllAchievements
                          .where((a) => a.category == _selectedCategory)
                          .toList();
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: _AchievementSummaryStrip(
                            completedCount: completedCount,
                            totalCount: kAllAchievements.length,
                            earnedReward: earnedReward,
                            totalReward: totalReward,
                            isCompact: isCompact,
                          ),
                        ),
                        Container(
                          height: isCompact ? 42 : 50,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _categoryInfo.length,
                            itemBuilder: (context, index) {
                              final catKey =
                                  _categoryInfo.keys.elementAt(index);
                              final info = _categoryInfo[catKey]!;
                              final isSelected = _selectedCategory == catKey;

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = catKey),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 10 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? info.color : Colors.white,
                                    border: Border.all(
                                        color: AutoBattlePalette.ink, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(info.icon,
                                          color: isSelected
                                              ? Colors.white
                                              : info.color,
                                          size: isCompact ? 14 : 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        info.title,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AutoBattlePalette.ink,
                                          fontSize: isCompact ? 11 : 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(
                            color: AutoBattlePalette.ink,
                            thickness: 1,
                            height: 1,
                            indent: 16,
                            endIndent: 16),
                        Expanded(
                          child: ListView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            children: grouped.entries.map((entry) {
                              final info = _categoryInfo[entry.key];
                              final achievements = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedCategory == 'all')
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 12, top: 8),
                                      child: Row(
                                        children: [
                                          Icon(info?.icon ?? Icons.star,
                                              color: info?.color ??
                                                  AutoBattlePalette.ink,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            info?.title ?? entry.key,
                                            style: TextStyle(
                                              color: AutoBattlePalette.ink,
                                              fontSize: isCompact ? 14 : 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isNarrow ? 1 : 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: isCompact ? 92 : 108,
                                    ),
                                    itemCount: achievements.length,
                                    itemBuilder: (context, i) {
                                      final ach = achievements[i];
                                      final done =
                                          metaCtrl.achievements[ach.id] == true;
                                      final progress =
                                          _AchievementProgress.from(
                                              metaCtrl, ach);
                                      return _AchievementCard(
                                        achievement: ach,
                                        completed: done,
                                        progress: progress,
                                        accentColor: info?.color ??
                                            AutoBattlePalette.ink,
                                        isCompact: isCompact,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementHeader extends StatelessWidget {
  final bool isCompact;
  const _AchievementHeader({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SketchExitButton(onTap: () => Get.back()),
        const SizedBox(width: 12),
        Transform.rotate(
          angle: -0.01,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24, vertical: isCompact ? 6 : 10),
            decoration: BoxDecoration(
              color: AutoBattlePalette.primary,
              border: Border.all(color: AutoBattlePalette.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))
              ],
            ),
            child: Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 18 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
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
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3))
          ],
        ),
        child: const Icon(Icons.arrow_back,
            color: AutoBattlePalette.ink, size: 22),
      ),
    );
  }
}

class _AchievementPageFrame extends StatelessWidget {
  final Widget child;
  final bool isCompact;
  const _AchievementPageFrame({required this.child, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5))
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _NotebookLinesPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (double y = 40; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AchievementCard extends StatelessWidget {
  final AchievementDef achievement;
  final bool completed;
  final _AchievementProgress progress;
  final Color accentColor;
  final bool isCompact;

  const _AchievementCard({
    required this.achievement,
    required this.completed,
    required this.progress,
    required this.accentColor,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: completed
            ? Colors.white
            : AutoBattlePalette.background.withValues(alpha: 0.24),
        border: Border.all(
          color: completed
              ? AutoBattlePalette.ink
              : AutoBattlePalette.ink.withValues(alpha: 0.22),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: completed
            ? [
                BoxShadow(
                  color: AutoBattlePalette.ink.withValues(alpha: 0.18),
                  offset: Offset(isCompact ? 2 : 3, isCompact ? 2 : 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 8 : 10,
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 32 : 38,
              height: isCompact ? 32 : 38,
              decoration: BoxDecoration(
                color: completed
                    ? accentColor.withValues(alpha: 0.12)
                    : Colors.white,
                border: Border.all(
                  color: completed
                      ? accentColor
                      : AutoBattlePalette.ink.withValues(alpha: 0.16),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Icon(
                  completed ? Icons.check : Icons.lock_outline,
                  color: completed
                      ? accentColor
                      : AutoBattlePalette.ink.withValues(alpha: 0.3),
                  size: isCompact ? 16 : 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: AutoBattlePalette.inkSubtle,
                      fontSize: isCompact ? 9 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.ratio,
                      minHeight: isCompact ? 5 : 6,
                      backgroundColor:
                          AutoBattlePalette.ink.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed ? accentColor : AutoBattlePalette.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.currentLabel} / ${progress.targetLabel}',
                    style: TextStyle(
                      color: AutoBattlePalette.inkSubtle,
                      fontSize: isCompact ? 8 : 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: completed
                          ? AutoBattlePalette.gold
                          : AutoBattlePalette.ink.withValues(alpha: 0.14),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '💎 ${achievement.currencyReward}',
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (completed) ...[
                  const SizedBox(height: 6),
                  Text(
                    'DONE',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSummaryStrip extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final int earnedReward;
  final int totalReward;
  final bool isCompact;

  const _AchievementSummaryStrip({
    required this.completedCount,
    required this.totalCount,
    required this.earnedReward,
    required this.totalReward,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AutoBattlePalette.background,
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.emoji_events,
              color: AutoBattlePalette.gold,
              label: '완료',
              value: '$completedCount / $totalCount',
              isCompact: isCompact,
            ),
          ),
          Container(
            width: 1,
            height: isCompact ? 26 : 30,
            color: AutoBattlePalette.ink.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.diamond,
              color: const Color(0xFF7C3AED),
              label: '보상',
              value: '$earnedReward / $totalReward',
              isCompact: isCompact,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isCompact;

  const _SummaryMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: isCompact ? 14 : 16),
        SizedBox(width: isCompact ? 6 : 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AutoBattlePalette.inkSubtle,
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AutoBattlePalette.ink,
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementProgress {
  final int current;
  final int target;
  final String currentLabel;
  final String targetLabel;

  const _AchievementProgress({
    required this.current,
    required this.target,
    required this.currentLabel,
    required this.targetLabel,
  });

  double get ratio {
    if (target <= 0) return 0;
    return (current / target).clamp(0, 1).toDouble();
  }

  factory _AchievementProgress.from(
      MetaProgressController ctrl, AchievementDef achievement) {
    final current = switch (achievement.category) {
      'kill' => ctrl.totalEnemiesKilled.value,
      'stage' => ctrl.highestStage.value,
      'boss' => ctrl.totalBossesDefeated.value,
      'damage' => ctrl.totalDamageDealt.value.round(),
      _ => 0,
    };
    return _AchievementProgress(
      current: current,
      target: achievement.threshold,
      currentLabel: _formatCount(current),
      targetLabel: _formatCount(achievement.threshold),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000) {
      final text = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
      return '${text}k';
    }
    return value.toString();
  }
}

class _AchCategoryInfo {
  final String title;
  final IconData icon;
  final Color color;

  const _AchCategoryInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}
