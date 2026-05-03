import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            final isCompact = h < 600 || w < 760;
            final pagePadding = w < 420 ? 12.0 : 20.0;

            return Column(
              children: [
                _ShopTopBar(
                  tabs: _tabs,
                  currentTab: _currentTab,
                  onTabChanged: (index) => setState(() => _currentTab = index),
                  isCompact: isCompact,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, pagePadding),
                    child: _ShopContentWrapper(
                      child: _buildCurrentTab(ctrl, isCompact, w < 500),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentTab(
      MetaProgressController ctrl, bool isCompact, bool isNarrow) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildTabContent(ctrl, isCompact, isNarrow),
    );
  }

  Widget _buildTabContent(MetaProgressController ctrl, bool isCompact, bool isNarrow) {
    switch (_currentTab) {
      case 0:
        return _CharacterShopTab(
            key: const ValueKey(0),
            ctrl: ctrl,
            isCompact: isCompact,
            isNarrowPage: isNarrow);
      case 1:
        return _EquipmentShopTab(
            key: const ValueKey(1),
            ctrl: ctrl,
            isCompact: isCompact,
            isNarrowPage: isNarrow);
      case 2:
        return _StatUpgradeTab(
            key: const ValueKey(2),
            ctrl: ctrl,
            isCompact: isCompact,
            isNarrowPage: isNarrow);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ShopContentWrapper extends StatelessWidget {
  final Widget child;
  const _ShopContentWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hard offset shadow for the whole board
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(left: 8, top: 8),
            decoration: const BoxDecoration(color: AutoBattlePalette.ink),
          ),
        ),
        Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: CustomPaint(
            painter: _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 4),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(painter: _NotebookLinesPainter()),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopTabDef {
  final String title;
  final IconData icon;
  final Color color;
  _ShopTabDef({required this.title, required this.icon, required this.color});
}

class _ShopTopBar extends StatelessWidget {
  final List<_ShopTabDef> tabs;
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final bool isCompact;

  const _ShopTopBar({
    required this.tabs,
    required this.currentTab,
    required this.onTabChanged,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MetaProgressController>();

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          Row(
            children: [
              _SketchIconButton(
                onTap: () => Get.back(),
                icon: Icons.close,
                isCompact: isCompact,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'BATTLE SHOP',
                  style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: isCompact ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Obx(() => _TopCurrencyBox(
                    amount: ctrl.currency.value,
                    isCompact: isCompact,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = currentTab == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
                  child: _TopTabButton(
                    label: tab.title,
                    icon: tab.icon,
                    color: tab.color,
                    isSelected: isSelected,
                    onTap: () => onTabChanged(index),
                    isCompact: isCompact,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TopTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  const _TopTabButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: isSelected ? 0 : (label.length % 2 == 0 ? 0.02 : -0.02),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            boxShadow: isSelected
                ? null
                : const [
                    BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
                  ],
          ),
          child: CustomPaint(
            painter: _SketchyBorderPainter(
              color: AutoBattlePalette.ink,
              width: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AutoBattlePalette.ink,
                  size: isCompact ? 16 : 20,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AutoBattlePalette.ink,
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopCurrencyBox extends StatelessWidget {
  final int amount;
  final bool isCompact;

  const _TopCurrencyBox({required this.amount, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: AutoBattlePalette.gold,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            amount.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 16 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool isCompact;

  const _SketchIconButton({
    required this.onTap,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: AutoBattlePalette.ink, size: isCompact ? 20 : 24),
      ),
    );
  }
}

// (Duplicate removed)

class _CharacterShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  final bool isNarrowPage;
  const _CharacterShopTab(
      {super.key,
      required this.ctrl,
      required this.isCompact,
      required this.isNarrowPage});

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

      return _ShopContentWrapper(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = widget.isNarrowPage || constraints.maxWidth < 420;
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
                  SizedBox(height: widget.isCompact ? 124 : 144, child: selector),
                  const SizedBox(height: 10),
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
          right: isNarrow ? BorderSide.none : const BorderSide(color: AutoBattlePalette.ink, width: 2),
          bottom: isNarrow ? const BorderSide(color: AutoBattlePalette.ink, width: 2) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNarrow) ...[
            Text('SELECT', style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isNarrow ? 4 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: isNarrow ? 1 : (isCompact ? 1.05 : 1.18),
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
                      color: viewing ? AutoBattlePalette.surfaceLight : Colors.white,
                      border: Border.all(color: viewing ? AutoBattlePalette.primary : AutoBattlePalette.ink, width: viewing ? 3 : 2),
                      boxShadow: viewing ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))],
                    ),
                    child: Stack(
                      children: [
                        Center(child: CharacterBallPreview(info: charDisplayInfoMap[char.shape] ?? charDisplayInfoMap['circle']!, size: isNarrow ? 28 : (isCompact ? 32 : 44))),
                        if (active) Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 8))),
                        if (!unlocked) Container(color: Colors.black.withValues(alpha: 0.05), child: const Center(child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 16))),
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

  const _CharacterDetailPanel({required this.ctrl, required this.character, required this.isUnlocked, required this.isSelected, required this.canAfford, required this.isCompact, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final previewSize = isNarrow ? 46.0 : (isCompact ? 50.0 : 80.0);

    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : (isCompact ? 16 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Character Card ──
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, top: 6),
                    decoration: const BoxDecoration(color: AutoBattlePalette.ink),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(color: AutoBattlePalette.background),
                  child: CustomPaint(
                    painter: const _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 3),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(Icons.auto_awesome, color: AutoBattlePalette.ink.withValues(alpha: 0.1), size: 40),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Hero(
                                    tag: 'char_${character.id}',
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: CharacterBallPreview(
                                        info: charDisplayInfoMap[character.shape] ??
                                            charDisplayInfoMap['circle']!,
                                        size: previewSize * 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                character.title,
                                style: TextStyle(
                                  color: AutoBattlePalette.ink,
                                  fontSize: isCompact ? 22 : 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _BattleRatingBadge(rating: character.price ~/ 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Stats card ──
          _InfoCard(
            child: _ShopSummaryPanel(
              icon: Icons.flash_on,
              summary: character.shopSummary,
              isCompact: isCompact,
              accentColor: AutoBattlePalette.secondary,
            ),
          ),
          const SizedBox(height: 20),
          // ── Action Button ──
          _SketchButton(
            onTap: isUnlocked
                ? (isSelected ? null : () => ctrl.selectCharacter(character.id))
                : (canAfford ? () => ctrl.buyCharacter(character) : null),
            isCompact: false,
            height: 64,
            color: isUnlocked
                ? (isSelected
                    ? const Color(0xFF4CAF50)
                    : AutoBattlePalette.secondary)
                : (canAfford
                    ? AutoBattlePalette.gold
                    : const Color(0xFF9CA3AF)),
            child: Text(
              isUnlocked
                  ? (isSelected ? 'EQUIPPED' : 'SELECT CHARACTER')
                  : '💎 ${character.price} PURCHASE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleRatingBadge extends StatelessWidget {
  final int rating;
  const _BattleRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AutoBattlePalette.primary.withValues(alpha: 0.1),
      ),
      child: CustomPaint(
        painter: _SketchyBorderPainter(color: AutoBattlePalette.primary, width: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            'BATTLE RATING: $rating',
            style: const TextStyle(
              color: AutoBattlePalette.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentShopTab extends StatefulWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  final bool isNarrowPage;
  const _EquipmentShopTab({super.key, required this.ctrl, required this.isCompact, required this.isNarrowPage});

  @override
  State<_EquipmentShopTab> createState() => _EquipmentShopTabState();
}

class _EquipmentShopTabState extends State<_EquipmentShopTab> {
  String _selectedSlot = 'weapon';
  final Map<String, int> _selectedIndexBySlot = {};

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<EquipmentShopDef>>{};
    for (final equipment in kAllEquipment) { grouped.putIfAbsent(equipment.slot, () => []).add(equipment); }
    return _ShopContentWrapper(
      child: Obx(() {
        final items = grouped[_selectedSlot] ?? const <EquipmentShopDef>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final selectedIndex = (_selectedIndexBySlot[_selectedSlot] ?? 0).clamp(0, items.length - 1);
        final selected = items[selectedIndex];
        final unlocked = widget.ctrl.unlockedEquipment.contains(selected.id);
        final equipped = widget.ctrl.equippedEquipment[selected.slot] == selected.id;
        final canAfford = widget.ctrl.currency.value >= selected.price;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = widget.isNarrowPage || constraints.maxWidth < 420;
            final selector = _EquipmentSelectorPanel(items: items, ctrl: widget.ctrl, selectedIndex: selectedIndex, selectedSlot: _selectedSlot, isCompact: widget.isCompact, isNarrow: isNarrow, onSelected: (index) => setState(() => _selectedIndexBySlot[_selectedSlot] = index), onSlotChanged: (slot) => setState(() => _selectedSlot = slot));
            final detail = _EquipmentDetailPanel(equipment: selected, ctrl: widget.ctrl, unlocked: unlocked, equipped: equipped, canAfford: canAfford, isCompact: widget.isCompact, isNarrow: isNarrow, onTap: () { if (unlocked) { widget.ctrl.equipEquipment(selected); } else { widget.ctrl.buyEquipment(selected); } });
            if (isNarrow) { return Column(children: [SizedBox(height: widget.isCompact ? 172 : 196, child: selector), const SizedBox(height: 10), Expanded(child: detail)]); }
            return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: selector), Expanded(flex: 3, child: detail)]);
          },
        );
      }),
    );
  }
}

class _EquipmentSelectorPanel extends StatelessWidget {
  final List<EquipmentShopDef> items;
  final MetaProgressController ctrl;
  final int selectedIndex;
  final String selectedSlot;
  final bool isCompact;
  final bool isNarrow;
  final ValueChanged<int> onSelected;
  final ValueChanged<String> onSlotChanged;

  const _EquipmentSelectorPanel({required this.items, required this.ctrl, required this.selectedIndex, required this.selectedSlot, required this.isCompact, required this.isNarrow, required this.onSelected, required this.onSlotChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 8 : 12),
      decoration: BoxDecoration(border: Border(right: isNarrow ? BorderSide.none : const BorderSide(color: AutoBattlePalette.ink, width: 2), bottom: isNarrow ? const BorderSide(color: AutoBattlePalette.ink, width: 2) : BorderSide.none)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isCompact ? 36 : 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: kEquipmentSlotLabels.keys.map((slotKey) {
                final isSelected = selectedSlot == slotKey;
                return GestureDetector(
                  onTap: () => onSlotChanged(slotKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: isSelected ? AutoBattlePalette.secondary : Colors.white, border: Border.all(color: AutoBattlePalette.ink, width: 2)),
                    child: Center(child: Text(kEquipmentSlotLabels[slotKey]!.split('/').first, style: TextStyle(color: isSelected ? Colors.white : AutoBattlePalette.ink, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w900))),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isNarrow ? 4 : 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isNarrow ? 1 : (isCompact ? 1.05 : 1.18)),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final equipment = items[index];
                final viewing = index == selectedIndex;
                final unlocked = ctrl.unlockedEquipment.contains(equipment.id);
                final active = ctrl.equippedEquipment[equipment.slot] == equipment.id;
                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(color: viewing ? AutoBattlePalette.surfaceLight : Colors.white, border: Border.all(color: viewing ? AutoBattlePalette.secondary : AutoBattlePalette.ink, width: viewing ? 3 : 2), boxShadow: viewing ? null : const [BoxShadow(color: AutoBattlePalette.ink, offset: Offset(2, 2))]),
                    child: Stack(
                      children: [
                        Center(child: Text(equipment.icon, style: TextStyle(fontSize: isNarrow ? 26 : 34))),
                        if (active) Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 8))),
                        if (!unlocked) Container(color: Colors.black.withValues(alpha: 0.05), child: const Center(child: Icon(Icons.lock, color: AutoBattlePalette.inkSubtle, size: 16))),
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

class _EquipmentDetailPanel extends StatelessWidget {
  final EquipmentShopDef equipment;
  final MetaProgressController ctrl;
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final bool isCompact;
  final bool isNarrow;
  final VoidCallback onTap;

  const _EquipmentDetailPanel({required this.equipment, required this.ctrl, required this.unlocked, required this.equipped, required this.canAfford, required this.isCompact, required this.isNarrow, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = equipment.slot == 'weapon'
        ? AutoBattlePalette.primary
        : (equipment.slot == 'hand'
            ? AutoBattlePalette.secondary
            : AutoBattlePalette.gold);

    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : (isCompact ? 16 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Equipment Card ──
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, top: 6),
                    decoration: const BoxDecoration(color: AutoBattlePalette.ink),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.05),
                  ),
                  child: CustomPaint(
                    painter: const _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 3),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            equipment.slot.toUpperCase(),
                            style: TextStyle(
                              color: AutoBattlePalette.ink.withValues(alpha: 0.1),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Hero(
                                    tag: 'equip_${equipment.id}',
                                    child: Text(
                                      equipment.icon,
                                      style: TextStyle(fontSize: isCompact ? 60 : 80),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                equipment.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AutoBattlePalette.ink,
                                  fontSize: isCompact ? 20 : 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Stats card ──
          _InfoCard(
            child: _ShopSummaryPanel(
              icon: Icons.bolt,
              summary: equipment.statSummary,
              isCompact: isCompact,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          // ── Action Button ──
          _SketchButton(
            onTap: onTap,
            height: 64,
            color: equipped
                ? const Color(0xFF4CAF50)
                : (unlocked
                    ? accentColor
                    : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF))),
            child: Text(
              equipped
                  ? 'EQUIPPED'
                  : (unlocked ? 'EQUIP ITEM' : '💎 ${equipment.price} PURCHASE'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (unlocked && equipment.weaponType != null) ...[
            const SizedBox(height: 12),
            _EquipmentUpgradeRow(
                equipment: equipment, ctrl: ctrl, isCompact: isCompact),
          ],
        ],
      ),
    );
  }
}

class _StatUpgradeTab extends StatelessWidget {
  final MetaProgressController ctrl;
  final bool isCompact;
  final bool isNarrowPage;
  const _StatUpgradeTab({super.key, required this.ctrl, required this.isCompact, required this.isNarrowPage});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
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
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(left: 4, top: 4),
                    decoration: const BoxDecoration(color: AutoBattlePalette.ink),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: CustomPaint(
                    painter: const _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 2),
                    child: Row(
                      children: [
                        Container(
                          width: isCompact ? 44 : 54,
                          height: isCompact ? 44 : 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AutoBattlePalette.gold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 1.5),
                            child: Center(
                              child: Text(def.icon, style: TextStyle(fontSize: isCompact ? 22 : 28)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                def.title,
                                style: TextStyle(
                                    color: AutoBattlePalette.ink,
                                    fontSize: isCompact ? 16 : 18,
                                    fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'LEVEL $level · $gain',
                                style: TextStyle(
                                    color: AutoBattlePalette.primary,
                                    fontSize: isCompact ? 12 : 14,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary,
                                style: TextStyle(
                                    color: AutoBattlePalette.inkSubtle,
                                    fontSize: isCompact ? 11 : 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _SketchButton(
                          onTap: () => ctrl.upgradeStat(def),
                          width: isCompact ? 80 : 100,
                          height: isCompact ? 50 : 60,
                          color: canAfford ? AutoBattlePalette.gold : const Color(0xFFE5E7EB),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('UPGRADE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 10 : 12,
                                      fontWeight: FontWeight.w900)),
                              Text('💎$cost',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 12 : 14,
                                      fontWeight: FontWeight.w900)),
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
      },
    );
  }
}

class _EquipmentUpgradeRow extends StatelessWidget {
  final EquipmentShopDef equipment;
  final MetaProgressController ctrl;
  final bool isCompact;
  const _EquipmentUpgradeRow({required this.equipment, required this.ctrl, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    if (equipment.weaponType == null) return const SizedBox.shrink();
    final level = ctrl.getWeaponLevel(equipment.weaponType!);
    final cost = ctrl.getWeaponUpgradeCost(equipment.weaponType!);
    final canAfford = ctrl.currency.value >= cost;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(color: AutoBattlePalette.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Expanded(child: Text('LV.$level 강화', style: TextStyle(color: AutoBattlePalette.ink, fontSize: 12, fontWeight: FontWeight.w800))),
          _SketchButton(onTap: canAfford ? () => ctrl.upgradeWeapon(equipment.weaponType!) : null, width: isCompact ? 56 : 64, height: isCompact ? 28 : 34, isCompact: true, color: canAfford ? AutoBattlePalette.primary : Colors.grey, child: Text('💎$cost', style: TextStyle(color: Colors.white, fontSize: isCompact ? 9 : 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _ShopSummaryPanel extends StatelessWidget {
  final IconData icon;
  final String summary;
  final bool isCompact;
  final Color accentColor;
  const _ShopSummaryPanel({required this.icon, required this.summary, required this.isCompact, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final lines = summary.split('\n');
    final power = lines.first;
    final chips = lines.length > 1 ? lines[1].split(' · ') : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, color: accentColor, size: isCompact ? 16 : 20), const SizedBox(width: 8), Text(power, style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.w900))]),
        if (chips.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: chips.map((chip) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1)), child: Text(chip, style: TextStyle(color: AutoBattlePalette.ink, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w700)))).toList())],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: CustomPaint(
        painter: _SketchyBorderPainter(color: AutoBattlePalette.ink, width: 2),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

// (Removed redundant _ShopPage)

// ─────────────────────────────────────────────
//  Sketchy UI Components
// ─────────────────────────────────────────────

class _SketchyBorderPainter extends CustomPainter {
  final Color color;
  final double width;

  const _SketchyBorderPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const step = 20.0;
    
    // Hand-drawn organic line helper
    void drawWavyLine(Offset start, Offset end) {
      path.moveTo(start.dx, start.dy);
      final dist = (end - start).distance;
      final points = (dist / step).ceil();
      for (int i = 1; i <= points; i++) {
        final t = i / points;
        final p = Offset.lerp(start, end, t)!;
        // Random jitter for sketchy feel
        final jitterX = (i == points) ? 0.0 : (DateTime.now().millisecond % 3 - 1.5) * 0.8;
        final jitterY = (i == points) ? 0.0 : (DateTime.now().millisecond % 5 - 2.5) * 0.8;
        path.lineTo(p.dx + jitterX, p.dy + jitterY);
      }
    }

    drawWavyLine(Offset.zero, Offset(size.width, 0));
    drawWavyLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawWavyLine(Offset(size.width, size.height), Offset(0, size.height));
    drawWavyLine(Offset(0, size.height), Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.15)
      ..strokeWidth = 1.2;
    for (double y = 40; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final color = disabled ? const Color(0xFFE5E7EB) : widget.color;
    final shadowOffset = _isPressed ? const Offset(1, 1) : const Offset(4, 4);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AutoBattlePalette.ink, width: 3),
          boxShadow: [
            BoxShadow(
              color: AutoBattlePalette.ink,
              offset: shadowOffset,
            ),
          ],
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
