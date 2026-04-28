import 'package:circle_war/game/auto_battle/auto_battle_game.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/game_snapshot.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:circle_war/game/auto_battle/services/local_game_service.dart';
import 'package:circle_war/game/auto_battle/engine/types.dart';
import 'package:circle_war/game/auto_battle/engine/physics.dart';
import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:circle_war/screens/home_screen.dart';
import 'package:circle_war/screens/upgrade_select_screen.dart';
class AutoBattleGamePage extends StatefulWidget {
  const AutoBattleGamePage({super.key});

  @override
  State<AutoBattleGamePage> createState() => _AutoBattleGamePageState();
}

class _AutoBattleGamePageState extends State<AutoBattleGamePage> {
  late final AutoBattleGame _game;
  late final LocalGameService _localService;

  GameSnapshot? _snapshot;
  String? _myId;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<GameProgressController>();
    final player = PlayerData(
      id: 'p1',
      characterType: controller.characterType.value,
      hp: controller.playerCurrentHp.value,
      maxHp: controller.playerMaxHp.value,
      atk: controller.playerAtk.value,
      def: controller.playerDef.value,
      speed: controller.playerSpd.value,
      abilityPower: controller.playerAbilityPower.value,
      gold: controller.gold.value.toDouble(),
      totalGold: controller.gold.value.toDouble(),
      pendingUpgradeCount: 0,
      upgradeChoices: [],
      kills: 0,
      damageDealt: 0,
      damageTaken: 0,
      pos: Vec2(x: 250, y: 250),
      vel: normalize(Vec2(x: 1, y: 0.1)),
      radius: 16.0,
      activeEffects: [],
      color: '#4F8CFF',
      alive: true,
      lives: controller.lives.value,
      maxLives: 3,
      lastCollisionAt: {},
      lastPoisonDropAt: 0,
      lastShotAt: 0,
      lastBladeAt: 0,
      lastMineDropAt: 0,
    );

    _game = AutoBattleGame();
    _localService = LocalGameService()
      ..connect(controller.currentStage.value, player)
      ..onConnectionChanged((c) {
        if (!mounted) return;
        setState(() => _connected = c);
      })
      ..onPlayerAssigned((id) {
        if (!mounted) return;
        setState(() => _myId = id);
      })
      ..onGameUpdate((s) {
        if (!mounted) return;
        setState(() => _snapshot = s);
        _game.applySnapshot(s);
      });
  }

  @override
  void dispose() {
    _localService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;
    final screenSize = mediaQuery.size;
    final compact = screenSize.width < 740 || screenSize.height < 390;
    final bottomLogPanel =
        screenSize.width < 560 || screenSize.height > screenSize.width * 1.15;
    final sidebarW = (screenSize.width * (compact ? 0.24 : 0.26))
        .clamp(compact ? 156.0 : 190.0, 240.0)
        .toDouble();
    final bottomPanelH =
        (screenSize.height * 0.23).clamp(132.0, 180.0).toDouble();
    final topH = (screenSize.height * (compact ? 0.15 : 0.16))
        .clamp(compact ? 56.0 : 64.0, 80.0)
        .toDouble();

    _game.viewportPadding = EdgeInsets.only(
      top: topH + viewPadding.top,
      right: bottomLogPanel ? viewPadding.right : sidebarW + viewPadding.right,
      left: viewPadding.left,
      bottom: bottomLogPanel
          ? bottomPanelH + viewPadding.bottom
          : viewPadding.bottom,
    );

    final players = _snapshot?.players ?? const <PlayerSnapshot>[];
    final myPlayer = players.isEmpty
        ? null
        : players.firstWhere((p) => p.id == _myId, orElse: () => players.first);

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          if (bottomLogPanel)
            Column(
              children: [
                _SketchTopBar(
                  snapshot: _snapshot,
                  connected: _connected,
                  height: topH + viewPadding.top,
                  myPlayer: myPlayer,
                  compact: true,
                ),
                const Spacer(),
                Container(
                  height: bottomPanelH + viewPadding.bottom,
                  padding: EdgeInsets.only(bottom: viewPadding.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AutoBattlePalette.ink, width: 4),
                    ),
                  ),
                  child: _SketchSidebar(
                    players: players,
                    myId: _myId,
                    topPadding: 0,
                    compact: true,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _SketchTopBar(
                        snapshot: _snapshot,
                        connected: _connected,
                        height: topH + viewPadding.top,
                        myPlayer: myPlayer,
                        compact: compact,
                      ),
                      const Spacer(),
                      SizedBox(height: viewPadding.bottom + 20),
                    ],
                  ),
                ),

                // Right Sidebar: Sketch Style
                Container(
                  width: sidebarW + viewPadding.right,
                  padding: EdgeInsets.only(right: viewPadding.right),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        left:
                            BorderSide(color: AutoBattlePalette.ink, width: 4)),
                  ),
                  child: _SketchSidebar(
                    players: players,
                    myId: _myId,
                    topPadding: topH + viewPadding.top,
                    compact: compact,
                  ),
                ),
              ],
            ),
          if (_snapshot == null)
            Positioned(
              top: topH + viewPadding.top,
              left: viewPadding.left,
              right: bottomLogPanel
                  ? viewPadding.right
                  : sidebarW + viewPadding.right,
              bottom: bottomLogPanel
                  ? bottomPanelH + viewPadding.bottom
                  : viewPadding.bottom,
              child: const Center(
                child: _SketchLoadingIndicator(),
              ),
            ),
          if (_snapshot != null && myPlayer != null)
            const SizedBox.shrink(),
          if (_snapshot?.roundState == 'ended' ||
              _snapshot?.roundState == 'gameover' ||
              _snapshot?.roundState == 'victory')
            _SketchResultOverlay(snapshot: _snapshot!, myId: _myId),
        ],
      ),
    );
  }
}

