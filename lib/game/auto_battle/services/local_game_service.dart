import '../engine/game_engine.dart';
import '../models/game_snapshot.dart';
import '../engine/types.dart';

class LocalGameService {
  GameEngine? _engine;
  Function(GameSnapshot)? _onGameUpdate;
  Function(bool)? _onConnectionChanged;
  Function(String)? _onPlayerAssigned;

  void connect(
    int stage,
    PlayerData player, {
    int currentCycle = 1,
    int stageInCycle = 1,
    int totalStageNumber = 1,
  }) {
    _engine = GameEngine(
      currentStage: stage,
      initialPlayer: player,
      currentCycle: currentCycle,
      stageInCycle: stageInCycle,
      totalStageNumber: totalStageNumber,
      onUpdate: (snapshot) {
        _onGameUpdate?.call(snapshot);
      },
    );
    
    // Simulate connection delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _onConnectionChanged?.call(true);
      _onPlayerAssigned?.call('p1');
      _engine?.start();
    });
  }

  void disconnect() {
    _engine?.stop();
    _engine = null;
    _onConnectionChanged?.call(false);
  }

  void revivePlayer() {
    _engine?.revivePlayer();
  }

  void onGameUpdate(Function(GameSnapshot) callback) {
    _onGameUpdate = callback;
  }

  void onConnectionChanged(Function(bool) callback) {
    _onConnectionChanged = callback;
  }

  void onPlayerAssigned(Function(String) callback) {
    _onPlayerAssigned = callback;
  }
}
