class Vec2 {
  double x;
  double y;

  Vec2({required this.x, required this.y});

  Vec2 clone() => Vec2(x: x, y: y);
}

class ActiveEffect {
  String type;
  int durationMs;

  ActiveEffect({required this.type, required this.durationMs});
}

class UpgradeOptionData {
  String type;
  String rarity;
  String title;
  String description;
  String statPreview;

  UpgradeOptionData({
    required this.type,
    required this.rarity,
    required this.title,
    required this.description,
    required this.statPreview,
  });
}

class PlayerData {
  String id;
  String characterType;
  bool isEnemy;

  double hp;
  double maxHp;
  double atk;
  double def;
  double speed;
  double abilityPower;
  double shield;
  double maxShield;
  int weaponLevel;
  int weaponCount;
  int bulletReflectCount;
  int bulletsPerWeapon;
  double regen;
  double lifesteal;
  double barrierHp;
  double barrierMaxHp;

  double gold;
  double totalGold;
  int pendingUpgradeCount;
  List<UpgradeOptionData> upgradeChoices;
  int kills;
  double damageDealt;
  double damageTaken;

  Vec2 pos;
  Vec2 vel;
  double radius;

  List<ActiveEffect> activeEffects;
  String color;
  bool alive;
  int lives;
  int maxLives;

  Map<String, int> lastCollisionAt;
  int lastPoisonDropAt;
  int lastShotAt;
  int lastBladeAt;
  int lastMineDropAt;
  int lastAttackAt;
  int lastAbilityAt;
  double targetAngle;
  String enemyType;
  String enemyAbility;

  PlayerData({
    required this.id,
    required this.characterType,
    this.isEnemy = false,
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
    required this.pendingUpgradeCount,
    required this.upgradeChoices,
    required this.kills,
    required this.damageDealt,
    required this.damageTaken,
    required this.pos,
    required this.vel,
    required this.radius,
    required this.activeEffects,
    required this.color,
    required this.alive,
    required this.lives,
    required this.maxLives,
    required this.lastCollisionAt,
    required this.lastPoisonDropAt,
    required this.lastShotAt,
    required this.lastBladeAt,
    required this.lastMineDropAt,
    this.lastAttackAt = 0,
    this.lastAbilityAt = 0,
    this.targetAngle = 0,
    this.enemyType = 'none',
    this.enemyAbility = 'none',
  });
}

class FoodData {
  String id;
  Vec2 pos;
  double radius;
  double gold;
  String kind;

  FoodData({
    required this.id,
    required this.pos,
    required this.radius,
    required this.gold,
    required this.kind,
  });
}

class ProjectileData {
  String id;
  String ownerId;
  Vec2 pos;
  Vec2 vel;
  double radius;
  String color;
  int reflectsRemaining;

  ProjectileData({
    required this.id,
    required this.ownerId,
    required this.pos,
    required this.vel,
    required this.radius,
    required this.color,
    this.reflectsRemaining = 0,
  });
}

class HazardData {
  String id;
  String ownerId;
  String type;
  Vec2 pos;
  double radius;
  int expiresAt;
  Map<String, int> lastDamageAt;

  HazardData({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.pos,
    required this.radius,
    required this.expiresAt,
    required this.lastDamageAt,
  });
}

class AttackEffectData {
  String id;
  String ownerId;
  String type;
  Vec2 pos;
  double radius;
  double angle;
  int createdAt;
  int durationMs;
  double scale;

  AttackEffectData({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.pos,
    required this.radius,
    required this.angle,
    required this.createdAt,
    required this.durationMs,
    this.scale = 1.0,
  });
}
