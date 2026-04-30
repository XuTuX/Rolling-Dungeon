import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Persistent meta-shop accessible from HomeScreen.
/// Buy weapons & view achievements using currency earned from achievements.
class MetaShopScreen extends StatelessWidget {
  const MetaShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MetaProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShopBgPainter())),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 44, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: AutoBattlePalette.ink, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: AutoBattlePalette.ink,
                                  offset: Offset(3, 3)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AutoBattlePalette.ink, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: AutoBattlePalette.ink, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: AutoBattlePalette.ink,
                                offset: Offset(4, 4)),
                          ],
                        ),
                        child: const Text(
                          'SHOP',
                          style: TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Currency display
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AutoBattlePalette.gold,
                              border: Border.all(
                                  color: AutoBattlePalette.ink, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: AutoBattlePalette.ink,
                                    offset: Offset(3, 3)),
                              ],
                            ),
                            child: Text(
                              '💎 ${ctrl.currency.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weapons section
                        _sectionTitle('무기 상점', Icons.shopping_cart),
                        const SizedBox(height: 10),
                        Obx(() => Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: kAllShopWeapons.map((w) {
                                final owned =
                                    ctrl.unlockedWeapons.contains(w.weaponType);
                                final canAfford =
                                    ctrl.currency.value >= w.price;
                                return _WeaponCard(
                                  weapon: w,
                                  owned: owned,
                                  canAfford: canAfford,
                                  onBuy: () {
                                    ctrl.buyWeapon(w);
                                  },
                                );
                              }).toList(),
                            )),
                        const SizedBox(height: 24),

                        // Achievements section
                        _sectionTitle('업적', Icons.emoji_events),
                        const SizedBox(height: 10),
                        Obx(() => Column(
                              children: kAllAchievements.map((ach) {
                                final done =
                                    ctrl.achievements[ach.id] == true;
                                return _AchievementRow(
                                  achievement: ach,
                                  completed: done,
                                );
                              }).toList(),
                            )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AutoBattlePalette.ink, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AutoBattlePalette.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WeaponCard extends StatelessWidget {
  final WeaponShopDef weapon;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _WeaponCard({
    required this.weapon,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: owned ? null : (canAfford ? onBuy : null),
      child: Container(
        width: 165,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: owned ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: owned ? const Color(0xFF4CAF50) : AutoBattlePalette.ink,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: owned
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : AutoBattlePalette.ink,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(weapon.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    weapon.title,
                    style: const TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              weapon.description,
              style: const TextStyle(
                color: AutoBattlePalette.inkSubtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: owned
                    ? const Color(0xFF4CAF50)
                    : (canAfford
                        ? AutoBattlePalette.gold
                        : const Color(0xFF9CA3AF)),
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
              ),
              child: Center(
                child: Text(
                  owned ? '✓ OWNED' : '💎 ${weapon.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final AchievementDef achievement;
  final bool completed;

  const _AchievementRow({
    required this.achievement,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFFFFBEB) : Colors.white,
        border: Border.all(
          color: completed ? AutoBattlePalette.gold : AutoBattlePalette.ink,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AutoBattlePalette.ink.withValues(alpha: completed ? 0.3 : 1),
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AutoBattlePalette.gold : AutoBattlePalette.inkSubtle,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AutoBattlePalette.inkSubtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: completed ? AutoBattlePalette.gold : const Color(0xFFE5E7EB),
              border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
            ),
            child: Text(
              '💎 ${achievement.currencyReward}',
              style: TextStyle(
                color: completed ? Colors.white : AutoBattlePalette.inkSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;
    for (var y = 28.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawLine(
      const Offset(38, 0),
      Offset(38, size.height),
      Paint()
        ..color = const Color(0xFFFF9999).withValues(alpha: 0.12)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
