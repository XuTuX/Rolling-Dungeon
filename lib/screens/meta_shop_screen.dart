import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Persistent meta-shop accessible from HomeScreen.
/// Buy weapons & view achievements using currency earned from achievements.
class MetaShopScreen extends StatefulWidget {
  const MetaShopScreen({super.key});

  @override
  State<MetaShopScreen> createState() => _MetaShopScreenState();
}

class _MetaShopScreenState extends State<MetaShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

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
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      _SketchButton(
                        onTap: () => Get.back(),
                        width: 44,
                        height: 40,
                        child: const Icon(Icons.arrow_back,
                            color: AutoBattlePalette.ink, size: 22),
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
                const SizedBox(height: 12),

                // ── Tab Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AutoBattlePalette.primary,
                      indicatorWeight: 4,
                      labelColor: AutoBattlePalette.ink,
                      unselectedLabelColor: AutoBattlePalette.text3,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 18),
                              SizedBox(width: 6),
                              Text('무기 상점'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.backpack, size: 18),
                              SizedBox(width: 6),
                              Text('장비'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upgrade, size: 18),
                              SizedBox(width: 6),
                              Text('강화'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events, size: 18),
                              SizedBox(width: 6),
                              Text('업적'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab Content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _WeaponShopTab(ctrl: ctrl),
                      _EquipmentShopTab(ctrl: ctrl),
                      _StatUpgradeTab(ctrl: ctrl),
                      _AchievementTab(ctrl: ctrl),
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

// ─────────────────────────────────────────────
//  Weapon Shop Tab
// ─────────────────────────────────────────────
class _WeaponShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  const _WeaponShopTab({required this.ctrl});

  @override
  State<_WeaponShopTab> createState() => _WeaponShopTabState();
}

