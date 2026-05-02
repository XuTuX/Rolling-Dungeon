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
    _ShopTabDef(
        title: '캐릭터', icon: Icons.person, color: AutoBattlePalette.primary),
    _ShopTabDef(
        title: '무기/장비',
        icon: Icons.shopping_bag,
        color: AutoBattlePalette.secondary),
    _ShopTabDef(
        title: '능력치', icon: Icons.upgrade, color: AutoBattlePalette.gold),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MetaProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final isNarrow = w < 520;
            final isCompact = h < 500 || isNarrow;
            final sidebarWidth = w < 380 ? 80.0 : (isCompact ? 94.0 : 120.0);
            final pagePadding = w < 380 ? 8.0 : (isCompact ? 12.0 : 24.0);

            return Row(
              children: [
                // ── Sidebar Navigation ──
                Container(
                  width: sidebarWidth,
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  child: _SidebarTabButton(
                                    isSelected: isSelected,
                                    icon: tab.icon,
                                    label: tab.title,
                                    accentColor: tab.color,
                                    onTap: () =>
                                        setState(() => _currentTab = index),
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
                        child: Obx(() => _CurrencyBox(
                            amount: ctrl.currency.value, isCompact: isCompact)),
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
                              pagePadding, 0, pagePadding, pagePadding),
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
      case 0:
        return _CharacterShopTab(
            key: const ValueKey(0), ctrl: ctrl, isCompact: isCompact);
      case 1:
        return _EquipmentShopTab(
            key: const ValueKey(1), ctrl: ctrl, isCompact: isCompact);
      case 2:
        return _StatUpgradeTab(
            key: const ValueKey(2), ctrl: ctrl, isCompact: isCompact);
      default:
        return const SizedBox.shrink();
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
          border: Border.all(
              color: AutoBattlePalette.ink, width: isCompact ? 2.5 : 3),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                      color: AutoBattlePalette.ink,
                      offset: Offset(isCompact ? 2 : 4, isCompact ? 2 : 4))
                ],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
              offset: Offset(isCompact ? 2 : 3, isCompact ? 2 : 3)),
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
  const _CharacterShopTab(
      {super.key, required this.ctrl, required this.isCompact});

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 390;
            final selector = _CharacterSelectorPanel(
              ctrl: ctrl,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
              isCompact: widget.isCompact,
              isNarrow: isNarrow,
            );
            final detail = _CharacterDetailPanel(
              ctrl: ctrl,
              character: selected,
              isUnlocked: isUnlocked,
              isSelected: isSelected,
              canAfford: canAfford,
              isCompact: widget.isCompact,
              isNarrow: isNarrow,
            );

            if (isNarrow) {
              return Column(
                children: [
                  SizedBox(
                      height: widget.isCompact ? 112 : 132, child: selector),
                  Expanded(child: detail),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: selector),
                Expanded(flex: 3, child: detail),
              ],
            );
          },
        ),
      );
    });
  }
}

class _CharacterSelectorPanel extends StatelessWidget {
  final MetaProgressController ctrl;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isCompact;
  final bool isNarrow;

