import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';
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
                              Icon(Icons.person, size: 18),
                              SizedBox(width: 6),
                              Text('캐릭터'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag, size: 18),
                              SizedBox(width: 6),
                              Text('정비'),
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
                              Text('영구 강화'),
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
                      _CharacterShopTab(ctrl: ctrl),
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
//  Character Shop Tab
// ─────────────────────────────────────────────
class _CharacterShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  const _CharacterShopTab({required this.ctrl});

  @override
  State<_CharacterShopTab> createState() => _CharacterShopTabState();
}

class _CharacterShopTabState extends State<_CharacterShopTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = widget.ctrl;
      final selected = kAllCharacters[_selectedIndex];
      final isUnlocked = ctrl.unlockedCharacters.contains(selected.id);
      final isSelected = ctrl.selectedCharacter.value == selected.id;
      final canAfford = ctrl.currency.value >= selected.price;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          children: [
            // Character Selection Grid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '플레이어 캐릭터 선택',
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(kAllCharacters.length, (i) {
                      final char = kAllCharacters[i];
                      final unlocked = ctrl.unlockedCharacters.contains(char.id);
                      final active = ctrl.selectedCharacter.value == char.id;
                      final viewing = i == _selectedIndex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: viewing ? const Color(0xFFF1F5F9) : Colors.white,
                            border: Border.all(
                              color: viewing ? AutoBattlePalette.primary : AutoBattlePalette.ink,
                              width: viewing ? 4 : 2.5,
                            ),
                            boxShadow: viewing ? null : const [
                              BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: CharacterBallPreview(
                                  info: charDisplayInfoMap[char.shape] ??
                                      charDisplayInfoMap['circle']!,
                                  size: 60,
                                ),
                              ),
                              if (active)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                ),
                              if (!unlocked)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 24),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Character Detail
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AutoBattlePalette.surfaceLight,
                          border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                        ),
                        child: Center(
                          child: CharacterBallPreview(
                            info: charDisplayInfoMap[selected.shape] ??
                                charDisplayInfoMap['circle']!,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.title,
                              style: const TextStyle(
                                color: AutoBattlePalette.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '특성: ${selected.trait}',
                              style: const TextStyle(
                                color: AutoBattlePalette.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AutoBattlePalette.ink, thickness: 1.5),
                  const SizedBox(height: 12),
                  Text(
                    selected.description,
                    style: const TextStyle(
                      color: AutoBattlePalette.inkSubtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '능력치 보너스',
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatBonusRow(label: 'HP 보너스', value: selected.hpBonus, unit: ''),
                  _StatBonusRow(label: '공격력 보너스', value: selected.atkBonus, unit: ''),
                  _StatBonusRow(label: '방어력 보너스', value: selected.defBonus, unit: ''),
                  _StatBonusRow(label: '속도 보너스', value: selected.speedBonus, unit: ''),
                  const SizedBox(height: 24),
                  
                  // Action Button
                  GestureDetector(
                    onTap: isUnlocked 
                      ? (isSelected ? null : () => ctrl.selectCharacter(selected.id))
                      : (canAfford ? () => ctrl.buyCharacter(selected) : null),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isUnlocked 
                          ? (isSelected ? const Color(0xFF4CAF50) : AutoBattlePalette.secondary)
                          : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)),
                        border: Border.all(color: AutoBattlePalette.ink, width: 3),
                        boxShadow: isSelected ? null : const [
                          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isUnlocked 
                            ? (isSelected ? '현재 선택됨' : '선택하기')
                            : '💎 ${selected.price} 구매하기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

class _StatBonusRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  const _StatBonusRow({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isZero = value == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AutoBattlePalette.text3, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(
            isZero ? '-' : '${isPositive ? "+" : ""}$value$unit',
            style: TextStyle(
              color: isZero ? AutoBattlePalette.text3 : (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
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
                    ctrl: ctrl,
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
  final MetaProgressController ctrl;
  final VoidCallback onTap;

  const _EquipmentRow({
    required this.equipment,
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.ctrl,
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
      child: Column(
        children: [
          Row(
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
          if (unlocked && equipment.weaponType != null)
            _EquipmentUpgradeRow(equipment: equipment, ctrl: ctrl),
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
//  Equipment Upgrade Row (Inside Equipment Tab for Weapons)
// ─────────────────────────────────────────────
class _EquipmentUpgradeRow extends StatelessWidget {
  final EquipmentShopDef equipment;
  final MetaProgressController ctrl;

  const _EquipmentUpgradeRow({required this.equipment, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (equipment.weaponType == null) return const SizedBox.shrink();

    return Obx(() {
      final level = ctrl.getWeaponLevel(equipment.weaponType!);
      final cost = ctrl.getWeaponUpgradeCost(equipment.weaponType!);
      final canAfford = ctrl.currency.value >= cost;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AutoBattlePalette.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              'LV.$level 공격력 강화',
              style: const TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: canAfford ? () => ctrl.upgradeWeapon(equipment.weaponType!) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford ? AutoBattlePalette.primary : Colors.grey,
                  border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                ),
                child: Text(
                  '강화 💎$cost',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
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
