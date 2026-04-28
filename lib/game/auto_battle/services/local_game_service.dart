import '../engine/game_engine.dart';
import '../models/game_snapshot.dart';

class LocalGameService {
  GameEngine? _engine;
  Function(GameSnapshot)? _onGameUpdate;
  Function(bool)? _onConnectionChanged;
  Function(String)? _onPlayerAssigned;

  void connect() {
    _engine = GameEngine(
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

  void sendUpgrade(String type) {
    _engine?.handleUpgrade(type);
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
