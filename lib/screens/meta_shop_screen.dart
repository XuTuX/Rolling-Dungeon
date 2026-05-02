import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MetaProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final isCompact = h < 500;

            return Row(
              children: [
                // ── Sidebar Navigation ──
                Container(
                  width: isCompact ? 100 : 120,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AutoBattlePalette.ink, width: 4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: isCompact ? 8 : 16),
                        child: _SidebarIconButton(
                          onTap: () => Get.back(),
                          icon: Icons.arrow_back,
                          color: AutoBattlePalette.ink,
                          size: isCompact ? 40 : 54,
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(_tabs.length, (index) {
                                final tab = _tabs[index];
                                final isSelected = _currentTab == index;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  child: _SidebarTabButton(
                                    isSelected: isSelected,
                                    icon: tab.icon,
                                    label: tab.title,
                                    accentColor: tab.color,
                                    onTap: () => setState(() => _currentTab = index),
                                    isCompact: isCompact,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Obx(() => _CurrencyBox(amount: ctrl.currency.value, isCompact: isCompact)),
                      ),
                    ],
                  ),
                ),

                // ── Main Content Area ──
                Expanded(
                  child: Column(
                    children: [
                      _ShopHeader(
                        title: _tabs[_currentTab].title,
                        isCompact: isCompact,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 12 : 24, 
                            0, 
                            isCompact ? 12 : 24, 
                            isCompact ? 12 : 24
                          ),
                          child: _buildCurrentTab(ctrl, isCompact),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentTab(MetaProgressController ctrl, bool isCompact) {
    switch (_currentTab) {
      case 0: return _CharacterShopTab(key: const ValueKey(0), ctrl: ctrl, isCompact: isCompact);
      case 1: return _EquipmentShopTab(key: const ValueKey(1), ctrl: ctrl, isCompact: isCompact);
      case 2: return _StatUpgradeTab(key: const ValueKey(2), ctrl: ctrl, isCompact: isCompact);
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
  final double size;

  const _SidebarIconButton({
    required this.onTap, 
    required this.icon, 
    required this.color,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
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

  final bool isCompact;

  const _SidebarTabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: isCompact ? 2.5 : 3),
          boxShadow: isSelected
              ? null
              : [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AutoBattlePalette.ink,
              size: isCompact ? 28 : 32,
            ),
            const SizedBox(height: 6),
            Text(
              label,
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
  }
}

class _CurrencyBox extends StatelessWidget {
  final int amount;
  final bool isCompact;
  const _CurrencyBox({required this.amount, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AutoBattlePalette.ink, 
            offset: Offset(isCompact ? 2 : 3, isCompact ? 2 : 3)
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💎', style: TextStyle(fontSize: isCompact ? 14 : 18)),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount.toString(),
                style: TextStyle(
                  color: AutoBattlePalette.ink,
                  fontSize: isCompact ? 14 : 18,
                  fontWeight: FontWeight.w900,
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
//  Character Shop Tab
// ─────────────────────────────────────────────
class _CharacterShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  const _CharacterShopTab({super.key, required this.ctrl, required this.isCompact});

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

      return _ShopPage(
        isCompact: widget.isCompact,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: Character Selection ──
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AutoBattlePalette.ink, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT CHARACTER',
                      style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: widget.isCompact ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.isCompact ? 3 : 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: viewing ? AutoBattlePalette.surfaceLight : Colors.white,
                                border: Border.all(
                                  color: viewing ? AutoBattlePalette.primary : AutoBattlePalette.ink,
                                  width: viewing ? 3 : 2,
                                ),
                                boxShadow: viewing ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: CharacterBallPreview(
                                      info: charDisplayInfoMap[char.shape] ?? charDisplayInfoMap['circle']!,
                                      size: widget.isCompact ? 32 : 44,
                                    ),
                                  ),
                                  if (active)
                                    Positioned(
                                      top: 4, right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                                        child: const Icon(Icons.check, color: Colors.white, size: 8),
                                      ),
                                    ),
                                  if (!unlocked)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      child: const Center(child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 16)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ── Right: Character Detail ──
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(widget.isCompact ? 10 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: widget.isCompact ? 50 : 80,
                          height: widget.isCompact ? 50 : 80,
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.surfaceLight,
                            border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                          ),
                          child: Center(
                            child: CharacterBallPreview(
                              info: charDisplayInfoMap[selected.shape] ?? charDisplayInfoMap['circle']!,
                              size: widget.isCompact ? 40 : 100,
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
                                style: TextStyle(
                                  color: AutoBattlePalette.ink,
                                  fontSize: widget.isCompact ? 18 : 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AutoBattlePalette.secondary.withValues(alpha: 0.1),
                                  border: Border.all(color: AutoBattlePalette.secondary, width: 1.5),
                                ),
                                child: Text(
                                  selected.trait,
                                  style: const TextStyle(color: AutoBattlePalette.secondary, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AutoBattlePalette.ink, thickness: 2),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AutoBattlePalette.background.withValues(alpha: 0.5),
                                border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  _StatBonusRow(label: 'HP', value: selected.hpBonus, icon: Icons.favorite, color: Colors.red, isCompact: widget.isCompact),
                                  _StatBonusRow(label: 'ATK', value: selected.atkBonus, icon: Icons.bolt, color: Colors.orange, isCompact: widget.isCompact),
                                  _StatBonusRow(label: 'DEF', value: selected.defBonus, icon: Icons.shield, color: Colors.blue, isCompact: widget.isCompact),
                                  _StatBonusRow(label: 'SPD', value: selected.speedBonus, icon: Icons.speed, color: Colors.green, isCompact: widget.isCompact),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _SketchButton(
                      onTap: isUnlocked 
                        ? (isSelected ? null : () => ctrl.selectCharacter(selected.id))
                        : (canAfford ? () => ctrl.buyCharacter(selected) : null),
                      isCompact: widget.isCompact,
                      color: isUnlocked 
                        ? (isSelected ? const Color(0xFF4CAF50) : AutoBattlePalette.secondary)
                        : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)),
                      child: Text(
                        isUnlocked 
                          ? (isSelected ? 'EQUIPPED' : 'SELECT')
                          : '💎 ${selected.price} BUY',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
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
  final IconData icon;
  final Color color;
  final bool isCompact;

  const _StatBonusRow({
    required this.label, 
    required this.value, 
    required this.icon, 
    required this.color,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isZero = value == 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 6),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: isCompact ? 14 : 16),
          SizedBox(width: isCompact ? 6 : 8),
          Text(label, style: TextStyle(color: AutoBattlePalette.text3, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            isZero ? '-' : '${isPositive ? "+" : ""}$value',
            style: TextStyle(
              color: isZero ? AutoBattlePalette.text3 : (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
              fontSize: isCompact ? 12 : 14,
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
  final bool isCompact;
  const _EquipmentShopTab({super.key, required this.ctrl, required this.isCompact});

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

    return _ShopPage(
      isCompact: widget.isCompact,
      child: Column(
        children: [
          // ── Horizontal Sub-nav (Top) ──
          Container(
            height: widget.isCompact ? 44 : 52,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AutoBattlePalette.ink, width: 2)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: kEquipmentSlotLabels.length,
              itemBuilder: (context, index) {
                final slotKey = kEquipmentSlotLabels.keys.elementAt(index);
                final slotLabel = kEquipmentSlotLabels[slotKey]!;
                final isSelected = _selectedSlot == slotKey;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slotKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AutoBattlePalette.secondary : Colors.white,
                      border: Border.all(color: AutoBattlePalette.ink, width: 2),
                      boxShadow: isSelected ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                    ),
                    child: Center(
                      child: Text(
                        slotLabel.split('/')[0],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AutoBattlePalette.ink,
                          fontSize: widget.isCompact ? 11 : 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ── Item Grid ──
          Expanded(
            child: Obx(() {
              // Accessing Rx variables here ensures Obx always has a listener
              final unlockedCount = widget.ctrl.unlockedEquipment.length;
              final currentCurrency = widget.ctrl.currency.value;
              
              final items = grouped[_selectedSlot] ?? const <EquipmentShopDef>[];
              
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    '항목이 없습니다.',
                    style: TextStyle(color: AutoBattlePalette.inkSubtle, fontWeight: FontWeight.w900),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: widget.isCompact ? 96 : 124,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final equipment = items[index];
                  final unlocked = widget.ctrl.unlockedEquipment.contains(equipment.id);
                  final isEquipped = widget.ctrl.equippedEquipment[equipment.slot] == equipment.id;
                  final canAfford = currentCurrency >= equipment.price;
                  
                  return _EquipmentCard(
                    equipment: equipment,
                    unlocked: unlocked,
                    equipped: isEquipped,
                    canAfford: canAfford,
                    ctrl: widget.ctrl,
                    isCompact: widget.isCompact,
                    onTap: () {
                      if (unlocked) {
                        widget.ctrl.equipEquipment(equipment);
                      } else {
                        widget.ctrl.buyEquipment(equipment);
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(EquipmentShopDef equipment) {
    final unlocked = widget.ctrl.unlockedEquipment.contains(equipment.id);
    final isEquipped = widget.ctrl.equippedEquipment[equipment.slot] == equipment.id;
    final canAfford = widget.ctrl.currency.value >= equipment.price;

    return _EquipmentCard(
      equipment: equipment,
      unlocked: unlocked,
      equipped: isEquipped,
      canAfford: canAfford,
      ctrl: widget.ctrl,
      isCompact: widget.isCompact,
      onTap: () {
        if (unlocked) {
          widget.ctrl.equipEquipment(equipment);
        } else {
          widget.ctrl.buyEquipment(equipment);
        }
      },
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentShopDef equipment;
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final MetaProgressController ctrl;
  final bool isCompact;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.ctrl,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = equipped
        ? const Color(0xFF4CAF50)
        : (unlocked
            ? AutoBattlePalette.secondary
            : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)));
    
    final accentColor = equipment.slot == 'weapon' 
        ? AutoBattlePalette.primary 
        : (equipment.slot == 'hand' ? AutoBattlePalette.secondary : AutoBattlePalette.gold);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          // Left: Icon
          Container(
            width: isCompact ? 50 : 60,
            decoration: const BoxDecoration(
              color: AutoBattlePalette.surfaceLight,
              border: Border(right: BorderSide(color: AutoBattlePalette.ink, width: 1.5)),
            ),
            child: Center(
              child: Text(equipment.icon, style: TextStyle(fontSize: isCompact ? 24 : 32)),
            ),
          ),
          
          // Right: Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        equipment.title,
                        style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        equipment.statSummary,
                        style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  
                  _SketchButton(
                    onTap: equipped ? null : onTap,
                    height: isCompact ? 24 : 28,
                    color: buttonColor,
                    isCompact: true,
                    child: Text(
                      !unlocked ? '💎${equipment.price}' : (equipped ? 'EQUIPPED' : 'SELECT'),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),

                  if (unlocked && equipment.weaponType != null)
                    _EquipmentUpgradeRow(
                      equipment: equipment, 
                      ctrl: ctrl, 
                      isCompact: isCompact
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stat Upgrade Tab
// ─────────────────────────────────────────────
class _StatUpgradeTab extends StatelessWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  const _StatUpgradeTab({super.key, required this.ctrl, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return _ShopPage(
      isCompact: isCompact,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, isCompact ? 12 : 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: isCompact ? 70 : 100,
        ),
        itemCount: kAllStatUpgrades.length,
        itemBuilder: (context, index) {
          final def = kAllStatUpgrades[index];
          return Obx(() {
            final level = ctrl.getStatLevel(def.statType);
            final cost = ctrl.getStatUpgradeCost(def);
            final canAfford = ctrl.currency.value >= cost;

            return Container(
              padding: EdgeInsets.all(isCompact ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
                boxShadow: [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 2 : 3, isCompact ? 2 : 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 36 : 48,
                    height: isCompact ? 36 : 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AutoBattlePalette.surfaceLight,
                      border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(def.icon, style: TextStyle(fontSize: isCompact ? 18 : 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.title,
                          style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'LV.$level',
                          style: TextStyle(color: AutoBattlePalette.inkSubtle, fontSize: isCompact ? 9 : 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SketchButton(
                    onTap: () => ctrl.upgradeStat(def),
                    width: isCompact ? 54 : 64,
                    height: isCompact ? 36 : 44,
                    isCompact: isCompact,
                    color: canAfford ? AutoBattlePalette.gold : const Color(0xFFE5E7EB),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('UP', style: TextStyle(color: Colors.white, fontSize: isCompact ? 9 : 11, fontWeight: FontWeight.w900)),
                        Text('💎$cost', style: TextStyle(color: Colors.white, fontSize: isCompact ? 8 : 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Equipment Upgrade Row (Inside Equipment Tab for Weapons)
// ─────────────────────────────────────────────
class _EquipmentUpgradeRow extends StatelessWidget {
  final EquipmentShopDef equipment;
  final MetaProgressController ctrl;
  final bool isCompact;

  const _EquipmentUpgradeRow({
    required this.equipment, 
    required this.ctrl,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    if (equipment.weaponType == null) return const SizedBox.shrink();

    final level = ctrl.getWeaponLevel(equipment.weaponType!);
    final cost = ctrl.getWeaponUpgradeCost(equipment.weaponType!);
    final canAfford = ctrl.currency.value >= cost;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10, 
        vertical: isCompact ? 3 : 6
      ),
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: AutoBattlePalette.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            'LV.$level 강화',
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: isCompact ? 8.5 : 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _SketchButton(
            onTap: canAfford ? () => ctrl.upgradeWeapon(equipment.weaponType!) : null,
            width: isCompact ? 56 : 64,
            height: isCompact ? 24 : 30,
            isCompact: true,
            color: canAfford ? AutoBattlePalette.primary : Colors.grey,
            child: Text(
              '💎$cost',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 8 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _ShopHeader extends StatelessWidget {
  final String title;
  final bool isCompact;
  const _ShopHeader({required this.title, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24, 
        vertical: isCompact ? 10 : 20
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.02, // Slight tilt for sketchy look
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24, 
                vertical: isCompact ? 6 : 12
              ),
              decoration: BoxDecoration(
                color: AutoBattlePalette.primary,
                border: Border.all(color: AutoBattlePalette.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 18 : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}


// ── Shared Sketchbook Page for Shop Tabs ──
class _ShopPage extends StatelessWidget {
  final Widget child;
  final bool isCompact;
  const _ShopPage({required this.child, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutoBattlePalette.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5)),
            ],
          ),
          child: Stack(
            children: [
              // Subtle notebook lines
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(painter: _NotebookLinesPainter()),
                ),
              ),
              child,
            ],
          ),
        ),
        
        // Decorative "Tape" effect
        Positioned(
          top: -10,
          left: 40,
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xAAFFFFFF),
                border: Border.all(color: AutoBattlePalette.ink.withValues(alpha: 0.1), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(1, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
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

// ─────────────────────────────────────────────
//  Reusable Sketch Button (Animated)
// ─────────────────────────────────────────────
class _SketchButton extends StatefulWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final bool isCompact;
  final double? width;
  final double? height;

  const _SketchButton({
    required this.color, 
    required this.child, 
    this.onTap,
    this.isCompact = false,
    this.width,
    this.height,
  });

  @override
  State<_SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<_SketchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height ?? (widget.isCompact ? 44 : 54),
        transform: _pressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade300 : widget.color,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: (disabled || _pressed)
            ? null 
            : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Achievement Category Info
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
//  Shop Background Painter
// ─────────────────────────────────────────────