class _WeaponShopTabState extends State<_WeaponShopTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = widget.ctrl;
      final ownedCount = kAllShopWeapons
          .where((w) => ctrl.unlockedWeapons.contains(w.weaponType))
          .length;

      final selected = kAllShopWeapons[_selectedIndex];
      final selOwned = ctrl.unlockedWeapons.contains(selected.weaponType);
      final selCanAfford = ctrl.currency.value >= selected.price;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Weapon icon grid (compact Wrap) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                ],
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(kAllShopWeapons.length, (i) {
                  final w = kAllShopWeapons[i];
                  final owned = ctrl.unlockedWeapons.contains(w.weaponType);
                  final isSelected = i == _selectedIndex;
                  return _WeaponIconTile(
                    weapon: w,
                    owned: owned,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = i),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // ── Selected weapon detail ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selOwned ? const Color(0xFFE8F5E9) : Colors.white,
                border: Border.all(
                  color: selOwned
                      ? const Color(0xFF4CAF50)
                      : AutoBattlePalette.ink,
                  width: 2.5,
                ),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(selected.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.title,
                              style: const TextStyle(
                                color: AutoBattlePalette.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected.description,
                              style: const TextStyle(
                                color: AutoBattlePalette.inkSubtle,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Buy / Upgrade button
                  Builder(builder: (context) {
                    final level = ctrl.getWeaponLevel(selected.weaponType);
                    final upgradeCost = ctrl.getWeaponUpgradeCost(selected);
                    final canAffordUpgrade = ctrl.currency.value >= upgradeCost;

                    return GestureDetector(
                      onTap: selOwned
                          ? (canAffordUpgrade
                              ? () => ctrl.upgradeWeapon(selected)
                              : null)
                          : (selCanAfford
                              ? () => ctrl.buyWeapon(selected)
                              : null),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selOwned
                              ? (canAffordUpgrade
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF9CA3AF))
                              : (selCanAfford
                                  ? AutoBattlePalette.gold
                                  : const Color(0xFF9CA3AF)),
                          border: Border.all(
                              color: AutoBattlePalette.ink, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                                color: AutoBattlePalette.ink,
                                offset: Offset(2, 2)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            selOwned
                                ? (canAffordUpgrade
                                    ? '💎 $upgradeCost  LV.${level + 1} 강화하기'
                                    : '💎 $upgradeCost  크리스탈 부족 (LV.$level)')
                                : (selCanAfford
                                    ? '💎 ${selected.price}  구매하기'
                                    : '💎 ${selected.price}  크리스탈 부족'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Owned count ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AutoBattlePalette.surfaceLight,
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2,
                      color: AutoBattlePalette.ink, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '보유 $ownedCount / ${kAllShopWeapons.length}',
                    style: const TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '기본 무기: 거너',
                    style: TextStyle(
                      color: AutoBattlePalette.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _EquipmentShopTab extends StatelessWidget {
  final MetaProgressController ctrl;

  const _EquipmentShopTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<EquipmentShopDef>>{};
    for (final equipment in kAllEquipment) {
      grouped.putIfAbsent(equipment.slot, () => []).add(equipment);
    }

    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: kEquipmentSlotLabels.entries.map((slotEntry) {
          final items = grouped[slotEntry.key] ?? const <EquipmentShopDef>[];
          final equipped = ctrl.equippedDefForSlot(slotEntry.key);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(
                      bottom:
                          BorderSide(color: AutoBattlePalette.ink, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2,
                          color: AutoBattlePalette.ink, size: 17),
                      const SizedBox(width: 8),
                      Text(
                        slotEntry.value,
                        style: const TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        equipped == null
                            ? '미장착'
                            : '${equipped.icon} ${equipped.title}',
                        style: const TextStyle(
                          color: AutoBattlePalette.text3,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                ...items.map((equipment) {
                  final unlocked =
                      ctrl.unlockedEquipment.contains(equipment.id);
                  final isEquipped =
                      ctrl.equippedEquipment[equipment.slot] == equipment.id;
                  final canAfford = ctrl.currency.value >= equipment.price;
                  return _EquipmentRow(
                    equipment: equipment,
                    unlocked: unlocked,
                    equipped: isEquipped,
                    canAfford: canAfford,
                    onTap: () {
                      if (unlocked) {
                        ctrl.equipEquipment(equipment);
                      } else {
                        ctrl.buyEquipment(equipment);
                      }
                    },
                  );
                }),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _EquipmentRow extends StatelessWidget {
  final EquipmentShopDef equipment;
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final VoidCallback onTap;

  const _EquipmentRow({
    required this.equipment,
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = equipped
        ? const Color(0xFF4CAF50)
        : (unlocked
            ? AutoBattlePalette.secondary
            : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)));
    final buttonText =
        equipped ? '장착중' : (unlocked ? '장착' : (canAfford ? '구매' : '부족'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: equipped
            ? const Color(0xFFE8F5E9)
            : AutoBattlePalette.ink.withValues(alpha: 0.0),
        border: Border(
          bottom: BorderSide(
            color: AutoBattlePalette.ink.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: AutoBattlePalette.ink, width: 2),
            ),
            child: Text(equipment.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.title,
                  style: const TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  equipment.description,
                  style: const TextStyle(
                    color: AutoBattlePalette.text3,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (equipment.statSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    equipment.statSummary,
                    style: const TextStyle(
                      color: AutoBattlePalette.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: equipped ? null : onTap,
            child: Container(
              width: 70,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: buttonColor,
                border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                boxShadow: equipped
                    ? null
                    : const [
                        BoxShadow(
                          color: AutoBattlePalette.ink,
                          offset: Offset(2, 2),
                        ),
                      ],
              ),
              child: Text(
                unlocked ? buttonText : '$buttonText\n💎 ${equipment.price}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Achievement Tab
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
//  Stat Upgrade Tab
// ─────────────────────────────────────────────
class _StatUpgradeTab extends StatelessWidget {
  final MetaProgressController ctrl;
  const _StatUpgradeTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: kAllStatUpgrades.length,
      itemBuilder: (context, index) {
        final def = kAllStatUpgrades[index];
        return Obx(() {
          final level = ctrl.getStatLevel(def.statType);
          final cost = ctrl.getStatUpgradeCost(def);
          final canAfford = ctrl.currency.value >= cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutoBattlePalette.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AutoBattlePalette.background,
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                  ),
                  child: Text(def.icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${def.title} (Lv.$level)',
                        style: const TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        def.description,
                        style: const TextStyle(
                          color: AutoBattlePalette.text3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Upgrade Button
                _SketchButton(
                  onTap: () {
                    ctrl.upgradeStat(def);
                  },
                  width: 80,
                  height: 44,
                  color:
                      canAfford ? AutoBattlePalette.gold : Colors.grey.shade300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '강화',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '💎 $cost',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _AchievementTab extends StatelessWidget {
  final MetaProgressController ctrl;
  const _AchievementTab({required this.ctrl});

  static const _categoryInfo = <String, _AchCategoryInfo>{
    'kill': _AchCategoryInfo(
      title: '처치',
      icon: Icons.my_location,
      color: AutoBattlePalette.primary,
    ),
    'stage': _AchCategoryInfo(
      title: '탐험',
      icon: Icons.explore,
      color: AutoBattlePalette.secondary,
    ),
    'boss': _AchCategoryInfo(
      title: '보스',
      icon: Icons.shield,
      color: Color(0xFF7C3AED),
    ),
    'damage': _AchCategoryInfo(
      title: '피해',
      icon: Icons.whatshot,
      color: AutoBattlePalette.gold,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completedCount =
          kAllAchievements.where((a) => ctrl.achievements[a.id] == true).length;
      final totalReward =
          kAllAchievements.fold<int>(0, (sum, a) => sum + a.currencyReward);
      final earnedReward = kAllAchievements
          .where((a) => ctrl.achievements[a.id] == true)
          .fold<int>(0, (sum, a) => sum + a.currencyReward);

      // Group achievements by category
      final grouped = <String, List<AchievementDef>>{};
      for (final a in kAllAchievements) {
        grouped.putIfAbsent(a.category, () => []).add(a);
      }

      return Column(
        children: [
          // Progress summary banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AutoBattlePalette.surfaceLight,
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AutoBattlePalette.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '완료: $completedCount / ${kAllAchievements.length}',
                    style: const TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '💎 $earnedReward / $totalReward',
                    style: const TextStyle(
                      color: AutoBattlePalette.inkSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category-grouped list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: grouped.entries.map((entry) {
                final info = _categoryInfo[entry.key];
                final achievements = entry.value;
                final categoryCompleted = achievements
                    .where((a) => ctrl.achievements[a.id] == true)
                    .length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                            color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (info?.color ?? AutoBattlePalette.ink)
                                .withValues(alpha: 0.1),
                            border: const Border(
                              bottom: BorderSide(
                                  color: AutoBattlePalette.ink, width: 2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(info?.icon ?? Icons.star,
                                  color: info?.color ?? AutoBattlePalette.ink,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                info?.title ?? entry.key,
                                style: TextStyle(
                                  color: info?.color ?? AutoBattlePalette.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (info?.color ?? AutoBattlePalette.ink)
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                      color:
                                          info?.color ?? AutoBattlePalette.ink,
                                      width: 1.5),
                                ),
                                child: Text(
                                  '$categoryCompleted / ${achievements.length}',
                                  style: TextStyle(
                                    color: info?.color ?? AutoBattlePalette.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Achievement items
                        ...achievements.map((ach) {
                          final done = ctrl.achievements[ach.id] == true;
                          return _AchievementRow(
                            achievement: ach,
                            completed: done,
                            accentColor: info?.color ?? AutoBattlePalette.ink,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────
//  Weapon Icon Tile (small fixed-size)
// ─────────────────────────────────────────────
class _WeaponIconTile extends StatelessWidget {
  final WeaponShopDef weapon;
  final bool owned;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeaponIconTile({
    required this.weapon,
    required this.owned,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    if (isSelected) {
      bg = owned ? const Color(0xFFC8E6C9) : const Color(0xFFFFF3E0);
      border = owned ? const Color(0xFF4CAF50) : AutoBattlePalette.gold;
    } else {
      bg = owned ? const Color(0xFFE8F5E9) : Colors.white;
      border = owned
          ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
          : AutoBattlePalette.ink.withValues(alpha: 0.25);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: border,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: 0.4),
                    offset: const Offset(2, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(weapon.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 1),
            if (owned)
              Obx(() {
                final level = Get.find<MetaProgressController>()
                    .getWeaponLevel(weapon.weaponType);
                return Text(
                  'LV.$level',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                );
              })
            else
              Text(
                '💎${weapon.price}',
                style: const TextStyle(
                  color: AutoBattlePalette.text3,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Achievement Row
// ─────────────────────────────────────────────
class _AchievementRow extends StatelessWidget {
  final AchievementDef achievement;
  final bool completed;
  final Color accentColor;

  const _AchievementRow({
    required this.achievement,
    required this.completed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed
            ? accentColor.withValues(alpha: 0.06)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AutoBattlePalette.ink.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed
                  ? accentColor
                  : AutoBattlePalette.ink.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: completed
                    ? accentColor
                    : AutoBattlePalette.ink.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),

          // Title + Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: completed
                        ? AutoBattlePalette.inkSubtle
                        : AutoBattlePalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AutoBattlePalette.text3,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Reward badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: completed
                  ? accentColor.withValues(alpha: 0.15)
                  : const Color(0xFFF3F4F6),
              border: Border.all(
                color: completed
                    ? accentColor
                    : AutoBattlePalette.ink.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Text(
              '💎 ${achievement.currencyReward}',
              style: TextStyle(
                color: completed ? accentColor : AutoBattlePalette.text3,
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

// ─────────────────────────────────────────────
//  Reusable Sketch Button
// ─────────────────────────────────────────────
class _SketchButton extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final double height;
  final Widget child;
  final Color color;

  const _SketchButton({
    required this.onTap,
    required this.width,
    required this.height,
    required this.child,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Achievement Category Info
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
//  Shop Background Painter
// ─────────────────────────────────────────────
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
