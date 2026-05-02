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

class _MetaShopScreenState extends State<MetaShopScreen> {
  int _currentTab = 0;

  final List<_ShopTabDef> _tabs = [
    _ShopTabDef(title: '캐릭터', icon: Icons.person, color: AutoBattlePalette.primary),
    _ShopTabDef(title: '무기/장비', icon: Icons.shopping_bag, color: AutoBattlePalette.secondary),
    _ShopTabDef(title: '능력치', icon: Icons.upgrade, color: AutoBattlePalette.gold),
    _ShopTabDef(title: '업적', icon: Icons.emoji_events, color: const Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MetaProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShopBgPainter())),
          SafeArea(
            child: Row(
              children: [
                // ── Sidebar Navigation ──
                Container(
                  width: 110,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AutoBattlePalette.ink, width: 4),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Back Button
                      _SidebarIconButton(
                        onTap: () => Get.back(),
                        icon: Icons.arrow_back,
                        color: AutoBattlePalette.ink,
                      ),
                      const SizedBox(height: 32),
                      // Tab Icons
                      Expanded(
                        child: ListView.separated(
                          itemCount: _tabs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder: (context, index) {
                            final tab = _tabs[index];
                            final isSelected = _currentTab == index;
                            return _SidebarTabButton(
                              isSelected: isSelected,
                              icon: tab.icon,
                              label: tab.title,
                              accentColor: tab.color,
                              onTap: () => setState(() => _currentTab = index),
                            );
                          },
                        ),
                      ),
                      // Currency display at bottom of sidebar
                      Obx(() => _CurrencyBox(amount: ctrl.currency.value)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // ── Main Content Area ──
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      _ContentHeader(title: _tabs[_currentTab].title, color: _tabs[_currentTab].color),
                      // Tab View with smooth transition
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildCurrentTab(ctrl),
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

  Widget _buildCurrentTab(MetaProgressController ctrl) {
    switch (_currentTab) {
      case 0: return _CharacterShopTab(key: const ValueKey(0), ctrl: ctrl);
      case 1: return _EquipmentShopTab(key: const ValueKey(1), ctrl: ctrl);
      case 2: return _StatUpgradeTab(key: const ValueKey(2), ctrl: ctrl);
      case 3: return _AchievementTab(key: const ValueKey(3), ctrl: ctrl);
      default: return const SizedBox.shrink();
    }
  }
}

class _ShopTabDef {
  final String title;
  final IconData icon;
  final Color color;
  _ShopTabDef({required this.title, required this.icon, required this.color});
}

class _SidebarIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _SidebarIconButton({required this.onTap, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _SidebarTabButton extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _SidebarTabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: isSelected
              ? null
              : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AutoBattlePalette.ink,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AutoBattlePalette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyBox extends StatelessWidget {
  final int amount;
  const _CurrencyBox({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AutoBattlePalette.gold,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        children: [
          const Text('💎', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            '$amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _ContentHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutoBattlePalette.ink, width: 4),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
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
  const _CharacterShopTab({super.key, required this.ctrl});

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

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Character Selection List (Left) ──
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 24),
              child: Container(
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
                      '캐릭터 목록',
                      style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: kAllCharacters.length,
                      itemBuilder: (context, i) {
                        final char = kAllCharacters[i];
                        final unlocked = ctrl.unlockedCharacters.contains(char.id);
                        final active = ctrl.selectedCharacter.value == char.id;
                        final viewing = i == _selectedIndex;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Container(
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
                                    size: 44,
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
                                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                                    ),
                                  ),
                                if (!unlocked)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Character Detail (Right) ──
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 24),
              child: Container(
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.surfaceLight,
                            border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                          ),
                          child: Center(
                            child: CharacterBallPreview(
                              info: charDisplayInfoMap[selected.shape] ??
                                  charDisplayInfoMap['circle']!,
                              size: 100,
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AutoBattlePalette.secondary.withValues(alpha: 0.1),
                                  border: Border.all(color: AutoBattlePalette.secondary, width: 1.5),
                                ),
                                child: Text(
                                  selected.trait,
                                  style: const TextStyle(
                                    color: AutoBattlePalette.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AutoBattlePalette.ink, thickness: 2),
                    const SizedBox(height: 16),
                    Text(
                      selected.description,
                      style: const TextStyle(
                        color: AutoBattlePalette.inkSubtle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '기본 능력치 보너스',
                      style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AutoBattlePalette.background.withValues(alpha: 0.5),
                        border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _StatBonusRow(label: 'HP 보너스', value: selected.hpBonus, icon: Icons.favorite, color: Colors.red),
                          _StatBonusRow(label: '공격력 보너스', value: selected.atkBonus, icon: Icons.bolt, color: Colors.orange),
                          _StatBonusRow(label: '방어력 보너스', value: selected.defBonus, icon: Icons.shield, color: Colors.blue),
                          _StatBonusRow(label: '속도 보너스', value: selected.speedBonus, icon: Icons.speed, color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Button
                    _SketchButton(
                      onTap: isUnlocked 
                        ? (isSelected ? null : () => ctrl.selectCharacter(selected.id))
                        : (canAfford ? () => ctrl.buyCharacter(selected) : null),
                      width: double.infinity,
                      height: 56,
                      color: isUnlocked 
                        ? (isSelected ? const Color(0xFF4CAF50) : AutoBattlePalette.secondary)
                        : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)),
                      child: Text(
                        isUnlocked 
                          ? (isSelected ? '현재 선택됨' : '선택하기')
                          : '💎 ${selected.price} 구매하기',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _StatBonusRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  const _StatBonusRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isZero = value == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AutoBattlePalette.text3, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            isZero ? '-' : '${isPositive ? "+" : ""}$value',
            style: TextStyle(
              color: isZero ? AutoBattlePalette.text3 : (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  const _EquipmentShopTab({super.key, required this.ctrl});

  @override
  State<_EquipmentShopTab> createState() => _EquipmentShopTabState();
}

class _EquipmentShopTabState extends State<_EquipmentShopTab> {
  String _selectedSlot = 'weapon';

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<EquipmentShopDef>>{};
    for (final equipment in kAllEquipment) {
      grouped.putIfAbsent(equipment.slot, () => []).add(equipment);
    }

    return Obx(() {
      final items = grouped[_selectedSlot] ?? const <EquipmentShopDef>[];
      
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Slot Selection Sidebar (Sub-navigation) ──
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AutoBattlePalette.ink, width: 2)),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: kEquipmentSlotLabels.entries.map((slotEntry) {
                final isSelected = _selectedSlot == slotEntry.key;
                final equipped = widget.ctrl.equippedDefForSlot(slotEntry.key);
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slotEntry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AutoBattlePalette.secondary : Colors.white,
                      border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                      boxShadow: isSelected ? null : const [
                        BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          slotEntry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AutoBattlePalette.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (equipped != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            equipped.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Item Grid ──
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180, // Fixed height for rows
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final equipment = items[i];
                final unlocked = widget.ctrl.unlockedEquipment.contains(equipment.id);
                final isEquipped = widget.ctrl.equippedEquipment[equipment.slot] == equipment.id;
                final canAfford = widget.ctrl.currency.value >= equipment.price;

                return _EquipmentCard(
                  equipment: equipment,
                  unlocked: unlocked,
                  equipped: isEquipped,
                  canAfford: canAfford,
                  ctrl: widget.ctrl,
                  onTap: () {
                    if (unlocked) {
                      widget.ctrl.equipEquipment(equipment);
                    } else {
                      widget.ctrl.buyEquipment(equipment);
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentShopDef equipment;
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final MetaProgressController ctrl;
  final VoidCallback onTap;

  const _EquipmentCard({
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
    final buttonText = equipped ? '장착중' : (unlocked ? '장착' : '구매');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header / Icon
          Expanded(
            child: Container(
              width: double.infinity,
              color: AutoBattlePalette.surfaceLight,
              child: Stack(
                children: [
                  Center(child: Text(equipment.icon, style: const TextStyle(fontSize: 40))),
                  if (equipped)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFF4CAF50),
                        child: const Text('EQUIPPED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AutoBattlePalette.ink, thickness: 2),
          // Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  equipment.title,
                  style: const TextStyle(color: AutoBattlePalette.ink, fontSize: 13, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  equipment.statSummary,
                  style: const TextStyle(color: AutoBattlePalette.secondary, fontSize: 10, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: equipped ? null : onTap,
                  child: Container(
                    height: 34,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      border: Border.all(color: AutoBattlePalette.ink, width: 2),
                    ),
                    child: Text(
                      unlocked ? buttonText : '💎 ${equipment.price} $buttonText',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked && equipment.weaponType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _EquipmentUpgradeRow(equipment: equipment, ctrl: ctrl),
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
  const _StatUpgradeTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 100,
      ),
      itemCount: kAllStatUpgrades.length,
      itemBuilder: (context, index) {
        final def = kAllStatUpgrades[index];
        return Obx(() {
          final level = ctrl.getStatLevel(def.statType);
          final cost = ctrl.getStatUpgradeCost(def);
          final canAfford = ctrl.currency.value >= cost;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutoBattlePalette.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AutoBattlePalette.background,
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                  ),
                  child: Text(def.icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${def.title} (Lv.$level)',
                        style: const TextStyle(color: AutoBattlePalette.ink, fontSize: 14, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        def.description,
                        style: const TextStyle(color: AutoBattlePalette.text3, fontSize: 10, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SketchButton(
                  onTap: () => ctrl.upgradeStat(def),
                  width: 64,
                  height: 40,
                  color: canAfford ? AutoBattlePalette.gold : const Color(0xFFE5E7EB),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('강화', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      Text('💎$cost', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
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
  const _AchievementTab({super.key, required this.ctrl});

  static const _categoryInfo = <String, _AchCategoryInfo>{
    'kill': _AchCategoryInfo(title: '처치', icon: Icons.my_location, color: AutoBattlePalette.primary),
    'stage': _AchCategoryInfo(title: '탐험', icon: Icons.explore, color: AutoBattlePalette.secondary),
    'boss': _AchCategoryInfo(title: '보스', icon: Icons.shield, color: Color(0xFF7C3AED)),
    'damage': _AchCategoryInfo(title: '피해', icon: Icons.whatshot, color: AutoBattlePalette.gold),
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completedCount = kAllAchievements.where((a) => ctrl.achievements[a.id] == true).length;
      final earnedReward = kAllAchievements.where((a) => ctrl.achievements[a.id] == true).fold<int>(0, (sum, a) => sum + a.currencyReward);
      final totalReward = kAllAchievements.fold<int>(0, (sum, a) => sum + a.currencyReward);

      final grouped = <String, List<AchievementDef>>{};
      for (final a in kAllAchievements) {
        grouped.putIfAbsent(a.category, () => []).add(a);
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AutoBattlePalette.surfaceLight,
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
                boxShadow: const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AutoBattlePalette.gold, size: 18),
                  const SizedBox(width: 8),
                  Text('진행도: $completedCount / ${kAllAchievements.length}', style: const TextStyle(color: AutoBattlePalette.ink, fontSize: 13, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('💎 보상 획득: $earnedReward / $totalReward', style: const TextStyle(color: AutoBattlePalette.inkSubtle, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: grouped.entries.map((entry) {
                final info = _categoryInfo[entry.key];
                final achievements = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        info?.title ?? entry.key,
                        style: TextStyle(color: info?.color ?? AutoBattlePalette.ink, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 64,
                      ),
                      itemCount: achievements.length,
                      itemBuilder: (context, i) {
                        final ach = achievements[i];
                        final done = ctrl.achievements[ach.id] == true;
                        return _AchievementRow(
                          achievement: ach,
                          completed: done,
                          accentColor: info?.color ?? AutoBattlePalette.ink,
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
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Widget child;
  final Color color;

  const _SketchButton({
    this.onTap,
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