class _SketchLoadingIndicator extends StatelessWidget {
  const _SketchLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutoBattlePalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AutoBattlePalette.ink, offset: Offset(5, 5)),
        ],
      ),
      child: const CircularProgressIndicator(
        color: AutoBattlePalette.ink,
        strokeWidth: 4,
      ),
    );
  }
}

class _SketchTopBar extends StatelessWidget {
  final GameSnapshot? snapshot;
  final bool connected;
  final double height;
  final PlayerSnapshot? myPlayer;
  final bool compact;

  const _SketchTopBar({
    required this.snapshot,
    required this.connected,
    required this.height,
    required this.compact,
    this.myPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final stage = snapshot?.currentStage ?? 1;
    final bottomMargin = compact ? 8.0 : 12.0;
    final borderWidth = compact ? 2.0 : 3.0;
    final stageFontSize = compact ? 16.0 : 20.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Stage Indicator (Center)
          Container(
            margin: EdgeInsets.only(bottom: bottomMargin),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: AutoBattlePalette.ink, width: borderWidth),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'STAGE $stage',
                style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: stageFontSize,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Gold & Lives (Grouped)
          Container(
            margin: EdgeInsets.only(bottom: bottomMargin),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gold
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 10,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AutoBattlePalette.gold,
                    border:
                        Border.all(color: AutoBattlePalette.ink, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.white, size: compact ? 14 : 16),
                      SizedBox(width: compact ? 2 : 4),
                      Text(
                        '${myPlayer?.gold.toInt() ?? 0}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                // Lives
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 6,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AutoBattlePalette.ink, width: 2),
                      bottom:
                          BorderSide(color: AutoBattlePalette.ink, width: 2),
                      right:
                          BorderSide(color: AutoBattlePalette.ink, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final hasLife = myPlayer != null && i < myPlayer!.lives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Icon(
                          hasLife ? Icons.favorite : Icons.favorite_border,
                          color: hasLife
                              ? AutoBattlePalette.primary
                              : AutoBattlePalette.ink.withValues(alpha: 0.2),
                          size: compact ? 12 : 14,
                        ),
                      );
                    }),
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

class _SketchSidebar extends StatelessWidget {
  final List<PlayerSnapshot> players;
  final String? myId;
  final double topPadding;
  final bool compact;

  const _SketchSidebar({
    required this.players,
    required this.myId,
    required this.topPadding,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = players.where((p) => !p.isEnemy || p.maxHp >= 500).toList();
    final sorted = List<PlayerSnapshot>.from(filtered)
      ..sort((a, b) => b.hp.compareTo(a.hp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPadding + (compact ? 12 : 20)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24),
          child: Text(
            'BATTLE LOG',
            style: TextStyle(
              color: AutoBattlePalette.ink,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => SizedBox(height: compact ? 10 : 16),
            itemBuilder: (context, i) {
              final p = sorted[i];
              final isMe = p.id == myId;
              return Container(
                padding: EdgeInsets.all(compact ? 9 : 12),
                decoration: BoxDecoration(
                  color: isMe
                      ? p.flutterColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                      color: isMe ? p.flutterColor : AutoBattlePalette.ink,
                      width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            p.id.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AutoBattlePalette.ink,
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text('${p.gold.toInt()} G',
                            style: TextStyle(
                                color: AutoBattlePalette.gold,
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Container(
                      height: compact ? 10 : 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: AutoBattlePalette.ink, width: 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (p.hp / p.maxHp).clamp(0, 1),
                        child: Container(color: p.flutterColor),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SketchResultOverlay extends StatelessWidget {
  final GameSnapshot snapshot;
  final String? myId;
  const _SketchResultOverlay({required this.snapshot, required this.myId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameProgressController>();
    final win = snapshot.roundState == 'victory'; // all enemies dead
    final dead = snapshot.roundState == 'gameover'; // player dead
    final isFinalClear = win && ctrl.isFinalStage;

    // Determine title and color
    String title;
    Color bgColor;

    if (isFinalClear) {
      title = 'FINAL VICTORY!';
      bgColor = AutoBattlePalette.mint;
    } else if (win) {
      title = 'STAGE CLEAR!';
      bgColor = AutoBattlePalette.gold;
    } else if (dead && ctrl.lives.value <= 1) {
      title = 'GAME OVER';
      bgColor = AutoBattlePalette.primary;
    } else {
      title = 'DEFEAT';
      bgColor = AutoBattlePalette.primary;
    }

    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 390 || constraints.maxWidth < 740;
          final titleFontSize = (constraints.maxWidth * 0.075)
              .clamp(compact ? 28.0 : 36.0, 48.0)
              .toDouble();
          final horizontalPadding =
              (constraints.maxWidth * 0.07).clamp(28.0, 60.0).toDouble();
          final verticalPadding =
              (constraints.maxHeight * 0.07).clamp(16.0, 30.0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Big Title Banner ──
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 6),
                      boxShadow: const [
                        BoxShadow(
                          color: AutoBattlePalette.ink,
                          offset: Offset(10, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  // ── Subtitle ──
                  if (win && !isFinalClear)
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 12 : 18),
                      child: Text(
                        'STAGE ${ctrl.currentStage.value} COMPLETED',
                        style: TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: compact ? 14 : 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (dead && ctrl.lives.value > 1)
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 12 : 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LIVES:  ',
                            style: TextStyle(
                              color: AutoBattlePalette.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          ...List.generate(ctrl.lives.value - 1, (_) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(Icons.favorite,
                                  color: AutoBattlePalette.primary,
                                  size: 18),
                            );
                          }),
                        ],
                      ),
                    ),

                  // ── Action Button ──
                  Padding(
                    padding: EdgeInsets.only(top: compact ? 20 : 32),
                    child: GestureDetector(
                      onTap: () {
                        if (isFinalClear) {
                          // Final victory → main menu
                          Get.offAll(() => const HomeScreen());
                        } else if (win) {
                          // Stage clear → upgrade select
                          Get.off(() => const UpgradeSelectScreen());
                        } else if (dead && ctrl.lives.value > 1) {
                          // Still have lives → retry
                          ctrl.loseLife();
                          Get.off(() => const AutoBattleGamePage(),
                              preventDuplicates: false);
                        } else {
                          // Total game over → main menu
                          Get.offAll(() => const HomeScreen());
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: AutoBattlePalette.ink, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: AutoBattlePalette.ink,
                                offset: Offset(5, 5)),
                          ],
                        ),
                        child: Text(
                          isFinalClear
                              ? 'MAIN MENU'
                              : win
                                  ? 'CONTINUE'
                                  : (dead && ctrl.lives.value > 1)
                                      ? 'RETRY'
                                      : 'MAIN MENU',
                          style: const TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
