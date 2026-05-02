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
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AutoBattlePalette.ink, width: 4),
                    ),
                  ),
                  child: Column(
                    children: [
                      _SidebarIconButton(
                        onTap: () => Get.back(),
                        icon: Icons.arrow_back,
                        color: AutoBattlePalette.ink,
                        size: isCompact ? 44 : 54,
                      ),
                      SizedBox(height: isCompact ? 12 : 24),
                      
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_tabs.length, (index) {
                            final tab = _tabs[index];
                            final isSelected = _currentTab == index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
                      
                      Obx(() => _CurrencyBox(amount: ctrl.currency.value, isCompact: isCompact)),
                      const SizedBox(height: 8),
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
      case 3: return _AchievementTab(key: const ValueKey(3), ctrl: ctrl, isCompact: isCompact);
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
        padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: isCompact ? 2 : 3),
          boxShadow: isSelected
              ? null
              : [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4))],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AutoBattlePalette.ink,
              size: isCompact ? 24 : 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AutoBattlePalette.ink,
                fontSize: isCompact ? 10 : 13,
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
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: isCompact ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: isCompact ? 2 : 3),
        boxShadow: [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💎', style: TextStyle(fontSize: isCompact ? 14 : 20)),
          SizedBox(width: isCompact ? 4 : 10),
          Text(
            amount.toString(),
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: isCompact ? 14 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
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
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
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
                                boxShadow: viewing ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: CharacterBallPreview(
                                      info: charDisplayInfoMap[char.shape] ?? charDisplayInfoMap['circle']!,
                                      size: widget.isCompact ? 36 : 44,
                                    ),
                                  ),
                                  if (active)
                                    Positioned(
                                      top: 4, right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                                      ),
                                    ),
                                  if (!unlocked)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      child: const Center(child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 18)),
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
                padding: EdgeInsets.all(widget.isCompact ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: widget.isCompact ? 60 : 80,
                          height: widget.isCompact ? 60 : 80,
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.surfaceLight,
                            border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                          ),
                          child: Center(
                            child: CharacterBallPreview(
                              info: charDisplayInfoMap[selected.shape] ?? charDisplayInfoMap['circle']!,
                              size: widget.isCompact ? 70 : 100,
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
                                  fontSize: widget.isCompact ? 20 : 24,
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
                    const SizedBox(height: 12),
                    const Divider(color: AutoBattlePalette.ink, thickness: 2),
                    const SizedBox(height: 8),
                    // Removed selected.description as requested
                    const Spacer(),
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
                    const SizedBox(height: 16),
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

    return Obx(() {
      final items = grouped[_selectedSlot] ?? const <EquipmentShopDef>[];
      
      return _ShopPage(
        isCompact: widget.isCompact,
        child: Row(
          children: [
            // ── Sub-nav ──
            Container(
              width: widget.isCompact ? 90 : 110,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AutoBattlePalette.ink, width: 2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: kEquipmentSlotLabels.entries.map((slotEntry) {
                  final isSelected = _selectedSlot == slotEntry.key;
                  final equipped = widget.ctrl.equippedDefForSlot(slotEntry.key);
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slotEntry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AutoBattlePalette.secondary : Colors.white,
                        border: Border.all(color: AutoBattlePalette.ink, width: 2),
                        boxShadow: isSelected ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slotEntry.value.split('/')[0],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AutoBattlePalette.ink,
                              fontSize: widget.isCompact ? 10 : 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (equipped != null) ...[
                            const SizedBox(height: 2),
                            Text(equipped.icon, style: TextStyle(fontSize: widget.isCompact ? 14 : 16)),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // ── Item Grid (Fixed 2x2) ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (items.isNotEmpty) Expanded(child: _buildItemCard(items[0])),
                          const SizedBox(width: 12),
                          if (items.length > 1) Expanded(child: _buildItemCard(items[1])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          if (items.length > 2) Expanded(child: _buildItemCard(items[2])),
                          const SizedBox(width: 12),
                          if (items.length > 3) Expanded(child: _buildItemCard(items[3])),
                        ],
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
        border: Border.all(color: AutoBattlePalette.ink, width: isCompact ? 2 : 3),
        boxShadow: [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4)),
        ],
      ),
      child: Column(
        children: [
          // Header / Icon
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AutoBattlePalette.surfaceLight,
                border: Border(
                  bottom: BorderSide(color: AutoBattlePalette.ink, width: 2),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'eq_${equipment.id}',
                      child: Text(
                        equipment.icon, 
                        style: TextStyle(fontSize: isCompact ? 32 : 44)
                      ),
                    ),
                  ),
                  if (equipped)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                        ),
                        child: const Text(
                          'EQUIPPED', 
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Info Area
          Padding(
            padding: EdgeInsets.all(isCompact ? 6.0 : 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  equipment.title,
                  style: TextStyle(
                    color: AutoBattlePalette.ink, 
                    fontSize: isCompact ? 12 : 14, 
                    fontWeight: FontWeight.w900
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    equipment.statSummary,
                    style: TextStyle(
                      color: accentColor, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SketchButton(
                  onTap: equipped ? null : onTap,
                  height: isCompact ? 32 : 38,
                  color: buttonColor,
                  isCompact: isCompact,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!unlocked) ...[
                        Text('💎 ', style: TextStyle(fontSize: isCompact ? 10 : 12)),
                        Text(
                          '${equipment.price} BUY',
                          style: TextStyle(color: Colors.white, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w900),
                        ),
                      ] else ...[
                        Text(
                          equipped ? 'EQUIPPED' : 'SELECT',
                          style: TextStyle(color: Colors.white, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Upgrade Row for Weapons
          if (unlocked && equipment.weaponType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _EquipmentUpgradeRow(
                equipment: equipment, 
                ctrl: ctrl, 
                isCompact: isCompact
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
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 32 : 44,
                    height: isCompact ? 32 : 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AutoBattlePalette.background,
                      border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                    ),
                    child: Text(def.icon, style: TextStyle(fontSize: isCompact ? 16 : 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${def.title} (Lv.$level)',
                          style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 12 : 14, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SketchButton(
                    onTap: () => ctrl.upgradeStat(def),
                    width: isCompact ? 60 : 70,
                    height: isCompact ? 38 : 46,
                    isCompact: isCompact,
                    color: canAfford ? AutoBattlePalette.gold : const Color(0xFFE5E7EB),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('UP', style: TextStyle(color: Colors.white, fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.w900)),
                        Text('💎$cost', style: TextStyle(color: Colors.white, fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w700)),
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

class _AchievementTab extends StatelessWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  const _AchievementTab({super.key, required this.ctrl, required this.isCompact});

  static const _categoryInfo = <String, _AchCategoryInfo>{
    'kill': _AchCategoryInfo(title: '처치', icon: Icons.my_location, color: AutoBattlePalette.primary),
    'stage': _AchCategoryInfo(title: '탐험', icon: Icons.explore, color: AutoBattlePalette.secondary),
    'boss': _AchCategoryInfo(title: '보스', icon: Icons.shield, color: Color(0xFF7C3AED)),
    'damage': _AchCategoryInfo(title: '피해', icon: Icons.whatshot, color: AutoBattlePalette.gold),
  };

  @override
  Widget build(BuildContext context) {
    return _ShopPage(
      isCompact: isCompact,
      child: Obx(() {
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
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AutoBattlePalette.background,
                  border: Border.all(color: AutoBattlePalette.ink, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AutoBattlePalette.gold, size: isCompact ? 14 : 18),
                    const SizedBox(width: 8),
                    Text('PROGRESS: $completedCount / ${kAllAchievements.length}', style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('💎 $earnedReward / $totalReward', style: TextStyle(color: AutoBattlePalette.inkSubtle, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: isCompact ? 48 : 64,
                        ),
                        itemCount: achievements.length,
                        itemBuilder: (context, i) {
                          final ach = achievements[i];
                          final done = ctrl.achievements[ach.id] == true;
                          return _AchievementRow(
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

    return Obx(() {
      final level = ctrl.getWeaponLevel(equipment.weaponType!);
      final cost = ctrl.getWeaponUpgradeCost(equipment.weaponType!);
      final canAfford = ctrl.currency.value >= cost;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12, 
          vertical: isCompact ? 4 : 8
        ),
        margin: const EdgeInsets.only(top: 4),
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
                fontSize: isCompact ? 9 : 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _SketchButton(
              onTap: canAfford ? () => ctrl.upgradeWeapon(equipment.weaponType!) : null,
              width: isCompact ? 60 : 70,
              height: isCompact ? 28 : 34,
              isCompact: true,
              color: canAfford ? AutoBattlePalette.primary : Colors.grey,
              child: Text(
                '💎$cost',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w900,
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
  final bool isCompact;

  const _AchievementRow({
    required this.achievement,
    required this.completed,
    required this.accentColor,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: isCompact ? 6 : 10),
      decoration: BoxDecoration(
        color: completed
            ? accentColor.withValues(alpha: 0.06)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AutoBattlePalette.ink.withValues(alpha: 0.08),
            width: isCompact ? 0.5 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: isCompact ? 18 : 24,
            height: isCompact ? 18 : 24,
            decoration: BoxDecoration(
              color: completed
                  ? accentColor
                  : AutoBattlePalette.ink.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: completed
                    ? accentColor
                    : AutoBattlePalette.ink.withValues(alpha: 0.2),
                width: isCompact ? 1.5 : 2,
              ),
            ),
            child: completed
                ? Icon(Icons.check, color: Colors.white, size: isCompact ? 10 : 14)
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
                    fontSize: isCompact ? 11 : 13,
                    fontWeight: FontWeight.w900,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isCompact) ...[
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
              ],
            ),
          ),

          // Reward badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: isCompact ? 2 : 4),
            decoration: BoxDecoration(
              color: completed
                  ? accentColor.withValues(alpha: 0.15)
                  : const Color(0xFFF3F4F6),
              border: Border.all(
                color: completed
                    ? accentColor
                    : AutoBattlePalette.ink.withValues(alpha: 0.15),
                width: isCompact ? 1 : 1.5,
              ),
            ),
            child: Text(
              '💎 ${achievement.currencyReward}',
              style: TextStyle(
                color: completed ? accentColor : AutoBattlePalette.text3,
                fontSize: isCompact ? 9 : 11,
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
        vertical: isCompact ? 12 : 20
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24, 
              vertical: isCompact ? 8 : 12
            ),
            decoration: BoxDecoration(
              color: AutoBattlePalette.primary,
              border: Border.all(color: AutoBattlePalette.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 18 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          // Optional "Tape" effect on the title
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(6, 6)),
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
