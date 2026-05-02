import 'dart:math' as math;
import 'package:circle_war/game/auto_battle/auto_battle_game.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/game_snapshot.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:circle_war/game/auto_battle/services/local_game_service.dart';
import 'package:circle_war/game/auto_battle/engine/types.dart';
import 'package:circle_war/game/auto_battle/engine/physics.dart';
import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:circle_war/screens/home_screen.dart';
import 'package:circle_war/screens/upgrade_select_screen.dart';
import 'package:circle_war/screens/run_results_screen.dart';
import 'package:circle_war/game/auto_battle/ui/character_display.dart';

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
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<GameProgressController>();
    final metaController = Get.find<MetaProgressController>();
    final player = PlayerData(
      id: 'p1',
      characterType: controller.characterType.value,
      hp: controller.playerCurrentHp.value,
      maxHp: controller.playerMaxHp.value,
      atk: controller.playerAtk.value,
      def: controller.playerDef.value,
      speed: controller.playerSpd.value,
      abilityPower: controller.playerAbilityPower.value,
      shield: controller.playerShield.value,
      maxShield: controller.playerMaxShield.value,
      weaponLevel: controller.playerWeaponLevel.value,
      weaponCount: controller.playerWeaponCount.value,
      bulletReflectCount: controller.playerBulletReflectCount.value,
      bulletsPerWeapon: controller.playerBulletsPerWeapon.value,
      regen: controller.playerRegen.value,
      lifesteal: controller.playerLifesteal.value,
      critChance: controller.playerCritChance.value,
      barrierHp: controller.playerBarrierHp.value,
      barrierMaxHp: controller.playerBarrierMaxHp.value,
      gold: controller.gold.value.toDouble(),
      totalGold: controller.gold.value.toDouble(),
      pendingUpgradeCount: 0,
      upgradeChoices: [],
      kills: controller.runEnemiesKilled.value,
      damageDealt: controller.runDamageDealt.value,
      damageTaken: 0,
      pos: Vec2(x: 250, y: 250),
      vel: normalize(Vec2(x: 1, y: 0.1)),
      radius: controller.playerRadius.value,
      activeEffects: [],
      // Ensure the selected characterType is always available, even if simulating an unowned weapon
      ownedWeapons: {
        ...controller.ownedWeapons,
        controller.characterType.value,
      }.toList(),
      weaponLevels: metaController.weaponLevels,
      color: controller.characterType.value == 'circle'
          ? '#F87171'
          : controller.characterType.value == 'square'
              ? '#3B82F6'
              : controller.characterType.value == 'triangle'
                  ? '#EAB308'
                  : '#4F8CFF',
      alive: true,
      lives: controller.lives.value,
      maxLives: 3,
      lastCollisionAt: {},
      lastPoisonDropAt: 0,
      lastShotAt: 0,
      lastBladeAt: 0,
      lastMineDropAt: 0,
      lastAttackAt: 0,
      targetAngle: 0,
    );

    _game = AutoBattleGame();
    _localService = LocalGameService()
      ..connect(
        controller.currentStage.value,
        player,
        currentCycle: controller.currentCycle.value,
        stageInCycle: controller.stageInCycle.value,
        totalStageNumber: controller.totalStageNumber.value,
      )
      ..onConnectionChanged((c) {
        if (!mounted || _navigating) return;
        setState(() => _connected = c);
      })
      ..onPlayerAssigned((id) {
        if (!mounted || _navigating) return;
        setState(() => _myId = id);
      })
      ..onGameUpdate((s) {
        if (!mounted || _navigating) return;

        // Perform Rx updates in a post-frame callback to avoid "setState() called during build" errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _navigating) return;
          final me = s.players
              .cast<PlayerSnapshot?>()
              .firstWhere((p) => p?.id == 'p1', orElse: () => null);
          if (me != null) {
            controller.playerCurrentHp.value = me.hp;
            controller.gold.value = me.gold.round();
            controller.playerShield.value = me.shield;
            controller.playerBarrierHp.value = me.barrierHp;
          }
        });

        setState(() => _snapshot = s);
        _game.applySnapshot(s);
        _handleTerminalSnapshot(s, controller);
      });
  }

  void _handleTerminalSnapshot(
    GameSnapshot snapshot,
    GameProgressController controller,
  ) {
    if (_navigating) return;

    final win = snapshot.roundState == 'victory';
    final dead = snapshot.roundState == 'gameover';
    if (!win && !dead) return;

    final me = snapshot.players
        .cast<PlayerSnapshot?>()
        .firstWhere((p) => p?.id == 'p1', orElse: () => null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigating) return;

      // Update terminal stats safely inside post-frame
      if (me != null) {
        controller.runEnemiesKilled.value = me.kills;
        controller.runDamageDealt.value = me.damageDealt;
      }

      if (win) {
        // Always go to upgrade select (game is infinite, never "final")
        _stopAndNavigate(() => const UpgradeSelectScreen());
      } else if (dead && controller.lives.value > 1) {
        controller.loseLife();
        _localService.revivePlayer(controller.lives.value);
      } else {
        // Game over — go to run results
        _stopAndNavigate(() => const RunResultsScreen(), offAll: true);
      }
    });
  }

  /// Stop engine and prevent further callbacks before navigating.
  void _stopAndNavigate(Widget Function() pageBuilder, {bool offAll = false}) {
    if (_navigating) return;
    _navigating = true;
    _localService.disconnect();
    if (offAll) {
      Get.offAll(pageBuilder);
    } else {
      Get.off(pageBuilder, preventDuplicates: false);
    }
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
                  onExit: () =>
                      _stopAndNavigate(() => const HomeScreen(), offAll: true),
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
                        onExit: () => _stopAndNavigate(() => const HomeScreen(),
                            offAll: true),
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
          if (_snapshot != null && myPlayer != null) const SizedBox.shrink(),
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
  final VoidCallback onExit;

  const _SketchTopBar({
    required this.snapshot,
    required this.connected,
    required this.height,
    required this.compact,
    required this.onExit,
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
          _SketchExitButton(compact: compact, onTap: onExit),
          SizedBox(width: compact ? 8 : 14),

          // Stage Indicator (Center)
          Container(
            margin: EdgeInsets.only(bottom: bottomMargin),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: AutoBattlePalette.ink, width: borderWidth),
              boxShadow: const [
                BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4))
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                snapshot?.isBossStage == true
                    ? 'CYCLE ${snapshot?.currentCycle ?? 1} — BOSS'
                    : 'CYCLE ${snapshot?.currentCycle ?? 1} — ${snapshot?.stageInCycle ?? stage}',
                style: TextStyle(
                    color: (snapshot?.isBossStage == true)
                        ? AutoBattlePalette.primary
                        : AutoBattlePalette.ink,
                    fontSize: stageFontSize,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          SizedBox(width: compact ? 8 : 20),

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
                    border: Border.all(color: AutoBattlePalette.ink, width: 2),
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
                Obx(() {
                  final lives = Get.find<GameProgressController>().lives.value;
                  return Container(
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
                        final hasLife = i < lives;
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
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchExitButton extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;

  const _SketchExitButton({
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 8 : 12),
        width: compact ? 38 : 44,
        height: compact ? 34 : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: AutoBattlePalette.ink, width: compact ? 2 : 3),
          boxShadow: const [
            BoxShadow(color: AutoBattlePalette.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(
          Icons.arrow_back,
          color: AutoBattlePalette.ink,
          size: compact ? 18 : 22,
        ),
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
    final filtered =
        players.where((p) => !p.isEnemy || p.maxHp >= 500).toList();
    final sorted = List<PlayerSnapshot>.from(filtered)
      ..sort((a, b) => b.hp.compareTo(a.hp));

    final myPlayer = players
        .cast<PlayerSnapshot?>()
        .firstWhere((p) => p?.id == myId, orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPadding + (compact ? 12 : 20)),

        // ── MY CHARACTER Section ──
        if (myPlayer != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24),
            child: Text(
              'MY CHARACTER',
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            child: Container(
              padding: EdgeInsets.all(compact ? 10 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AutoBattlePalette.ink, offset: Offset(4, 4)),
                ],
              ),
              child: Row(
                children: [
                  CharacterBallPreview(
                    info: charDisplayInfoMap[myPlayer.characterType] ??
                        charDisplayInfoMap['gunner']!,
                    size: compact ? 48 : 64,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myPlayer.id.toUpperCase(),
                          style: TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              myPlayer.characterType,
                              ...myPlayer.ownedWeapons
                                  .where((w) => w != myPlayer.characterType),
                            ]
                                .map((w) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: _WeaponStatusIcon(
                                        weapon: w,
                                        player: myPlayer,
                                        now: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        compact: compact,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
        ],

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

              return Container(
                padding: EdgeInsets.all(compact ? 9 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AutoBattlePalette.ink, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AutoBattlePalette.ink,
                      offset: Offset(4, 4),
                    ),
                  ],
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
                    // HP Bar
                    Container(
                      height: compact ? 12 : 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: AutoBattlePalette.ink, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                              color: AutoBattlePalette.ink,
                              offset: Offset(2, 2)),
                        ],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (p.hp / p.maxHp).clamp(0, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.flutterColor,
                            border: const Border(
                              right: BorderSide(
                                  color: AutoBattlePalette.ink, width: 2),
                            ),
                          ),
                        ),
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

class _WeaponStatusIcon extends StatelessWidget {
  final String weapon;
  final PlayerSnapshot player;
  final int now;
  final bool compact;

  const _WeaponStatusIcon({
    required this.weapon,
    required this.player,
    required this.now,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getWeaponInfo(weapon);
    final bool isPersistent = info['persistent'] == true;
    final color = info['color'] as Color;
    final int lastAction = _getLastActionTime(weapon, player);
    final double cooldownMs = _getCooldownMs(weapon).toDouble();

    final elapsed = now - lastAction;
    final remaining = math.max(0.0, (cooldownMs - elapsed) / 1000.0);
    final progress = (elapsed / cooldownMs).clamp(0.0, 1.0);
    final ready = isPersistent || remaining <= 0;
    final size = compact ? 38.0 : 42.0;

    return Tooltip(
      message: info['name'] as String,
      waitDuration: const Duration(milliseconds: 350),
      child: SizedBox(
        width: size + 4,
        height: size + 4,
        child: Stack(
          children: [
            // Hard Shadow Layer
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AutoBattlePalette.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Main Body
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AutoBattlePalette.ink,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Icon Background (Color)
                  Positioned.fill(
                    child: Container(
                      color: ready
                          ? color.withValues(alpha: 0.1)
                          : Colors.grey[200],
                    ),
                  ),

                  // Cooldown Fill (Sketchy Overlay)
                  if (!ready)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 1.0 - progress,
                        child: Container(
                          color: AutoBattlePalette.ink.withValues(alpha: 0.4),
                          child: CustomPaint(
                            painter: _HatchingPainter(),
                          ),
                        ),
                      ),
                    ),

                  // Center Icon
                  Center(
                    child: Icon(
                      info['icon'] as IconData,
                      size: compact ? 18 : 22,
                      color: ready ? color : AutoBattlePalette.inkSubtle,
                    ),
                  ),

                  // Label Badge (Ink Tag)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: const BoxDecoration(
                        color: AutoBattlePalette.ink,
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(4)),
                      ),
                      child: Text(
                        ready
                            ? info['label'] as String
                            : remaining.ceil().toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 8 : 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getWeaponInfo(String type) {
    switch (type) {
      case 'minigun':
        return {
          'icon': Icons.bolt,
          'label': 'FAST',
          'name': '미니건',
          'color': const Color(0xFF475569),
          'persistent': false,
        };
      case 'long_gun':
        return {
          'icon': Icons.center_focus_strong,
          'label': 'SNIP',
          'name': '장거리 포',
          'color': const Color(0xFFDC2626),
          'persistent': false,
        };
      case 'poison':
        return {
          'icon': Icons.bubble_chart,
          'label': 'GAS',
          'name': '독 가스 분무기',
          'color': const Color(0xFF16A34A),
          'persistent': true,
        };
      case 'blade':
        return {
          'icon': Icons.autorenew, // Rotates/Spins
          'label': 'SPIN',
          'name': '회전 칼날',
          'color': const Color(0xFF7C3AED),
          'persistent': true,
        };
      case 'heavy_blade':
        return {
          'icon': Icons.gavel, // Heavy impact
          'label': 'HEVY',
          'name': '거대 대검',
          'color': const Color(0xFF0F172A),
          'persistent': true,
        };
      case 'miner':
        return {
          'icon': Icons.dangerous,
          'label': 'MINE',
          'name': '지뢰 매설기',
          'color': const Color(0xFFEF4444),
          'persistent': false,
        };
      case 'footsteps':
        return {
          'icon': Icons.whatshot,
          'label': 'FIRE',
          'name': '불타는 발자국',
          'color': const Color(0xFFF97316),
          'persistent': true,
        };
      case 'burst':
        return {
          'icon': Icons.flare,
          'label': 'EXPL',
          'name': '전방위 버스트',
          'color': const Color(0xFFFACC15),
          'persistent': false,
        };
      case 'ricochet':
        return {
          'icon': Icons.keyboard_return,
          'label': 'BOUNC',
          'name': '도탄 사격',
          'color': const Color(0xFF0284C7),
          'persistent': false,
        };
      case 'aura':
        return {
          'icon': Icons.shield,
          'label': 'AURA',
          'name': '수호자의 오라',
          'color': const Color(0xFFA855F7),
          'persistent': true,
        };
      case 'gunner':
      default:
        return {
          'icon': Icons.gps_fixed,
          'label': 'SHOT',
          'name': '기본 사격',
          'color': AutoBattlePalette.primary,
          'persistent': false,
        };
    }
  }

  int _getLastActionTime(String type, PlayerSnapshot p) {
    switch (type) {
      case 'poison':
      case 'footsteps':
        return p.lastPoisonDropAt;
      case 'blade':
      case 'heavy_blade':
        return p.lastBladeAt;
      case 'miner':
        return p.lastMineDropAt;
      case 'minigun':
      case 'long_gun':
      case 'ricochet':
      case 'burst':
      case 'gunner':
      default:
        return p.lastShotAt;
    }
  }

  int _getCooldownMs(String type) {
    switch (type) {
      case 'minigun':
        return (WEAPON_FIRE_INTERVAL_MS * 0.4).round();
      case 'long_gun':
        return (WEAPON_FIRE_INTERVAL_MS * 1.8).round();
      case 'burst':
        return BURST_FIRE_MS;
      case 'miner':
        return MINER_DROP_MS;
      case 'poison':
        return POISON_DROP_MS;
      case 'footsteps':
        return FOOTSTEPS_DROP_MS;
      case 'ricochet':
      case 'gunner':
      default:
        return WEAPON_FIRE_INTERVAL_MS;
    }
  }
}

/// Simple Hatching effect for a sketchy cooldown look
class _HatchingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    const spacing = 4.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
