import 'package:circle_war/game/auto_battle/auto_battle_game.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/models/game_snapshot.dart';
import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';
import 'package:circle_war/game/auto_battle/services/local_game_service.dart';
import 'package:circle_war/game/auto_battle/ui/character_info_panel.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

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
    _game = AutoBattleGame();
    _localService = LocalGameService()
      ..connect()
      ..onConnectionChanged((c) => setState(() => _connected = c))
      ..onPlayerAssigned((id) => setState(() => _myId = id))
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
            CharacterInfoPanel(
              player: myPlayer,
              roundState: _snapshot!.roundState,
              onUpgradeSelected: _localService.sendUpgrade,
            ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Connection (Compact)
          Flexible(
            flex: 2,
            child: Container(
              margin: EdgeInsets.only(bottom: bottomMargin),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutoBattlePalette.ink, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: connected
                          ? AutoBattlePalette.mint
                          : AutoBattlePalette.primary,
                      border:
                          Border.all(color: AutoBattlePalette.ink, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        connected ? 'ON' : 'OFF',
                        style: const TextStyle(
                            color: AutoBattlePalette.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Stage Indicator (Center)
          Flexible(
            flex: 4,
            child: Container(
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
          ),

          const Spacer(),

          // Gold & Lives (Grouped)
          Flexible(
            flex: 5,
            child: Container(
              margin: EdgeInsets.only(bottom: bottomMargin),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold
                  Flexible(
                    child: Container(
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
                      children: List.generate(5, (i) {
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
    final win = snapshot.winnerId == myId;
    final isGameOver = snapshot.roundState == 'gameover';
    final isVictory = snapshot.roundState == 'victory';

    String title =
        snapshot.winnerId == null ? 'DRAW' : (win ? 'VICTORY' : 'DEFEAT');
    Color bgColor = win ? AutoBattlePalette.gold : AutoBattlePalette.primary;

    if (isGameOver) {
      title = 'GAME OVER';
      bgColor = AutoBattlePalette.primary;
    } else if (isVictory) {
      title = 'FINAL VICTORY';
      bgColor = AutoBattlePalette.mint;
    }

    return Container(
      color: Colors.white.withValues(alpha: 0.8),
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
          final playerIndex = snapshot.players.indexWhere((p) => p.id == myId);
          final lives =
              playerIndex == -1 ? 0 : snapshot.players[playerIndex].lives;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (!isGameOver && !isVictory)
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 14 : 20),
                      child: Text(
                        win ? 'CHOOSE YOUR AUGMENT' : 'LIVES REMAINING: $lives',
                        style: TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: compact ? 15 : 18,
                          fontWeight: FontWeight.bold,
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
