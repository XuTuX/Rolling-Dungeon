import 'constants.dart';

class SimulationClock {
  int lastTickAt;
  int simulationTime;
  double speed;

  SimulationClock({
    required int startedAt,
    this.speed = SIMULATION_DEFAULT_SPEED,
  })  : lastTickAt = startedAt,
        simulationTime = startedAt;

  void reset(int wallTime) {
    lastTickAt = wallTime;
    simulationTime = wallTime;
  }

  int advanceTo(int wallTime) {
    final realDt = wallTime - lastTickAt;
    lastTickAt = wallTime;

    final scaledDt = (realDt * speed).round();
    simulationTime += scaledDt;
    return scaledDt;
  }

  void setSpeed(double value) {
    speed = value.clamp(0.25, SIMULATION_FAST_SPEED).toDouble();
  }

  void holdAt(int wallTime) {
    lastTickAt = wallTime;
  }
}
