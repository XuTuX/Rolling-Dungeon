import 'package:flutter/material.dart';

class PlayerSnapshot {
  final String id;
  final String characterType;
  final bool isEnemy;
  final double hp;
  final double maxHp;
  final double atk;
  final double def;
  final double speed;
  final double abilityPower;
  final double shield;
  final double maxShield;
  final int weaponLevel;
  final int weaponCount;
  final int bulletReflectCount;
  final int bulletsPerWeapon;
  final double regen;
  final double lifesteal;
  final double barrierHp;
  final double barrierMaxHp;
  final double gold;
  final double totalGold;
  final int unspentUpgrades;
  final List<UpgradeOption> upgradeChoices;
  final int kills;
  final double damageDealt;
  final double damageTaken;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double radius;
  final String color;
  final bool alive;
  final int lives;
  final int maxLives;
  final int lastAttackAt;
  final double targetAngle;

  const PlayerSnapshot({
    required this.id,
    required this.characterType,
    required this.isEnemy,
    required this.hp,
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.speed,
    required this.abilityPower,
    this.shield = 0,
    this.maxShield = 0,
    this.weaponLevel = 0,
    this.weaponCount = 1,
    this.bulletReflectCount = 0,
    this.bulletsPerWeapon = 1,
    this.regen = 0,
    this.lifesteal = 0,
    this.barrierHp = 0,
    this.barrierMaxHp = 0,
    required this.gold,
    required this.totalGold,
    required this.unspentUpgrades,
    required this.upgradeChoices,
    required this.kills,
    required this.damageDealt,
    required this.damageTaken,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.alive,
    required this.lives,
    required this.maxLives,
    this.lastAttackAt = 0,
    this.targetAngle = 0,
  });

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      id: json['id']?.toString() ?? '',
      characterType: json['characterType']?.toString() ?? 'poison',
      isEnemy: json['isEnemy'] == true,
      hp: _asDouble(json['hp']),
      maxHp: _asDouble(json['maxHp'], fallback: 100),
      atk: _asDouble(json['atk']),
      def: _asDouble(json['def']),
      speed: _asDouble(json['speed']),
      abilityPower: _asDouble(json['abilityPower'], fallback: 1),
      shield: _asDouble(json['shield']),
      maxShield: _asDouble(json['maxShield']),
      weaponLevel: _asInt(json['weaponLevel']),
      weaponCount: _asInt(json['weaponCount'], fallback: 1),
      bulletReflectCount: _asInt(json['bulletReflectCount']),
      bulletsPerWeapon: _asInt(json['bulletsPerWeapon'], fallback: 1),
      regen: _asDouble(json['regen']),
      lifesteal: _asDouble(json['lifesteal']),
      barrierHp: _asDouble(json['barrierHp']),
      barrierMaxHp: _asDouble(json['barrierMaxHp']),
      gold: _asDouble(json['gold']),
      totalGold: _asDouble(json['totalGold']),
      unspentUpgrades: _asInt(json['unspentUpgrades']),
      upgradeChoices:
          _parseList(json['upgradeChoices'], UpgradeOption.fromJson),
      kills: _asInt(json['kills']),
      damageDealt: _asDouble(json['damageDealt']),
      damageTaken: _asDouble(json['damageTaken']),
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      vx: _asDouble(json['vx']),
      vy: _asDouble(json['vy']),
      radius: _asDouble(json['radius'], fallback: 18),
      color: json['color']?.toString() ?? '#9CA3AF',
      alive: json['alive'] == true,
      lives: _asInt(json['lives'], fallback: 5),
      maxLives: _asInt(json['maxLives'], fallback: 5),
      lastAttackAt: _asInt(json['lastAttackAt']),
      targetAngle: _asDouble(json['targetAngle']),
    );
  }

  Color get flutterColor {
    final hex = color.replaceAll('#', '');
    final value = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.tryParse(value, radix: 16) ?? 0xFF9CA3AF);
  }
}

class UpgradeOption {
  final String type;
  final String rarity;
  final String title;
  final String description;
  final String statPreview;

  UpgradeOption({
    required this.type,
    required this.rarity,
    required this.title,
    required this.description,
    required this.statPreview,
  });

  factory UpgradeOption.fromJson(Map<String, dynamic> json) {
    return UpgradeOption(
      type: json['type'] as String,
      rarity: json['rarity'] as String? ?? 'common',
      title: json['title'] as String,
      description: json['description'] as String,
      statPreview: json['statPreview'] as String,
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
