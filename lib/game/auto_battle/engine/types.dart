class Vec2 {
  double x;
  double y;

  Vec2({required this.x, required this.y});

  Vec2 clone() => Vec2(x: x, y: y);
}

class ActiveEffect {
  String type;
  int expiresAt;

  ActiveEffect({required this.type, required this.expiresAt});
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

  List<String> ownedWeapons;
  Map<String, int> weaponLevels;
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
    this.ownedWeapons = const [],
    this.weaponLevels = const {},
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

  PlayerSnapshot toSnapshot() => PlayerSnapshot(
        id: id,
        characterType: characterType,
        isEnemy: isEnemy,
        hp: hp,
        maxHp: maxHp,
        atk: atk,
        def: def,
        speed: speed,
        abilityPower: abilityPower,
        shield: shield,
        maxShield: maxShield,
        weaponLevel: weaponLevel,
        weaponCount: weaponCount,
        bulletReflectCount: bulletReflectCount,
        bulletsPerWeapon: bulletsPerWeapon,
        regen: regen,
        kills: kills,
        score: gold.toInt(), // mapping gold to score for UI
        gold: gold,
        totalGold: totalGold,
        radius: radius,
        pos: pos,
        vel: vel,
        alive: alive,
        barrierHp: barrierHp,
        barrierMaxHp: barrierMaxHp,
        activeEffects: activeEffects
            .map((e) => ActiveEffect(
                  type: e.type,
                  value: e.value,
                  endsAt: e.endsAt,
                ))
            .toList(),
      );

  double takeDamage(double amount) {
    if (!alive) return 0;
    final prev = hp;
    hp = math.max(0, hp - amount);
    final actual = prev - hp;
    if (hp <= 0) alive = false;
    return actual;
  }
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

  FoodSnapshot toSnapshot() => FoodSnapshot(
        id: id,
        type: kind,
        pos: pos,
        value: gold,
      );
}

class ProjectileData {
  String id;
  String ownerId;
  Vec2 pos;
  Vec2 vel;
  double radius;
  String color;
  int reflectsRemaining;
  double damageMult;

  ProjectileData({
    required this.id,
    required this.ownerId,
    required this.pos,
    required this.vel,
    required this.radius,
    required this.color,
    this.reflectsRemaining = 0,
    this.damageMult = 1.0,
  });

  ProjectileSnapshot toSnapshot() => ProjectileSnapshot(
        id: id,
        ownerId: ownerId,
        type: 'bullet', // default type
        pos: pos,
        vel: vel,
        radius: radius,
        damage: damageMult,
        canReflect: reflectsRemaining > 0,
        reflectCount: reflectsRemaining,
      );
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

  HazardSnapshot toSnapshot() => HazardSnapshot(
        id: id,
        type: type,
        pos: pos,
        radius: radius,
        damagePerSec: 10, // default
        endsAt: expiresAt,
      );
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

  final Set<String> hitIds = {};

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

  AttackEffectSnapshot toSnapshot() => AttackEffectSnapshot(
        id: id,
        type: type,
        pos: pos,
        radius: radius,
        color: '#FFFFFF', // default
        endsAt: createdAt + durationMs,
      );
}

class DamageEvent {
  final String victimId;
  final double damage;
  final double x;
  final double y;
  final bool isCritical;
  final bool isPlayer;

  DamageEvent({
    required this.victimId,
    required this.damage,
    required this.x,
    required this.y,
    this.isCritical = false,
    this.isPlayer = false,
  });

  DamageEventSnapshot toSnapshot() => DamageEventSnapshot(
        id: 'dmg_${DateTime.now().microsecondsSinceEpoch}',
        targetId: victimId,
        pos: Vec2(x: x, y: y),
        amount: damage,
        isPlayer: isPlayer,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
}

class ObstacleData {
  final String id;
  final Vec2 pos;
  final double radius;
  final double rotation;

  ObstacleData({
    required this.id,
    required this.pos,
    required this.radius,
    required this.rotation,
  });

  ObstacleSnapshot toSnapshot() => ObstacleSnapshot(
        id: id,
        pos: pos,
        radius: radius,
        rotation: rotation,
      );
}
