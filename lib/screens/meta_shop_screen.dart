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
            final isNarrow = w < 560;
            final isCompact = h < 560 || w < 760;
            final sidebarWidth = w < 420 ? 82.0 : (isCompact ? 96.0 : 112.0);
            final pagePadding = w < 420 ? 8.0 : (isCompact ? 12.0 : 18.0);

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
                        padding: EdgeInsets.only(top: isCompact ? 8 : 12),
                        child: _SidebarIconButton(
                          onTap: () => Get.back(),
                          icon: Icons.arrow_back,
                          color: AutoBattlePalette.ink,
                          size: isCompact ? 40 : 54,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(_tabs.length, (index) {
                              final tab = _tabs[index];
                              final isSelected = _currentTab == index;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: _SidebarTabButton(
                                    isSelected: isSelected,
                                    icon: tab.icon,
                                    label: tab.title,
                                    accentColor: tab.color,
                                    onTap: () =>
                                        setState(() => _currentTab = index),
                                    isCompact: isCompact,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                          child: _buildCurrentTab(ctrl, isCompact, isNarrow),
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

  Widget _buildCurrentTab(
      MetaProgressController ctrl, bool isCompact, bool isNarrow) {
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

      return _ShopPage(
        isCompact: widget.isCompact,
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
                  SizedBox(
                      height: widget.isCompact ? 124 : 144, child: selector),
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
              physics: const NeverScrollableScrollPhysics(),
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isNarrow ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isNarrow ? 10 : 12),
                    decoration: BoxDecoration(
                      color:
                          AutoBattlePalette.background.withValues(alpha: 0.5),
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShopSummaryPanel(
                          icon: Icons.analytics,
                          summary: character.shopSummary,
                          isCompact: isCompact,
                          accentColor: AutoBattlePalette.primary,
                        ),
                        const Spacer(),
                        _CharacterStatusRow(
                          isUnlocked: isUnlocked,
                          isSelected: isSelected,
                          canAfford: canAfford,
                          price: character.price,
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

class _CharacterStatusRow extends StatelessWidget {
  final bool isUnlocked;
  final bool isSelected;
  final bool canAfford;
  final int price;
  final bool isCompact;

  const _CharacterStatusRow({
    required this.isUnlocked,
    required this.isSelected,
    required this.canAfford,
    required this.price,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final label = isUnlocked
        ? (isSelected ? '현재 선택됨' : '보유 중')
        : (canAfford ? '구매 가능' : '재화 부족');
    final value = isUnlocked ? 'READY' : '💎 $price';
    final color = isUnlocked
        ? AutoBattlePalette.secondary
        : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF));

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10, vertical: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w900,
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
  final int maxChips;
  final Color accentColor;

  const _ShopSummaryPanel({
    required this.icon,
    required this.summary,
    required this.isCompact,
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
                  horizontal: isCompact ? 6 : 8,
                  vertical: isCompact ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: isCompact ? 12 : 15),
                    SizedBox(width: isCompact ? 3 : 5),
                    Flexible(
                      child: Text(
                        power,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 12 : 14,
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
          SizedBox(height: isCompact ? 4 : 7),
          Wrap(
            spacing: isCompact ? 3 : 5,
            runSpacing: isCompact ? 3 : 5,
            children: [
              for (final chip in chips.take(maxChips))
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 5 : 7,
                    vertical: isCompact ? 2 : 4,
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
                      fontSize: isCompact ? 9 : 11,
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
  final bool isNarrowPage;
  const _EquipmentShopTab(
      {super.key,
      required this.ctrl,
      required this.isCompact,
      required this.isNarrowPage});

  @override
  State<_EquipmentShopTab> createState() => _EquipmentShopTabState();
}

class _EquipmentShopTabState extends State<_EquipmentShopTab> {
  String _selectedSlot = 'weapon';
  final Map<String, int> _selectedIndexBySlot = {};

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<EquipmentShopDef>>{};
    for (final equipment in kAllEquipment) {
      grouped.putIfAbsent(equipment.slot, () => []).add(equipment);
    }

    return _ShopPage(
      isCompact: widget.isCompact,
      child: Obx(() {
        widget.ctrl.unlockedEquipment.length;
        widget.ctrl.currency.value;

        final items = grouped[_selectedSlot] ?? const <EquipmentShopDef>[];
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

        final selectedIndex = (_selectedIndexBySlot[_selectedSlot] ?? 0)
            .clamp(0, items.length - 1);
        final selected = items[selectedIndex];
        final unlocked = widget.ctrl.unlockedEquipment.contains(selected.id);
        final equipped =
            widget.ctrl.equippedEquipment[selected.slot] == selected.id;
        final canAfford = widget.ctrl.currency.value >= selected.price;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = widget.isNarrowPage || constraints.maxWidth < 420;
            final selector = _EquipmentSelectorPanel(
              items: items,
              ctrl: widget.ctrl,
              selectedIndex: selectedIndex,
              selectedSlot: _selectedSlot,
              isCompact: widget.isCompact,
              isNarrow: isNarrow,
              onSelected: (index) =>
                  setState(() => _selectedIndexBySlot[_selectedSlot] = index),
              onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
            );
            final detail = _EquipmentDetailPanel(
              equipment: selected,
              ctrl: widget.ctrl,
              unlocked: unlocked,
              equipped: equipped,
              canAfford: canAfford,
              isCompact: widget.isCompact,
              isNarrow: isNarrow,
              onTap: () {
                if (unlocked) {
                  widget.ctrl.equipEquipment(selected);
                } else {
                  widget.ctrl.buyEquipment(selected);
                }
              },
            );

            if (isNarrow) {
              return Column(
                children: [
                  SizedBox(
                      height: widget.isCompact ? 172 : 196, child: selector),
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

  const _EquipmentSelectorPanel({
    required this.items,
    required this.ctrl,
    required this.selectedIndex,
    required this.selectedSlot,
    required this.isCompact,
    required this.isNarrow,
    required this.onSelected,
    required this.onSlotChanged,
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
          SizedBox(
            height: isCompact ? 36 : 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: kEquipmentSlotLabels.keys.map((slotKey) {
                final slotLabel = kEquipmentSlotLabels[slotKey]!;
                final isSelected = selectedSlot == slotKey;
                return GestureDetector(
                  onTap: () => onSlotChanged(slotKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AutoBattlePalette.secondary
                          : Colors.white,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        slotLabel.split('/').first,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AutoBattlePalette.ink,
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: isNarrow ? 8 : 12),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isNarrow ? 4 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: isNarrow ? 1 : (isCompact ? 1.05 : 1.18),
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final equipment = items[index];
                final viewing = index == selectedIndex;
                final unlocked = ctrl.unlockedEquipment.contains(equipment.id);
                final active =
                    ctrl.equippedEquipment[equipment.slot] == equipment.id;

                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: viewing
                          ? AutoBattlePalette.surfaceLight
                          : Colors.white,
                      border: Border.all(
                        color: viewing
                            ? AutoBattlePalette.secondary
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
                          child: Text(
                            equipment.icon,
                            style: TextStyle(fontSize: isNarrow ? 26 : 34),
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

class _EquipmentDetailPanel extends StatelessWidget {
  final EquipmentShopDef equipment;
  final MetaProgressController ctrl;
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final bool isCompact;
  final bool isNarrow;
  final VoidCallback onTap;

  const _EquipmentDetailPanel({
    required this.equipment,
    required this.ctrl,
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.isCompact,
    required this.isNarrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = equipment.slot == 'weapon'
        ? AutoBattlePalette.primary
        : (equipment.slot == 'hand'
            ? AutoBattlePalette.secondary
            : AutoBattlePalette.gold);
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
                  color: accentColor.withValues(alpha: 0.14),
                  border: Border.all(color: AutoBattlePalette.ink, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    equipment.icon,
                    style: TextStyle(fontSize: isCompact ? 24 : 34),
                  ),
                ),
              ),
              SizedBox(width: isNarrow ? 10 : 16),
              Expanded(
                child: Text(
                  equipment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: isNarrow ? 16 : (isCompact ? 18 : 24),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isNarrow ? 8 : 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isNarrow ? 10 : 12),
              decoration: BoxDecoration(
                color: AutoBattlePalette.background.withValues(alpha: 0.5),
                border: Border.all(color: AutoBattlePalette.ink, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShopSummaryPanel(
                    icon: Icons.bolt,
                    summary: equipment.statSummary,
                    isCompact: isCompact,
                    maxChips: 3,
                    accentColor: accentColor,
                  ),
                  const Spacer(),
                  _EquipmentStatusRow(
                    unlocked: unlocked,
                    equipped: equipped,
                    canAfford: canAfford,
                    price: equipment.price,
                    isCompact: isCompact,
                    accentColor: accentColor,
                  ),
                  if (unlocked && equipment.weaponType != null) ...[
                    const SizedBox(height: 8),
                    _EquipmentUpgradeRow(
                        equipment: equipment, ctrl: ctrl, isCompact: isCompact),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentStatusRow extends StatelessWidget {
  final bool unlocked;
  final bool equipped;
  final bool canAfford;
  final int price;
  final bool isCompact;
  final Color accentColor;

  const _EquipmentStatusRow({
    required this.unlocked,
    required this.equipped,
    required this.canAfford,
    required this.price,
    required this.isCompact,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = equipped
        ? '현재 장착됨'
        : (unlocked ? '보유 중' : (canAfford ? '구매 가능' : '재화 부족'));
    final value = unlocked ? 'READY' : '💎 $price';
    final color = equipped
        ? const Color(0xFF4CAF50)
        : (unlocked
            ? accentColor
            : (canAfford ? AutoBattlePalette.gold : const Color(0xFF9CA3AF)));

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10, vertical: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w900,
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
  final bool isNarrowPage;
  const _StatUpgradeTab(
      {super.key,
      required this.ctrl,
      required this.isCompact,
      required this.isNarrowPage});

  @override
  Widget build(BuildContext context) {
    return _ShopPage(
      isCompact: isCompact,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final oneColumn = isNarrowPage || constraints.maxWidth < 390;
          final crossAxisCount = oneColumn ? 1 : 2;
          final rowCount = (kAllStatUpgrades.length / crossAxisCount).ceil();
          const spacing = 12.0;
          final verticalPadding = isCompact ? 24.0 : 32.0;
          final itemExtent = ((constraints.maxHeight -
                      verticalPadding -
                      (spacing * (rowCount - 1))) /
                  rowCount)
              .clamp(oneColumn ? 70.0 : 82.0, oneColumn ? 90.0 : 116.0);

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(12, 12, 12, isCompact ? 12 : 20),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: itemExtent,
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
          horizontal: isCompact ? 12 : 20, vertical: isCompact ? 8 : 16),
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
                  fontSize: isCompact ? 17 : 22,
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
