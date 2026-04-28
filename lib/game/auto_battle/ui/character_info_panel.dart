import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:flutter/material.dart';

class CharacterInfoPanel extends StatelessWidget {
  final PlayerSnapshot? player;
  final String roundState;
  final ValueChanged<String> onUpgradeSelected;

  const CharacterInfoPanel({
    super.key,
    required this.player,
    required this.roundState,
    required this.onUpgradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) return const SizedBox.shrink();

    final hasUpgrades = player!.upgradeChoices.isNotEmpty;
    final isUpgrading = roundState == 'upgrading';

    if (!hasUpgrades && !isUpgrading) return const SizedBox.shrink();

    return Stack(
      children: [
        // Semi-transparent Paper Overlay
        Positioned.fill(
          child: Container(
              color: AutoBattlePalette.background.withValues(alpha: 0.9)),
        ),

        // Content
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 420 || constraints.maxWidth < 760;
            final titleFontSize = (constraints.maxWidth * 0.045)
                .clamp(compact ? 22.0 : 28.0, 32.0)
                .toDouble();
            final cardHeight = (constraints.maxHeight * (compact ? 0.62 : 0.66))
                .clamp(compact ? 230.0 : 300.0, 380.0)
                .toDouble();
            final cardWidth = (constraints.maxWidth * (compact ? 0.34 : 0.28))
                .clamp(compact ? 198.0 : 230.0, 260.0)
                .toDouble();
            final horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(18.0, 40.0).toDouble();
            final gap = (constraints.maxHeight * 0.07)
                .clamp(compact ? 14.0 : 24.0, 40.0)
                .toDouble();

            return Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasUpgrades) ...[
                        Text(
                          'AUGMENT SELECTION',
                          style: TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: cardHeight,
                          child: ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            itemCount: player!.upgradeChoices.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(width: compact ? 18 : 32),
                            itemBuilder: (context, i) {
                              final choice = player!.upgradeChoices[i];
                              return _SketchAugmentCard(
                                choice: choice,
                                width: cardWidth,
                                compact: compact,
                                onTap: () => onUpgradeSelected(choice.type),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(
                            color: AutoBattlePalette.ink, strokeWidth: 6),
                        const SizedBox(height: 24),
                        Text(
                          'WAITING FOR OTHERS...',
                          style: TextStyle(
                            color: AutoBattlePalette.inkSubtle,
                            fontSize: compact ? 16 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SketchAugmentCard extends StatelessWidget {
  final UpgradeOption choice;
  final double width;
  final bool compact;
  final VoidCallback onTap;

  const _SketchAugmentCard({
    required this.choice,
    required this.width,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getChoiceColor(choice.type);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(compact ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: AutoBattlePalette.ink, width: compact ? 3 : 4),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(8, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
                  ),
                  child: Text(
                    choice.rarity.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(height: compact ? 14 : 24),
                Text(
                  choice.title,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: compact ? 8 : 12),
                Expanded(
                  child: Text(
                    choice.description,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                        color: AutoBattlePalette.inkSubtle,
                        fontSize: compact ? 12 : 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 9 : 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    choice.statPreview,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AutoBattlePalette.ink,
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getChoiceColor(String type) {
    switch (type) {
      case 'assault':
        return AutoBattlePalette.primary;
      case 'guard':
        return AutoBattlePalette.secondary;
      case 'haste':
        return AutoBattlePalette.gold;
      case 'vitality':
        return AutoBattlePalette.mint;
      default:
        return Colors.grey;
    }
  }
}
