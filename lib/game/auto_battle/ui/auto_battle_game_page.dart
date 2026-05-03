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
        _game.applySnapshot(s, myPlayerId: _myId);
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
    final compact = screenSize.width < 740 || screenSize.height < 430;
    final bottomLogPanel =
        screenSize.width < 560 || screenSize.height > screenSize.width * 1.15;
    final sidebarW = (screenSize.width * (compact ? 0.30 : 0.29))
        .clamp(compact ? 198.0 : 232.0, 304.0)
        .toDouble();
    final bottomPanelH =
        (screenSize.height * 0.23).clamp(132.0, 180.0).toDouble();
    final topH = (screenSize.height * (compact ? 0.14 : 0.13))
        .clamp(compact ? 58.0 : 64.0, compact ? 72.0 : 82.0)
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
                    topPadding: viewPadding.top + (compact ? 8 : 12),
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
    final borderWidth = compact ? 2.0 : 3.0;
    final stageFontSize = compact ? 16.0 : 20.0;
    final horizontalPadding = compact ? 8.0 : 12.0;

    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        compact ? 8 : 10,
      ),
      alignment: Alignment.bottomCenter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SketchExitButton(compact: compact, onTap: onExit),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            flex: compact ? 4 : 3,
            child: Container(
              height: compact ? 34 : 40,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: AutoBattlePalette.ink, width: borderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: AutoBattlePalette.ink,
                    offset: Offset(3, 3),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  snapshot?.isBossStage == true
                      ? 'CYCLE ${snapshot?.currentCycle ?? 1} - BOSS'
                      : 'CYCLE ${snapshot?.currentCycle ?? 1} - ${snapshot?.stageInCycle ?? stage}',
                  style: TextStyle(
                    color: (snapshot?.isBossStage == true)
                        ? AutoBattlePalette.primary
                        : AutoBattlePalette.ink,
                    fontSize: stageFontSize,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (myPlayer != null) ...[
            SizedBox(width: compact ? 7 : 10),
            Expanded(
              flex: compact ? 5 : 4,
              child: _TopPlayerVitals(player: myPlayer!, compact: compact),
            ),
          ],
          SizedBox(width: compact ? 7 : 10),
          _TopResourceCluster(
            compact: compact,
            gold: myPlayer?.gold.toInt() ?? 0,
          ),
        ],
      ),
    );
  }
}

class _TopResourceCluster extends StatelessWidget {
  final bool compact;
  final int gold;

