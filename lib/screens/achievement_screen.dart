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
    'all': _AchCategoryInfo(title: '전체', icon: Icons.apps, color: AutoBattlePalette.ink),
    'kill': _AchCategoryInfo(title: '전투', icon: Icons.my_location, color: AutoBattlePalette.primary),
    'stage': _AchCategoryInfo(title: '모험', icon: Icons.explore, color: AutoBattlePalette.secondary),
    'boss': _AchCategoryInfo(title: '보스', icon: Icons.shield, color: Color(0xFF7C3AED)),
    'damage': _AchCategoryInfo(title: '기록', icon: Icons.whatshot, color: AutoBattlePalette.gold),
  };

  @override
  Widget build(BuildContext context) {
    final metaCtrl = Get.find<MetaProgressController>();
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 500;

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
                    final completedCount = kAllAchievements.where((a) => metaCtrl.achievements[a.id] == true).length;
                    final earnedReward = kAllAchievements.where((a) => metaCtrl.achievements[a.id] == true).fold<int>(0, (sum, a) => sum + a.currencyReward);
                    final totalReward = kAllAchievements.fold<int>(0, (sum, a) => sum + a.currencyReward);

                    final grouped = <String, List<AchievementDef>>{};
                    if (_selectedCategory == 'all') {
                      for (final a in kAllAchievements) {
                        grouped.putIfAbsent(a.category, () => []).add(a);
                      }
                    } else {
                      grouped[_selectedCategory] = kAllAchievements.where((a) => a.category == _selectedCategory).toList();
                    }

                    return Column(
                      children: [
                        // ── Achievement Summary Bar ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AutoBattlePalette.background,
                              border: Border.all(color: AutoBattlePalette.ink, width: 2),
                              boxShadow: const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, color: AutoBattlePalette.gold, size: isCompact ? 14 : 18),
                                const SizedBox(width: 8),
                                Text('업적 진행도: $completedCount / ${kAllAchievements.length}', 
                                  style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w900)),
                                const Spacer(),
                                Text('💎 $earnedReward / $totalReward', 
                                  style: TextStyle(color: AutoBattlePalette.inkSubtle, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),

                        // ── Horizontal Category Sub-nav ──
                        Container(
                          height: isCompact ? 46 : 54,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _categoryInfo.length,
                            itemBuilder: (context, index) {
                              final catKey = _categoryInfo.keys.elementAt(index);
                              final info = _categoryInfo[catKey]!;
                              final isSelected = _selectedCategory == catKey;
                              
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = catKey),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? info.color : Colors.white,
                                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                                    boxShadow: isSelected ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(info.icon, color: isSelected ? Colors.white : info.color, size: isCompact ? 14 : 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        info.title,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AutoBattlePalette.ink,
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

                        const Divider(color: AutoBattlePalette.ink, thickness: 1, height: 1, indent: 16, endIndent: 16),

                        // ── Achievement List ──
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: grouped.entries.map((entry) {
                              final info = _categoryInfo[entry.key];
                              final achievements = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedCategory == 'all')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                                      child: Row(
                                        children: [
                                          Icon(info?.icon ?? Icons.star, color: info?.color ?? AutoBattlePalette.ink, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            info?.title ?? entry.key,
                                            style: TextStyle(
                                              color: AutoBattlePalette.ink, 
                                              fontSize: 16, 
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isCompact ? 1 : 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: isCompact ? 64 : 82,
                                    ),
                                    itemCount: achievements.length,
                                    itemBuilder: (context, i) {
                                      final ach = achievements[i];
                                      final done = metaCtrl.achievements[ach.id] == true;
                                      return _AchievementCard(
                                        achievement: ach,
                                        completed: done,
                                        accentColor: info?.color ?? AutoBattlePalette.ink,
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
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24, vertical: isCompact ? 6 : 10),
            decoration: BoxDecoration(
              color: AutoBattlePalette.primary,
              border: Border.all(color: AutoBattlePalette.ink, width: 3),
              boxShadow: const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))],
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
          boxShadow: const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3))],
        ),
        child: const Icon(Icons.arrow_back, color: AutoBattlePalette.ink, size: 22),
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
        boxShadow: const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5))],
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
  final Color accentColor;
  final bool isCompact;

  const _AchievementCard({
    required this.achievement,
    required this.completed,
    required this.accentColor,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: completed ? Colors.white : AutoBattlePalette.background.withValues(alpha: 0.3),
        border: Border.all(
          color: completed ? AutoBattlePalette.ink : AutoBattlePalette.ink.withValues(alpha: 0.4),
          width: 2.5,
        ),
        boxShadow: completed ? [
          BoxShadow(
            color: AutoBattlePalette.ink,
            offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4),
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          if (completed)
            Positioned(
              right: -5,
              top: -5,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: isCompact ? 8 : 10),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 32 : 40,
                  height: isCompact ? 32 : 40,
                  decoration: BoxDecoration(
                    color: completed ? accentColor.withValues(alpha: 0.1) : Colors.white,
                    border: Border.all(
                      color: completed ? accentColor : AutoBattlePalette.ink.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      completed ? Icons.emoji_events : Icons.lock_outline,
                      color: completed ? accentColor : AutoBattlePalette.ink.withValues(alpha: 0.3),
                      size: isCompact ? 16 : 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          decoration: completed ? TextDecoration.lineThrough : null,
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
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: completed ? AutoBattlePalette.gold : AutoBattlePalette.ink.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💎', style: TextStyle(fontSize: isCompact ? 10 : 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.currencyReward}',
                        style: TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