  const _CharacterSelectorPanel({
    required this.ctrl,
    required this.selectedIndex,
    required this.onSelected,
    required this.isCompact,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 8 : 12),
      decoration: BoxDecoration(
        border: Border(
          right: isNarrow
              ? BorderSide.none
              : const BorderSide(color: AutoBattlePalette.ink, width: 2),
          bottom: isNarrow
              ? const BorderSide(color: AutoBattlePalette.ink, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNarrow) ...[
            Text(
              'SELECT CHARACTER',
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isNarrow ? 4 : (isCompact ? 3 : 2),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: kAllCharacters.length,
              itemBuilder: (context, i) {
                final char = kAllCharacters[i];
                final unlocked = ctrl.unlockedCharacters.contains(char.id);
                final active = ctrl.selectedCharacter.value == char.id;
                final viewing = i == selectedIndex;

                return GestureDetector(
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: viewing
                          ? AutoBattlePalette.surfaceLight
                          : Colors.white,
                      border: Border.all(
                        color: viewing
                            ? AutoBattlePalette.primary
                            : AutoBattlePalette.ink,
                        width: viewing ? 3 : 2,
                      ),
                      boxShadow: viewing
                          ? null
                          : const [
                              BoxShadow(
                                  color: AutoBattlePalette.ink,
                                  offset: Offset(2, 2))
                            ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: CharacterBallPreview(
                            info: charDisplayInfoMap[char.shape] ??
                                charDisplayInfoMap['circle']!,
                            size: isNarrow ? 28 : (isCompact ? 32 : 44),
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
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 8),
                            ),
                          ),
                        if (!unlocked)
                          Container(
                            color: Colors.black.withValues(alpha: 0.05),
                            child: const Center(
                              child: Icon(Icons.lock,
                                  color: AutoBattlePalette.inkSubtle, size: 16),
                            ),
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
    );
  }
}

class _CharacterDetailPanel extends StatelessWidget {
  final MetaProgressController ctrl;
  final CharacterShopDef character;
  final bool isUnlocked;
  final bool isSelected;
  final bool canAfford;
  final bool isCompact;
  final bool isNarrow;

  const _CharacterDetailPanel({
    required this.ctrl,
    required this.character,
    required this.isUnlocked,
    required this.isSelected,
    required this.canAfford,
    required this.isCompact,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    final previewSize = isNarrow ? 46.0 : (isCompact ? 50.0 : 80.0);

    return Container(
      padding: EdgeInsets.all(isNarrow ? 8 : (isCompact ? 10 : 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: previewSize,
                height: previewSize,
                decoration: BoxDecoration(
                  color: AutoBattlePalette.surfaceLight,
                  border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                ),
                child: Center(
                  child: CharacterBallPreview(
                    info: charDisplayInfoMap[character.shape] ??
                        charDisplayInfoMap['circle']!,
                    size: previewSize * 0.82,
                  ),
                ),
              ),
              SizedBox(width: isNarrow ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: isNarrow ? 16 : (isCompact ? 18 : 24),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AutoBattlePalette.secondary.withValues(alpha: 0.1),
                        border: Border.all(
                            color: AutoBattlePalette.secondary, width: 1.5),
                      ),
                      child: Text(
                        character.trait,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AutoBattlePalette.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
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
                    width: double.infinity,
                    padding: EdgeInsets.all(isNarrow ? 8 : 10),
                    decoration: BoxDecoration(
                      color:
                          AutoBattlePalette.background.withValues(alpha: 0.5),
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 1.5),
                    ),
                    child: _ShopSummaryPanel(
                      icon: Icons.analytics,
                      summary: character.shopSummary,
                      isCompact: isCompact,
                      accentColor: AutoBattlePalette.primary,
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
                ? (isSelected ? null : () => ctrl.selectCharacter(character.id))
                : (canAfford ? () => ctrl.buyCharacter(character) : null),
            isCompact: true,
            color: isUnlocked
                ? (isSelected
                    ? const Color(0xFF4CAF50)
                    : AutoBattlePalette.secondary)
                : (canAfford
                    ? AutoBattlePalette.gold
                    : const Color(0xFF9CA3AF)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isUnlocked
                    ? (isSelected ? 'EQUIPPED' : 'SELECT')
                    : '💎 ${character.price} BUY',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopSummaryPanel extends StatelessWidget {
  final IconData icon;
  final String summary;
  final bool isCompact;
  final bool dense;
  final int maxChips;
  final Color accentColor;

  const _ShopSummaryPanel({
    required this.icon,
    required this.summary,
    required this.isCompact,
    this.dense = false,
    this.maxChips = 3,
    this.accentColor = AutoBattlePalette.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final lines = summary.split('\n');
    final power = lines.first.replaceFirst('전투력 ', '');
    final chips = lines.length > 1 ? lines[1].split(' · ') : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dense ? 6 : 8,
                  vertical: dense ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: dense ? 12 : 15),
                    SizedBox(width: dense ? 3 : 5),
                    Flexible(
                      child: Text(
                        power,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dense ? 11 : (isCompact ? 12 : 14),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          SizedBox(height: dense ? 4 : 7),
          Wrap(
            spacing: dense ? 3 : 5,
            runSpacing: dense ? 3 : 5,
            children: [
              for (final chip in chips.take(maxChips))
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dense ? 5 : 7,
                    vertical: dense ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    chip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: dense ? 8 : (isCompact ? 9 : 11),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EquipmentShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  const _EquipmentShopTab(
      {super.key, required this.ctrl, required this.isCompact});

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
              border: Border(
                  bottom: BorderSide(color: AutoBattlePalette.ink, width: 2)),
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AutoBattlePalette.secondary
                          : Colors.white,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 2),
                      boxShadow: isSelected
                          ? null
                          : const [
                              BoxShadow(
                                  color: AutoBattlePalette.ink,
                                  offset: Offset(2, 2))
                            ],
                    ),
                    child: Center(
                      child: Text(
                        slotLabel.split('/')[0],
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AutoBattlePalette.ink,
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
              // Accessing Rx variables here ensures Obx always has listeners.
              widget.ctrl.unlockedEquipment.length;
              final currentCurrency = widget.ctrl.currency.value;

              final items =
                  grouped[_selectedSlot] ?? const <EquipmentShopDef>[];

              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    '항목이 없습니다.',
                    style: TextStyle(
                        color: AutoBattlePalette.inkSubtle,
                        fontWeight: FontWeight.w900),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, gridConstraints) {
                  final oneColumn = gridConstraints.maxWidth < 390;
                  final itemExtent = oneColumn
                      ? (widget.isCompact ? 158.0 : 172.0)
                      : (widget.isCompact ? 148.0 : 168.0);

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: oneColumn ? 1 : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: itemExtent,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final equipment = items[index];
                      final unlocked =
                          widget.ctrl.unlockedEquipment.contains(equipment.id);
                      final isEquipped =
                          widget.ctrl.equippedEquipment[equipment.slot] ==
                              equipment.id;
                      final canAfford = currentCurrency >= equipment.price;

                      return _EquipmentCard(
                        equipment: equipment,
                        unlocked: unlocked,
                        equipped: isEquipped,
                        canAfford: canAfford,
                        ctrl: widget.ctrl,
                        isCompact: widget.isCompact,
                        oneColumn: oneColumn,
                        isWeaponTab: _selectedSlot == 'weapon',
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
                },
              );
            }),
          ),
        ],
      ),
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
  final bool oneColumn;
  final bool isWeaponTab;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.ctrl,
    required this.isCompact,
    required this.oneColumn,
    required this.isWeaponTab,
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
        : (equipment.slot == 'hand'
            ? AutoBattlePalette.secondary
            : AutoBattlePalette.gold);

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
            width: oneColumn ? (isCompact ? 48 : 58) : (isCompact ? 54 : 66),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              border: const Border(
                right: BorderSide(color: AutoBattlePalette.ink, width: 1.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  equipment.icon,
                  style: TextStyle(fontSize: isCompact ? 24 : 31),
                ),
                const SizedBox(height: 5),
                Icon(
                  _slotIcon(equipment.slot),
                  color: accentColor,
                  size: isCompact ? 14 : 16,
                ),
              ],
            ),
          ),

          // Right: Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: oneColumn ? 8 : 6, vertical: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            equipment.title,
                            style: TextStyle(
                                color: AutoBattlePalette.ink,
                                fontSize: isCompact ? 11 : 13,
                                fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isCompact ? 4 : 6),
                          _ShopSummaryPanel(
                            icon: Icons.bolt,
                            summary: equipment.statSummary,
                            isCompact: isCompact,
                            dense: true,
                            maxChips: isWeaponTab ? 1 : 2,
                            accentColor: accentColor,
                          ),
                          SizedBox(height: isCompact ? 6 : 8),
                          _SketchButton(
                            onTap: equipped ? null : onTap,
                            height: isCompact ? 24 : 28,
                            color: buttonColor,
                            isCompact: true,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                !unlocked
                                    ? '💎${equipment.price}'
                                    : (equipped ? 'EQUIPPED' : 'SELECT'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          if (unlocked && equipment.weaponType != null) ...[
                            const SizedBox(height: 4),
                            _EquipmentUpgradeRow(
                                equipment: equipment,
                                ctrl: ctrl,
                                isCompact: isCompact),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _slotIcon(String slot) {
    return switch (slot) {
      'weapon' => Icons.gps_fixed,
      'hand' => Icons.center_focus_strong,
      'armor' => Icons.shield,
      'boots' => Icons.speed,
      _ => Icons.auto_awesome,
    };
  }
}

// ─────────────────────────────────────────────
//  Stat Upgrade Tab
// ─────────────────────────────────────────────
class _StatUpgradeTab extends StatelessWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  const _StatUpgradeTab(
      {super.key, required this.ctrl, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return _ShopPage(
      isCompact: isCompact,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final oneColumn = constraints.maxWidth < 390;

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(12, 12, 12, isCompact ? 12 : 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: oneColumn ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent:
                  oneColumn ? (isCompact ? 76 : 88) : (isCompact ? 92 : 112),
            ),
            itemCount: kAllStatUpgrades.length,
            itemBuilder: (context, index) {
              final def = kAllStatUpgrades[index];
              return Obx(() {
                final level = ctrl.getStatLevel(def.statType);
                final cost = ctrl.getStatUpgradeCost(def);
                final canAfford = ctrl.currency.value >= cost;
                final gain = ShopStatPresenter.statUpgradeGain(def);
                final summary = ShopStatPresenter.statUpgradeSummary(def);

                return Container(
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AutoBattlePalette.ink,
                          offset: Offset(isCompact ? 2 : 3, isCompact ? 2 : 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isCompact ? 34 : 44,
                        height: isCompact ? 34 : 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AutoBattlePalette.surfaceLight,
                          border: Border.all(
                              color: AutoBattlePalette.ink, width: 1.5),
                          shape: BoxShape.circle,
                        ),
                        child: Text(def.icon,
                            style: TextStyle(fontSize: isCompact ? 17 : 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.title,
                              style: TextStyle(
                                  color: AutoBattlePalette.ink,
                                  fontSize: isCompact ? 11 : 13,
                                  fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'LV.$level · $gain',
                              style: TextStyle(
                                  color: AutoBattlePalette.inkSubtle,
                                  fontSize: isCompact ? 9 : 11,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              summary,
                              style: TextStyle(
                                  color: AutoBattlePalette.secondary,
                                  fontSize: isCompact ? 8 : 10,
                                  fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SketchButton(
                        onTap: () => ctrl.upgradeStat(def),
                        width: isCompact ? 52 : 62,
                        height: isCompact ? 34 : 42,
                        isCompact: isCompact,
                        color: canAfford
                            ? AutoBattlePalette.gold
                            : const Color(0xFFE5E7EB),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('UP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 9 : 11,
                                      fontWeight: FontWeight.w900)),
                              Text('💎$cost',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 8 : 10,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          );
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
          horizontal: isCompact ? 6 : 10, vertical: isCompact ? 3 : 6),
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: AutoBattlePalette.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'LV.$level 강화',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: isCompact ? 8.5 : 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _SketchButton(
            onTap: canAfford
                ? () => ctrl.upgradeWeapon(equipment.weaponType!)
                : null,
            width: isCompact ? 56 : 64,
            height: isCompact ? 24 : 30,
            isCompact: true,
            color: canAfford ? AutoBattlePalette.primary : Colors.grey,
            child: Text(
              '💎$cost',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          horizontal: isCompact ? 12 : 24, vertical: isCompact ? 10 : 20),
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.02, // Slight tilt for sketchy look
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 24,
                  vertical: isCompact ? 6 : 12),
              decoration: BoxDecoration(
                color: AutoBattlePalette.primary,
                border: Border.all(color: AutoBattlePalette.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                ],
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                border: Border.all(
                    color: AutoBattlePalette.ink.withValues(alpha: 0.1),
                    width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(1, 1)),
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
        transform:
            _pressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade300 : widget.color,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: (disabled || _pressed)
              ? null
              : const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))
                ],
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