  const _TopResourceCluster({
    required this.compact,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                '$gold',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
                bottom: BorderSide(color: AutoBattlePalette.ink, width: 2),
                right: BorderSide(color: AutoBattlePalette.ink, width: 2),
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
    final visibleCombatants = compact ? sorted.take(2).toList() : sorted;

    final myPlayer = players
        .cast<PlayerSnapshot?>()
        .firstWhere((p) => p?.id == myId, orElse: () => null);

    final sidePadding = EdgeInsets.symmetric(horizontal: compact ? 10 : 16);
    final children = <Widget>[
      SizedBox(height: topPadding),
      if (myPlayer != null) ...[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          child: _SidebarSectionTitle(label: 'PLAYER', compact: compact),
        ),
        SizedBox(height: compact ? 7 : 10),
        Padding(
          padding: sidePadding,
          child: _PlayerSidebarCard(
            player: myPlayer,
            compact: compact,
          ),
        ),
        SizedBox(height: compact ? 14 : 22),
      ],
      Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
        child: _SidebarSectionTitle(label: 'COMBATANTS', compact: compact),
      ),
      SizedBox(height: compact ? 8 : 12),
      for (var i = 0; i < visibleCombatants.length; i++) ...[
        Padding(
          padding: sidePadding,
          child: _CombatantCard(
            player: visibleCombatants[i],
            myId: myId,
            compact: compact,
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  final String label;
  final bool compact;

  const _SidebarSectionTitle({
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AutoBattlePalette.ink,
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CombatantCard extends StatelessWidget {
  final PlayerSnapshot player;
  final String? myId;
  final bool compact;

  const _CombatantCard({
    required this.player,
    required this.myId,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = player.id == myId;
    final label = isMine
        ? 'PLAYER'
        : player.isEnemy
            ? 'ENEMY'
            : 'ALLY';
    final color = isMine
        ? const Color(0xFF2563EB)
        : player.isEnemy
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AutoBattlePalette.ink, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: AutoBattlePalette.ink,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isMine ? 'YOU' : player.id.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RoleBadge(
                label: label,
                color: color,
                compact: compact,
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (player.hp / player.maxHp).clamp(0, 1).toDouble(),
              minHeight: compact ? 8 : 9,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                _hpColor(player.maxHp <= 0 ? 0 : player.hp / player.maxHp),
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'HP ${player.hp.ceil()} / ${player.maxHp.ceil()}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AutoBattlePalette.ink,
                    fontSize: compact ? 10 : 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${player.gold.toInt()} G',
                style: TextStyle(
                  color: AutoBattlePalette.gold,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final size = compact ? 36.0 : 40.0;

    return Tooltip(
      message: info['name'] as String,
      waitDuration: const Duration(milliseconds: 350),
      child: SizedBox(
        width: size + 4,
        height: size + 4,
        child: Stack(
          children: [
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AutoBattlePalette.ink,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: ready ? color.withValues(alpha: 0.18) : Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 2.2),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (!ready)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 1.0 - progress,
                        child: Container(
                          color: AutoBattlePalette.ink.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  Center(
                    child: Icon(
                      info['icon'] as IconData,
                      size: compact ? 17 : 20,
                      color: ready ? color : AutoBattlePalette.inkSubtle,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: AutoBattlePalette.ink,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        ready
                            ? info['label'] as String
                            : remaining.ceil().toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 7.5 : 8.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
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

class _TopPlayerVitals extends StatelessWidget {
  final PlayerSnapshot player;
  final bool compact;

  const _TopPlayerVitals({
    required this.player,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio =
        player.maxHp <= 0 ? 0.0 : (player.hp / player.maxHp).clamp(0.0, 1.0);

    return Container(
      height: compact ? 34 : 40,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AutoBattlePalette.ink.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'HP',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hpRatio.toDouble(),
                minHeight: compact ? 8 : 10,
                backgroundColor: const Color(0xFFEFF3F8),
                valueColor: AlwaysStoppedAnimation<Color>(_hpColor(hpRatio)),
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${player.hp.ceil()}/${player.maxHp.ceil()}',
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSidebarCard extends StatelessWidget {
  final PlayerSnapshot player;
  final bool compact;

  const _PlayerSidebarCard({
    required this.player,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = !compact && constraints.maxWidth < 248;
        final info = charDisplayInfoMap[player.characterType] ??
            charDisplayInfoMap['gunner']!;
        final preview = SizedBox(
          width: stacked ? double.infinity : (compact ? 46 : 72),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: compact ? 42 : 66,
                    height: compact ? 42 : 66,
                    decoration: BoxDecoration(
                      color: AutoBattlePalette.gold,
                      border: Border.all(
                        color: AutoBattlePalette.ink,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                CharacterBallPreview(
                  info: info,
                  size: compact ? 44 : 68,
                ),
              ],
            ),
          ),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    player.id.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _RoleBadge(
                  label: 'PLAYER',
                  color: const Color(0xFF2563EB),
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            _StatChipWrap(
              chips: [
                _StatChipData(
                  label: 'HP',
                  value: '${player.hp.ceil()}/${player.maxHp.ceil()}',
                  color: _hpColor(
                    player.maxHp <= 0 ? 0 : player.hp / player.maxHp,
                  ),
                ),
                if (player.shield > 0)
                  _StatChipData(
                    label: 'SH',
                    value: player.shield.ceil().toString(),
                    color: const Color(0xFF0EA5E9),
                  ),
                if (player.barrierHp > 0)
                  _StatChipData(
                    label: 'BR',
                    value: player.barrierHp.ceil().toString(),
                    color: const Color(0xFF4F46E5),
                  ),
              ],
              compact: compact,
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              _StatChipWrap(
                chips: [
                  _StatChipData(
                    label: 'ATK',
                    value: player.atk.toStringAsFixed(0),
                    color: const Color(0xFFDC2626),
                  ),
                  _StatChipData(
                    label: 'DEF',
                    value: player.def.toStringAsFixed(0),
                    color: const Color(0xFF059669),
                  ),
                  _StatChipData(
                    label: 'SPD',
                    value: player.speed.toStringAsFixed(1),
                    color: const Color(0xFFF59E0B),
                  ),
                ],
                compact: compact,
              ),
            ],
            SizedBox(height: compact ? 6 : 8),
            Wrap(
              spacing: compact ? 4 : 6,
              runSpacing: compact ? 4 : 6,
              children: [
                player.characterType,
                ...player.ownedWeapons.where((w) => w != player.characterType),
              ]
                  .map((w) => _WeaponStatusIcon(
                        weapon: w,
                        player: player,
                        now: DateTime.now().millisecondsSinceEpoch,
                        compact: compact,
                      ))
                  .toList(),
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutoBattlePalette.ink, width: 3.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: AutoBattlePalette.ink,
                offset: Offset(5, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 5 : 8,
                ),
                decoration: BoxDecoration(
                  color: info.bodyColor,
                  border: const Border(
                    bottom: BorderSide(color: AutoBattlePalette.ink, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        info.name.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12 : 16,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: AutoBattlePalette.ink,
                              offset: Offset(1.5, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _RoleBadge(
                      label: 'PLAYER',
                      color: AutoBattlePalette.gold,
                      compact: compact,
                      filled: true,
                      textColor: AutoBattlePalette.ink,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 10 : 12),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          preview,
                          const SizedBox(height: 10),
                          content,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          preview,
                          const SizedBox(width: 12),
                          Expanded(child: content),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;
  final bool filled;
  final Color? textColor;

  const _RoleBadge({
    required this.label,
    required this.color,
    required this.compact,
    this.filled = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled ? color : color.withValues(alpha: 0.18);
    final foregroundColor = textColor ?? (filled ? Colors.white : color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _StatChipData {
  final String label;
  final String value;
  final Color color;

  const _StatChipData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatChipWrap extends StatelessWidget {
  final List<_StatChipData> chips;
  final bool compact;

  const _StatChipWrap({
    required this.chips,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          chips.map((chip) => _StatChip(chip: chip, compact: compact)).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final _StatChipData chip;
  final bool compact;

  const _StatChip({
    required this.chip,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AutoBattlePalette.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 6,
              vertical: compact ? 4 : 5,
            ),
            color: chip.color,
            child: Text(
              chip.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 4 : 5,
            ),
            child: Text(
              chip.value,
              style: TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _hpColor(double hpRatio) {
  if (hpRatio > 0.6) return const Color(0xFF16A34A);
  if (hpRatio > 0.3) return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}
