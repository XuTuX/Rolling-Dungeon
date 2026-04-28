import 'package:circle_war/game/auto_battle/models/player_snapshot.dart';

class GameSnapshot {
  final int serverTime;
  final int currentStage;
  final double arenaWidth;
  final double arenaHeight;
  final String roundState;
  final String? winnerId;
  final int? roundEndsAt;
  final int aliveCount;
  final List<PlayerSnapshot> players;
  final List<FoodSnapshot> foods;
  final List<ProjectileSnapshot> projectiles;
  final List<HazardSnapshot> hazards;
  final List<AttackSnapshot> attacks;

  const GameSnapshot({
    required this.serverTime,
    required this.currentStage,
    required this.arenaWidth,
    required this.arenaHeight,
    required this.roundState,
    required this.winnerId,
    required this.roundEndsAt,
    required this.aliveCount,
    required this.players,
    required this.foods,
    required this.projectiles,
    required this.hazards,
    required this.attacks,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    final arena = json['arena'];

    return GameSnapshot(
      serverTime: _asInt(json['serverTime']),
      currentStage: _asInt(json['currentStage'], fallback: 1),
      arenaWidth: arena is Map<String, dynamic>
          ? _asDouble(arena['width'], fallback: 500)
          : 500,
      arenaHeight: arena is Map<String, dynamic>
          ? _asDouble(arena['height'], fallback: 500)
          : 500,
      roundState: json['roundState']?.toString() ?? 'running',
      winnerId: json['winnerId']?.toString(),
      roundEndsAt:
          json['roundEndsAt'] == null ? null : _asInt(json['roundEndsAt']),
      aliveCount: _asInt(json['aliveCount'], fallback: 4),
      players: _parseList(json['players'], PlayerSnapshot.fromJson),
      foods: _parseList(json['foods'], FoodSnapshot.fromJson),
      projectiles: _parseList(json['projectiles'], ProjectileSnapshot.fromJson),
      hazards: _parseList(json['hazards'], HazardSnapshot.fromJson),
      attacks: _parseList(json['attacks'], AttackSnapshot.fromJson),
    );
  }
}

class FoodSnapshot {
  final String id;
  final double x;
  final double y;
  final double radius;
  final double gold;
  final String kind;

  const FoodSnapshot({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.gold,
    required this.kind,
  });

  factory FoodSnapshot.fromJson(Map<String, dynamic> json) {
    return FoodSnapshot(
      id: json['id']?.toString() ?? '',
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      radius: _asDouble(json['radius'], fallback: 4),
      gold: _asDouble(json['gold'], fallback: 4),
      kind: json['kind']?.toString() ?? 'small',
    );
  }
}

class ProjectileSnapshot {
  final String id;
  final String ownerId;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double radius;
  final String color;
  final int reflectsRemaining;

  const ProjectileSnapshot({
    required this.id,
    required this.ownerId,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    this.reflectsRemaining = 0,
  });

  factory ProjectileSnapshot.fromJson(Map<String, dynamic> json) {
    return ProjectileSnapshot(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      vx: _asDouble(json['vx']),
      vy: _asDouble(json['vy']),
      radius: _asDouble(json['radius'], fallback: 5),
      color: json['color']?.toString() ?? '#FFFFFF',
      reflectsRemaining: _asInt(json['reflectsRemaining']),
    );
  }
}

class HazardSnapshot {
  final String id;
  final String ownerId;
  final String type;
  final double x;
  final double y;
  final double radius;
  final int expiresAt;

  const HazardSnapshot({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.x,
    required this.y,
    required this.radius,
    required this.expiresAt,
  });

  factory HazardSnapshot.fromJson(Map<String, dynamic> json) {
    return HazardSnapshot(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'poison',
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      radius: _asDouble(json['radius'], fallback: 24),
      expiresAt: _asInt(json['expiresAt']),
    );
  }
}

class AttackSnapshot {
  final String id;
  final String ownerId;
  final String type;
  final double x;
  final double y;
  final double radius;
  final double angle;
  final int createdAt;
  final int durationMs;
  final double scale;

  const AttackSnapshot({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.x,
    required this.y,
    required this.radius,
    required this.angle,
    required this.createdAt,
    required this.durationMs,
    this.scale = 1.0,
  });

  factory AttackSnapshot.fromJson(Map<String, dynamic> json) {
    return AttackSnapshot(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'blade',
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      radius: _asDouble(json['radius'], fallback: 62),
      angle: _asDouble(json['angle']),
      createdAt: _asInt(json['createdAt']),
      durationMs: _asInt(json['durationMs'], fallback: 220),
      scale: _asDouble(json['scale'], fallback: 1.0),
    );
  }
}

List<T> _parseList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) parser,
) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
