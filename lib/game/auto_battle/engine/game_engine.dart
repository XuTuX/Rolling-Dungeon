import 'dart:async';
import 'dart:math' as math;
import '../models/game_snapshot.dart';
import 'constants.dart';
import 'physics.dart';
import 'types.dart';

class GameEngine {
  final Function(GameSnapshot) onUpdate;

  List<PlayerData> players = [];
  final List<FoodData> foods = [];
  final List<ProjectileData> projectiles = [];
  final List<HazardData> hazards = [];
  final List<AttackEffectData> attacks = [];
  final List<PlayerData> pendingSpawns = [];
  final List<DamageEvent> _damageEvents = [];
  final List<ObstacleData> obstacles = [];

  Timer? timer;
  int lastTickAt = DateTime.now().millisecondsSinceEpoch;
  String roundState = 'waiting';
  int currentStage;
  String? winnerId;
  int? roundEndsAt;
  int idSeq = 0;

  // ── Cycle System ──
  int currentCycle;
  int stageInCycle;
  int totalStageNumber;
  bool get isBossStage => stageInCycle >= BOSS_STAGE_IN_CYCLE;

  final math.Random _rand = math.Random();

  GameEngine({
    required this.onUpdate,
    required this.currentStage,
    required PlayerData initialPlayer,
    this.currentCycle = 1,
    this.stageInCycle = 1,
    this.totalStageNumber = 1,
  }) {
    initialPlayer
      ..radius =
          initialPlayer.radius <= 0 ? PLAYER_BASE_RADIUS : initialPlayer.radius
      ..pos = Vec2(x: ARENA_WIDTH * 0.28, y: ARENA_HEIGHT * 0.5)
      ..vel = normalize(Vec2(x: 1, y: -0.28))
      ..characterType = initialPlayer.characterType == 'none'
          ? 'gunner'
          : initialPlayer.characterType
      ..weaponCount = math.min(
        PLAYER_MAX_WEAPON_COUNT,
        math.max(1, initialPlayer.weaponCount),
      )
      ..weaponLevel = math.min(
        PLAYER_MAX_WEAPON_COUNT - 1,
        math.max(0, initialPlayer.weaponLevel),
      )
      ..bulletsPerWeapon = math.min(
        PLAYER_MAX_BULLETS_PER_WEAPON,
        math.max(1, initialPlayer.bulletsPerWeapon),
      )
      ..barrierHp = initialPlayer.barrierMaxHp > 0
          ? math.max(initialPlayer.barrierHp, initialPlayer.barrierMaxHp)
          : initialPlayer.barrierHp;
    players.add(initialPlayer);
    _spawnEnemiesForStage(currentStage);
    _spawnObstacles();
  }

  void _spawnObstacles() {
    obstacles.clear();
    if (isBossStage) return;

    final count = math.min(3, 1 + currentCycle ~/ 2);
    for (int i = 0; i < count; i++) {
      for (int attempt = 0; attempt < 10; attempt++) {
        final pos = Vec2(
          x: 100 + _rand.nextDouble() * (ARENA_WIDTH - 200),
          y: 100 + _rand.nextDouble() * (ARENA_HEIGHT - 200),
        );
        final tooClose = players.any((p) => distance(p.pos, pos) < 100);
        if (!tooClose) {
          obstacles.add(ObstacleData(
            id: _nextId('obs'),
            pos: pos,
            radius: 15 + _rand.nextDouble() * 15,
            rotation: _rand.nextDouble() * math.pi * 2,
          ));
          break;
        }
      }
    }
  }

  void start() {
    if (timer != null) return;
    lastTickAt = DateTime.now().millisecondsSinceEpoch;
    _primeAbilityCooldowns(lastTickAt);
    timer = Timer.periodic(const Duration(milliseconds: TICK_MS), (t) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dt = now - lastTickAt;
      lastTickAt = now;
      _tick(dt);
    });
  }

  void stop() {
    timer?.cancel();
    timer = null;
  }

  void revivePlayer(int newLives) {
    final p1 = _getPlayer('p1');
    if (p1 == null) return;

    p1.alive = true;
    p1.hp = p1.maxHp;
    p1.lives = newLives;
    // Reset position to safe area
    p1.pos = Vec2(x: ARENA_WIDTH * 0.15, y: ARENA_HEIGHT * 0.5);
    p1.vel = normalize(Vec2(x: 1, y: 0));

    // Resume game
    roundState = 'running';
    winnerId = null;
    roundEndsAt = null;
    _primeAbilityCooldowns(DateTime.now().millisecondsSinceEpoch);

    // Brief invincibility could be added here if needed
    _broadcastSnapshot();
  }

  void _primeAbilityCooldowns(int now) {
    for (final player in players) {
      player.lastShotAt = now;
      player.lastBladeAt = now;
      player.lastMineDropAt = now;
      player.lastAttackAt = now;
      if (!player.isEnemy) {
        for (final weapon in _activeWeaponsFor(player)) {
          player.lastCollisionAt['weapon:$weapon'] = now;
        }
      }
    }
  }

  void _tick(int dt) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final p1 = _getPlayer('p1');

    if (p1 == null) return;

    if (roundState == 'waiting') {
      roundState = 'running';
    }

    if (roundState == 'gameover' || roundState == 'victory') {
      _broadcastSnapshot();
      return;
    }

    _updatePlayers(dt.toDouble(), now);
    _handleCollisions(now);
    _handleAbilities(now);
    _updateProjectiles(dt.toDouble());
    _updateHazards(now, dt.toDouble());
    _updateEffects(now);
    _flushPendingSpawns();
    _checkRoundEnd(now);
    _broadcastSnapshot();
  }

  void _flushPendingSpawns() {
    if (pendingSpawns.isEmpty) return;
    players.addAll(pendingSpawns);
    pendingSpawns.clear();
  }

  void _updatePlayers(double dt, int now) {
    for (final player in players) {
      if (!player.alive) continue;
      _updateEnemyMovement(player, now);
      if (player.regen > 0 && player.hp < player.maxHp) {
        player.hp =
            math.min(player.maxHp, player.hp + player.regen * dt / 1000);
      }
      updatePosition(player, dt);
      handleWallCollision(player);
      _handleObstacleCollision(player);
    }
  }

  void _handleObstacleCollision(PlayerData player) {
    for (final obs in obstacles) {
      final dist = distance(player.pos, obs.pos);
      final min = player.radius + obs.radius;
      if (dist < min) {
        final overlap = min - dist;
        final nx = (player.pos.x - obs.pos.x) / dist;
        final ny = (player.pos.y - obs.pos.y) / dist;
        player.pos.x += nx * overlap;
        player.pos.y += ny * overlap;

        final dot = player.vel.x * nx + player.vel.y * ny;
        if (dot < 0) {
          player.vel.x -= 2 * dot * nx;
          player.vel.y -= 2 * dot * ny;
          player.vel = normalize(player.vel);
        }
      }
    }
  }

  void _updateEnemyMovement(PlayerData player, int now) {
    if (!player.isEnemy) return;
    final target = _getPlayer('p1');
    if (target == null || !target.alive) return;

    final dist = distance(player.pos, target.pos);
    var targetVel = normalize(Vec2(
      x: target.pos.x - player.pos.x,
      y: target.pos.y - player.pos.y,
    ));

    if (player.enemyAbility == 'dash') {
      final inDashWindow = now - player.lastAbilityAt < DASH_ENEMY_DURATION_MS;
      if (now - player.lastAbilityAt >= DASH_ENEMY_INTERVAL_MS) {
        player.lastAbilityAt = now;
        player.vel = targetVel;
      }
      player.speed =
          ENEMY_BASE_SPEED * (inDashWindow ? DASH_ENEMY_SPEED_MULTIPLIER : 0.9);
    } else if (player.enemyAbility == 'shoot') {
      if (dist < 130) {
        // Retreat
        targetVel = normalize(Vec2(
          x: player.pos.x - target.pos.x,
          y: player.pos.y - target.pos.y,
        ));
      } else if (dist < 190) {
        // Circle
        final angle = math.atan2(
                player.pos.y - target.pos.y, player.pos.x - target.pos.x) +
            0.04;
        player.pos.x = target.pos.x + math.cos(angle) * dist;
        player.pos.y = target.pos.y + math.sin(angle) * dist;
        targetVel = Vec2(x: 0, y: 0);
      }
    }

    if (targetVel.x != 0 || targetVel.y != 0) {
      player.vel.x = player.vel.x * 0.85 + targetVel.x * 0.15;
      player.vel.y = player.vel.y * 0.85 + targetVel.y * 0.15;
      player.vel = normalize(player.vel);
    }

    final stageSpeedMult =
        1 + math.max(0, currentStage - 1) * ENEMY_STAGE_SPEED_GROWTH;
    if (player.enemyAbility != 'dash') {
      player.speed = ENEMY_BASE_SPEED * stageSpeedMult;
    }
  }

  void _handleCollisions(int now) {
    for (int i = 0; i < players.length; i += 1) {
      for (int j = i + 1; j < players.length; j += 1) {
        final a = players[i];
        final b = players[j];
        if (!a.alive || !b.alive) continue;

        // 1. Body-to-Body Collision
        if (checkCircleCollision(a, b)) {
          resolveCircleCollision(a, b);
          if (a.isEnemy && b.isEnemy) continue;
          _applyCollisionDamage(a, b, now);
          _applyCollisionDamage(b, a, now);
        }

        // 2. Weapon-to-Body Physical Interaction
        // Players' weapons now physically block and push opponents
        _handleWeaponPhysicalCollision(a, b);
        _handleWeaponPhysicalCollision(b, a);
      }
    }
  }

  void _handleWeaponPhysicalCollision(PlayerData attacker, PlayerData victim) {
    if (attacker.isEnemy == victim.isEnemy) {
      return; // Only collide with opponents
    }
    if (attacker.characterType == 'none') return;

    double length = 0;
    double weaponStartDistance = attacker.radius * 0.5;
    switch (attacker.characterType) {
      case 'gunner':
        length = WEAPON_LENGTH * 1.5;
        break;
      case 'blade':
        length = BLADE_RANGE * 0.9;
        weaponStartDistance = attacker.radius + length * 0.58;
        break;
      case 'miner':
        length = 15.0;
        break;
    }

    if (length <= 0) return;

    final weaponDir = Vec2(
      x: math.cos(attacker.targetAngle),
      y: math.sin(attacker.targetAngle),
    );

    final wStart = Vec2(
      x: attacker.pos.x + weaponDir.x * weaponStartDistance,
      y: attacker.pos.y + weaponDir.y * weaponStartDistance,
    );
    final wEnd = Vec2(
      x: attacker.pos.x + weaponDir.x * (attacker.radius + length),
      y: attacker.pos.y + weaponDir.y * (attacker.radius + length),
    );

    resolveWeaponCollision(attacker, victim, wStart, wEnd);
  }

  PlayerData? _getPlayer(String id) {
    for (var p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _spawnEnemiesForStage(int stage) {
    final List<Map<String, dynamic>> enemiesToSpawn = [];

    if (isBossStage) {
      // Boss stage — spawn a boss with cycle-based pattern
      enemiesToSpawn.add({'type': _bossTypeForCycle(currentCycle), 'count': 1});
      // Later cycles add minions alongside the boss
      if (currentCycle >= 2) {
        enemiesToSpawn
            .add({'type': 'basic', 'count': math.min(currentCycle - 1, 3)});
      }
    } else {
      // Normal stage — use stageInCycle to vary composition
      final baseCount = 1 + (currentCycle ~/ 2).clamp(0, 3);
      switch (stageInCycle) {
        case 1:
          enemiesToSpawn.add({'type': 'basic', 'count': baseCount});
          if (currentCycle >= 2) {
            enemiesToSpawn.add({'type': 'fast', 'count': 1});
          }
          break;
        case 2:
          enemiesToSpawn
              .add({'type': 'dasher', 'count': math.max(1, baseCount - 1)});
          enemiesToSpawn.add({'type': 'shooter', 'count': 1});
          if (currentCycle >= 3) {
            enemiesToSpawn.add({'type': 'tank', 'count': 1});
          }
          break;
        case 3:
          enemiesToSpawn.add({'type': 'shield', 'count': 1});
          enemiesToSpawn
              .add({'type': 'splitter', 'count': math.max(1, baseCount - 1)});
          if (currentCycle >= 2) {
            enemiesToSpawn.add({'type': 'bruiser', 'count': 1});
          }
          break;
        default:
          enemiesToSpawn.add({'type': 'basic', 'count': baseCount});
      }
    }

    for (final group in enemiesToSpawn) {
      for (int i = 0; i < (group['count'] as int); i++) {
        players.add(_createEnemy(group['type'] as String, stage));
      }
    }
  }

  /// Determine boss type based on cycle. Cycles beyond 5 reuse patterns.
  String _bossTypeForCycle(int cycle) {
    switch ((cycle - 1) % 5) {
      case 0:
        return 'boss_basic'; // Basic large boss
      case 1:
        return 'boss_summoner'; // Summons minions
      case 2:
        return 'boss_dasher'; // Dash attack
      case 3:
        return 'boss_shield'; // Shield phase
      case 4:
        return 'boss_combined'; // Combined patterns
      default:
        return 'boss_basic';
    }
  }

  PlayerData _createEnemy(String type, int stage) {
    final stageStep = math.max(0, stage - 1);
    final cycleStep = math.max(0, currentCycle - 1);
    // Cycle-aware scaling
    final cycleHpMult = 1 + cycleStep * CYCLE_ENEMY_HP_SCALE;
    final cycleAtkMult = 1 + cycleStep * CYCLE_ENEMY_ATK_SCALE;
    final cycleSpdMult = 1 + cycleStep * CYCLE_ENEMY_SPD_SCALE;
    final hpMult = (1 + stageStep * ENEMY_STAGE_HP_GROWTH) * cycleHpMult;
    final speedMult = (1 + stageStep * ENEMY_STAGE_SPEED_GROWTH) * cycleSpdMult;
    double hp = (totalStageNumber == 1) ? STAGE_ONE_ENEMY_HP : 110 * hpMult;
    double speed = (totalStageNumber == 1)
        ? STAGE_ONE_ENEMY_SPEED
        : ENEMY_BASE_SPEED * speedMult;
    double radius =
        (totalStageNumber == 1) ? STAGE_ONE_ENEMY_RADIUS : ENEMY_BASE_RADIUS;
    String color = '#FF5E5E';
    double atk = (totalStageNumber == 1)
        ? STAGE_ONE_ENEMY_ATTACK
        : (7.0 + stage * ENEMY_STAGE_ATTACK_GROWTH) * cycleAtkMult;
    double def = (totalStageNumber == 1)
        ? STAGE_ONE_ENEMY_DEFENSE
        : 1.0 + stage * ENEMY_STAGE_DEFENSE_GROWTH;
    String ability = 'none';

    if (type == 'fast') {
      speed = ENEMY_BASE_SPEED * speedMult * 1.28;
      hp = 72 * hpMult;
      radius = ENEMY_BASE_RADIUS * 0.72;
      color = '#FFB84D';
    } else if (type == 'dasher') {
      speed = ENEMY_BASE_SPEED * speedMult * 0.95;
      hp = 95 * hpMult;
      radius = ENEMY_BASE_RADIUS * 0.9;
      color = '#FB7185';
      ability = 'dash';
    } else if (type == 'shooter') {
      speed = ENEMY_BASE_SPEED * speedMult * 0.85;
      hp = 92 * hpMult;
      radius = ENEMY_BASE_RADIUS * 0.85;
      color = '#38BDF8';
      ability = 'shoot';
    } else if (type == 'tank') {
      speed = ENEMY_BASE_SPEED * speedMult * 0.66;
      hp = 210 * hpMult;
      radius = ENEMY_BASE_RADIUS * 1.34;
      color = '#8A2BE2';
      def += 3.5;
    } else if (type == 'bruiser') {
      speed = ENEMY_BASE_SPEED * speedMult * 1.02;
      hp = 130 * hpMult;
      radius = ENEMY_BASE_RADIUS * 1.06;
      color = '#F97316';
      atk += 5;
      ability = 'impact';
    } else if (type == 'shield') {
      speed = ENEMY_BASE_SPEED * speedMult * 0.82;
      hp = 130 * hpMult;
      radius = ENEMY_BASE_RADIUS;
      color = '#14B8A6';
      ability = 'shield';
    } else if (type == 'splitter') {
      speed = ENEMY_BASE_SPEED * speedMult * 1.04;
      hp = 112 * hpMult;
      radius = ENEMY_BASE_RADIUS * 1.05;
      color = '#A855F7';
      ability = 'split';
    } else if (type == 'final_boss' || type.startsWith('boss_')) {
      // ── Boss types with cycle scaling ──
      final bossHpMult = 1 + cycleStep * CYCLE_BOSS_HP_SCALE;
      final bossAtkMult = 1 + cycleStep * CYCLE_BOSS_ATK_SCALE;
      speed = ENEMY_BASE_SPEED * cycleSpdMult * 0.92;
      hp = 780 * bossHpMult;
      radius = ENEMY_BASE_RADIUS * 1.9;
      color = '#000000';
      atk = (19 + cycleStep * 3.0) * bossAtkMult;
      def = 7 + cycleStep * 1.5;
      // Boss ability varies by type
      if (type == 'boss_dasher' || type == 'boss_combined') ability = 'dash';
      if (type == 'boss_shield' || type == 'boss_combined') ability = 'shield';
      if (type == 'boss_summoner') ability = 'shield';
      if (type == 'boss_basic' || type == 'final_boss') ability = 'shield';
    }

    final player = _getPlayer('p1');
    final minPlayerDistance =
        (player?.radius ?? PLAYER_BASE_RADIUS) + radius + 95;
    final spawnPos = _randomEnemySpawnPosition(radius, minPlayerDistance);
    final velocityAngle = player == null
        ? math.atan2(
            ARENA_HEIGHT / 2 - spawnPos.y, ARENA_WIDTH / 2 - spawnPos.x)
        : math.atan2(player.pos.y - spawnPos.y, player.pos.x - spawnPos.x);

    return PlayerData(
      id: _nextId('enemy'),
      characterType: 'none',
      isEnemy: true,
      hp: hp,
      maxHp: hp,
      atk: atk,
      def: def,
      speed: speed,
      abilityPower: 1,
      shield: 0,
      maxShield: 0,
      weaponLevel: 0,
      weaponCount: ability == 'shoot' ? 1 : 0,
      bulletReflectCount: 0,
      bulletsPerWeapon: 1,
      barrierHp: 0,
      barrierMaxHp: 0,
      gold: 0,
      totalGold: 0,
      pendingUpgradeCount: 0,
      upgradeChoices: [],
      kills: 0,
      damageDealt: 0,
      damageTaken: 0,
      pos: spawnPos,
      vel: normalize(
        Vec2(x: math.cos(velocityAngle), y: math.sin(velocityAngle) + 0.24),
      ),
      radius: radius,
      color: color,
      alive: true,
      lives: 1,
      maxLives: 1,
      lastCollisionAt: {},
      lastPoisonDropAt: 0,
      lastShotAt: 0,
      lastBladeAt: 0,
      lastMineDropAt: 0,
      lastAttackAt: 0,
      targetAngle: 0,
      lastAbilityAt: 0,
      enemyType: type,
      enemyAbility: ability,
      activeEffects: [],
    );
  }

  Vec2 _randomEnemySpawnPosition(double radius, double minPlayerDistance) {
    final player = _getPlayer('p1');
    Vec2? fallback;
    var fallbackDistance = -1.0;

    for (int attempt = 0; attempt < 32; attempt++) {
      final pos = Vec2(
        x: radius + _rand.nextDouble() * (ARENA_WIDTH - radius * 2),
        y: radius + _rand.nextDouble() * (ARENA_HEIGHT - radius * 2),
      );
      if (player == null) return pos;

      final playerDistance = distance(pos, player.pos);
      if (playerDistance >= minPlayerDistance) return pos;
      if (playerDistance > fallbackDistance) {
        fallback = pos;
        fallbackDistance = playerDistance;
      }
    }

    if (fallback != null) return clampToHexagon(fallback, radius);
    return clampToHexagon(
        Vec2(x: ARENA_WIDTH - radius, y: ARENA_HEIGHT / 2), radius);
  }

  void _handleAbilities(int now) {
    for (final player in players) {
      if (!player.alive) continue;
      if (player.isEnemy) {
        _handleEnemyAbility(player, now);
      } else {
        final weapons = _activeWeaponsFor(player);

        for (final weapon in weapons) {
          switch (weapon) {
            case 'miner':
              _dropMine(player, now);
              break;
            case 'poison':
              _dropPoison(player, now);
              break;
            case 'footsteps':
              _dropFootsteps(player, now);
              break;
            case 'aura':
              _applyAura(player, now);
              break;
            case 'blade':
            case 'heavy_blade':
              player.targetAngle = _rotatingWeaponAngle(player, now);
              _checkBladeCollision(player, now, weapon == 'heavy_blade');
              break;
            case 'burst':
              _fireBurst(player, now);
              break;
            case 'minigun':
              player.targetAngle = _rotatingWeaponAngle(player, now);
              _fireBullet(player, now, weaponType: weapon, spread: 0.15);
              break;
            case 'long_gun':
            case 'ricochet':
            case 'gunner':
            default:
              player.targetAngle = _rotatingWeaponAngle(player, now);
              _fireBullet(player, now, weaponType: weapon);
              break;
          }
        }
      }
    }
  }

  void _handleEnemyAbility(PlayerData enemy, int now) {
    switch (enemy.enemyAbility) {
      case 'shoot':
        _fireEnemyBullet(enemy, now);
        break;
      case 'shield':
        if (now - enemy.lastAbilityAt >= ENEMY_SHIELD_INTERVAL_MS) {
          enemy.lastAbilityAt = now;
          enemy.shield = ENEMY_SHIELD_HP;
          enemy.maxShield = ENEMY_SHIELD_HP;
        }
        break;
      default:
        break;
    }

    if (enemy.vel.x.abs() + enemy.vel.y.abs() > 0.01) {
      enemy.targetAngle = math.atan2(enemy.vel.y, enemy.vel.x);
    }
  }

  List<String> _activeWeaponsFor(PlayerData player) {
    final baseWeapon =
        player.characterType == 'none' ? 'gunner' : player.characterType;
    return [
      baseWeapon,
      ...player.ownedWeapons.where((weapon) => weapon != baseWeapon),
    ];
  }

  bool _weaponReady(
    PlayerData player,
    String weaponType,
    int now,
    double cooldown,
  ) {
    final lastUsedAt = player.lastCollisionAt['weapon:$weaponType'] ?? 0;
    return now - lastUsedAt >= cooldown;
  }

  void _markWeaponUsed(PlayerData player, String weaponType, int now) {
    player.lastCollisionAt['weapon:$weaponType'] = now;
    player.lastAttackAt = now;
  }

  void _fireBullet(
    PlayerData player,
    int now, {
    String weaponType = 'gunner',
    double spread = 0.0,
  }) {
    int baseFireInterval = WEAPON_FIRE_INTERVAL_MS;
    final wLevel = player.weaponLevels[weaponType] ?? 0;
    double damageMult = 1.0 + (wLevel * 0.15);
    double bulletRad = BULLET_RADIUS;
    int extraReflects = 0;

    if (weaponType == 'minigun') {
      baseFireInterval = (WEAPON_FIRE_INTERVAL_MS * 0.4).round();
      damageMult = 0.5;
    } else if (weaponType == 'long_gun') {
      baseFireInterval = (WEAPON_FIRE_INTERVAL_MS * 1.8).round();
      damageMult = 2.5;
      bulletRad = BULLET_RADIUS * 2.0;
    } else if (weaponType == 'ricochet') {
      extraReflects = 3;
    }

    final cooldown = _getAbilityCooldown(player, baseFireInterval);
    if (!_weaponReady(player, weaponType, now, cooldown)) return;
    if (!players.any((other) => other.alive && other.id != player.id)) return;
    _markWeaponUsed(player, weaponType, now);
    player.lastShotAt = now;
    final baseAngle = _rotatingWeaponAngle(player, now);
    player.targetAngle = baseAngle;
    final weaponCount = math.max(1, player.weaponCount);
    final bulletsPerWeapon = math.max(1, player.bulletsPerWeapon);
    final muzzleDist = player.radius + WEAPON_LENGTH + MUZZLE_OFFSET_EXTRA;

    for (int i = 0; i < weaponCount; i++) {
      final weaponAngle = baseAngle + math.pi * 2 * i / weaponCount;
      final spreadRange = (bulletsPerWeapon - 1) * BULLET_BURST_SPREAD_RADIANS;
      for (int shot = 0; shot < bulletsPerWeapon; shot++) {
        final jitter = (spread > 0) ? (_rand.nextDouble() - 0.5) * spread : 0.0;
        final angle = bulletsPerWeapon == 1
            ? weaponAngle + jitter
            : weaponAngle -
                spreadRange / 2 +
                spreadRange * shot / (bulletsPerWeapon - 1) +
                jitter;
        final direction = Vec2(x: math.cos(angle), y: math.sin(angle));
        final spawnPos = Vec2(
          x: player.pos.x + direction.x * muzzleDist,
          y: player.pos.y + direction.y * muzzleDist,
        );

        projectiles.add(ProjectileData(
          id: _nextId('bullet'),
          ownerId: player.id,
          pos: spawnPos,
          vel: direction,
          radius: bulletRad,
          color: player.color,
          reflectsRemaining: player.bulletReflectCount + extraReflects,
          damageMult: damageMult,
        ));
      }
    }
  }

  void _fireBurst(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, BURST_FIRE_MS);
    if (!_weaponReady(player, 'burst', now, cooldown)) return;
    _markWeaponUsed(player, 'burst', now);
    player.lastShotAt = now;

    for (int i = 0; i < BURST_COUNT; i++) {
      final angle = (math.pi * 2 * i) / BURST_COUNT;
      final direction = Vec2(x: math.cos(angle), y: math.sin(angle));
      final muzzleDist = player.radius + 5;
      final spawnPos = Vec2(
        x: player.pos.x + direction.x * muzzleDist,
        y: player.pos.y + direction.y * muzzleDist,
      );

      final wLevel = player.weaponLevels['burst'] ?? 0;
      projectiles.add(ProjectileData(
        id: _nextId('burst'),
        ownerId: player.id,
        pos: spawnPos,
        vel: direction,
        radius: BULLET_RADIUS * 0.8,
        color: '#FFEB3B', // Yellow burst
        reflectsRemaining: 0,
        damageMult: 1.0 + (wLevel * 0.15),
      ));
    }
  }

  void _dropFootsteps(PlayerData player, int now) {
    if (!_weaponReady(player, 'footsteps', now, FOOTSTEPS_DROP_MS.toDouble())) {
      return;
    }
    if (player.vel.x.abs() + player.vel.y.abs() < 0.1) return;
    _markWeaponUsed(player, 'footsteps', now);
    player.lastPoisonDropAt = now;

    hazards.add(HazardData(
      id: _nextId('fire'),
      ownerId: player.id,
      type: 'fire',
      pos: Vec2(x: player.pos.x, y: player.pos.y),
      radius: FOOTSTEPS_RADIUS,
      expiresAt: now + FOOTSTEPS_DURATION_MS,
      lastDamageAt: {},
    ));
  }

  void _applyAura(PlayerData player, int now) {
    // Auras don't have a drop interval, they tick every frame
    final owner = player;
    for (final target in players) {
      if (!target.alive || target.id == player.id) continue;
      if (target.isEnemy == player.isEnemy) continue;

      if (distance(target.pos, player.pos) <= player.radius + AURA_RADIUS) {
        // Ticking damage
        final wLevel = owner.weaponLevels['aura'] ?? 0;
        _dealDamage(owner, target,
            AURA_DAMAGE_TICK * (1.0 + wLevel * 0.15) * (TICK_MS / 1000));
      }
    }
  }

  void _dropMine(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, MINER_DROP_MS);
    if (!_weaponReady(player, 'miner', now, cooldown)) return;
    if (!players.any((other) => other.alive && other.isEnemy)) return;
    _markWeaponUsed(player, 'miner', now);
    player.lastMineDropAt = now;
    final rearAngle = _rearAngle(player);
    final mineCount = math.max(1, player.weaponCount);
    final mineDistance = player.radius + MINE_THROW_DISTANCE;
    final spread = mineCount == 1 ? 0.0 : math.pi / 7;

    for (int i = 0; i < mineCount; i++) {
      final t = mineCount == 1 ? 0.0 : i / (mineCount - 1);
      final angle = rearAngle - spread / 2 + spread * t;
      final minePos = clampToHexagon(
        Vec2(
          x: (player.pos.x + math.cos(angle) * mineDistance),
          y: (player.pos.y + math.sin(angle) * mineDistance),
        ),
        MINE_RADIUS,
      );
      hazards.add(HazardData(
        id: _nextId('mine'),
        ownerId: player.id,
        type: 'mine',
        pos: minePos,
        radius: MINE_RADIUS,
        expiresAt: now + MINE_DURATION_MS,
        lastDamageAt: {},
      ));
    }
  }

  void _dropPoison(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, POISON_DROP_MS);
    if (!_weaponReady(player, 'poison', now, cooldown)) return;

    // Only drop poison if we are moving
    if (player.vel.x.abs() + player.vel.y.abs() < 0.1) return;

    _markWeaponUsed(player, 'poison', now);
    player.lastPoisonDropAt = now;

    final rearAngle = _rearAngle(player);
    final sprayCount = math.max(1, player.weaponCount);

    // 'Spraying' effect: add randomness to the drop position
    for (int i = 0; i < sprayCount; i++) {
      final t = sprayCount == 1 ? 0.0 : (i / (sprayCount - 1)) - 0.5;
      final offsetAngle = rearAngle + math.pi / 2;

      // Add jitter (randomness) to make it feel like spraying
      final jitterX = (_rand.nextDouble() - 0.5) * 6.0;
      final jitterY = (_rand.nextDouble() - 0.5) * 6.0;

      // Drop slightly behind the player to feel like it's coming from the rear
      final dropDist = player.radius * 0.6;

      final poisonPos = clampToHexagon(
        Vec2(
          x: (player.pos.x +
              math.cos(rearAngle) * dropDist +
              math.cos(offsetAngle) * t * 15.0 +
              jitterX),
          y: (player.pos.y +
              math.sin(rearAngle) * dropDist +
              math.sin(offsetAngle) * t * 15.0 +
              jitterY),
        ),
        POISON_RADIUS,
      );

      hazards.add(HazardData(
        id: _nextId('poison'),
        ownerId: player.id,
        type: 'poison',
        pos: poisonPos,
        radius: POISON_RADIUS *
            (0.7 + _rand.nextDouble() * 0.6), // More variation in size
        expiresAt: now + POISON_DURATION_MS,
        lastDamageAt: {},
      ));
    }
  }

  void _checkBladeCollision(PlayerData player, int now, bool isHeavy) {
    final weaponCount = math.max(1, player.weaponCount);
    final baseAngle = player.targetAngle;
    final rangeMult = isHeavy ? 1.5 : 1.0;
    final visualRange = player.radius * 1.6 * rangeMult;

    final wLevel = player.weaponLevels[isHeavy ? 'heavy_blade' : 'blade'] ?? 0;
    final dmgMult =
        (isHeavy ? HEAVY_BLADE_DAMAGE_MULT : 1.0) * (1.0 + wLevel * 0.15);
    final cooldown =
        isHeavy ? HEAVY_BLADE_COOLDOWN_MS : BLADE_CONTACT_DAMAGE_MS;

    for (int i = 0; i < weaponCount; i++) {
      final angle = baseAngle + math.pi * 2 * i / weaponCount;
      final dir = Vec2(x: math.cos(angle), y: math.sin(angle));

      final bladeStart = Vec2(
        x: player.pos.x + dir.x * player.radius * 0.4,
        y: player.pos.y + dir.y * player.radius * 0.4,
      );
      final bladeEnd = Vec2(
        x: player.pos.x + dir.x * visualRange,
        y: player.pos.y + dir.y * visualRange,
      );

      for (final enemy in players) {
        if (!enemy.alive || enemy.id == player.id) continue;
        if (enemy.isEnemy == player.isEnemy) continue;

        // Damage cooldown per enemy for this specific blade
        final hitKey = 'blade:${player.id}:$i';
        final lastHit = enemy.lastCollisionAt[hitKey] ?? 0;
        if (now - lastHit < cooldown) continue;

        final hitDistance =
            _distancePointToSegment(enemy.pos, bladeStart, bladeEnd);
        if (hitDistance <=
            enemy.radius + BLADE_CONTACT_WIDTH * (isHeavy ? 2.0 : 1.0)) {
          enemy.lastCollisionAt[hitKey] = now;
          player.lastBladeAt = now;
          player.lastAttackAt = now;
          _dealDamage(
            player,
            enemy,
            (BASE_ATK + player.atk * 0.8) * dmgMult,
          );
        }
      }
    }
  }

  void _fireEnemyBullet(PlayerData enemy, int now) {
    if (now - enemy.lastShotAt < ENEMY_SHOOTER_FIRE_MS) return;
    final target = _getPlayer('p1');
    if (target == null || !target.alive) return;
    enemy.lastShotAt = now;
    enemy.lastAttackAt = now;
    final angle =
        math.atan2(target.pos.y - enemy.pos.y, target.pos.x - enemy.pos.x);
    enemy.targetAngle = angle;
    final direction = Vec2(x: math.cos(angle), y: math.sin(angle));
    final muzzleDist = enemy.radius + WEAPON_LENGTH + MUZZLE_OFFSET_EXTRA;
    projectiles.add(ProjectileData(
      id: _nextId('enemy_bullet'),
      ownerId: enemy.id,
      pos: Vec2(
        x: enemy.pos.x + direction.x * muzzleDist,
        y: enemy.pos.y + direction.y * muzzleDist,
      ),
      vel: direction,
      radius: BULLET_RADIUS,
      color: enemy.color,
      reflectsRemaining: 0,
    ));
  }

  void _updateProjectiles(double dt) {
    for (int i = projectiles.length - 1; i >= 0; i -= 1) {
      final p = projectiles[i];
      p.pos.x += p.vel.x * BULLET_SPEED * dt;
      p.pos.y += p.vel.y * BULLET_SPEED * dt;

      // Wall reflection logic
      bool hitWall = handleProjectileHexWallCollision(p);
      if (hitWall) {
        if (p.reflectsRemaining > 0) {
          p.reflectsRemaining -= 1;
        } else {
          projectiles.removeAt(i);
          continue;
        }
      }

      final owner = _getPlayer(p.ownerId);
      if (owner == null) {
        projectiles.removeAt(i);
        continue;
      }
      final target = players.cast<PlayerData?>().firstWhere(
            (pl) =>
                pl != null &&
                pl.alive &&
                pl.id != p.ownerId &&
                pl.isEnemy != owner.isEnemy &&
                distance(pl.pos, p.pos) <= pl.radius + p.radius,
            orElse: () => null,
          );
      if (target == null) continue;
      final damage = (owner.isEnemy
              ? ENEMY_BULLET_DAMAGE
              : BASE_BULLET_DAMAGE + owner.atk * BULLET_ATTACK_DAMAGE_RATIO) *
          p.damageMult;
      _dealDamage(owner, target, damage);
      projectiles.removeAt(i);
    }
  }

  void _updateHazards(int now, double dt) {
    for (int i = hazards.length - 1; i >= 0; i -= 1) {
      final hazard = hazards[i];
      if (now >= hazard.expiresAt) {
        hazards.removeAt(i);
        continue;
      }
      final owner = _getPlayer(hazard.ownerId);
      if (owner == null) {
        hazards.removeAt(i);
        continue;
      }
      for (final target in players) {
        if (!target.alive || target.id == hazard.ownerId) continue;
        if (target.isEnemy == owner.isEnemy) continue;
        if (distance(target.pos, hazard.pos) > target.radius + hazard.radius) {
          continue;
        }
        if (hazard.type == 'mine') {
          final wLevel = owner.weaponLevels['miner'] ?? 0;
          _dealDamage(
            owner,
            target,
            (MINE_DAMAGE + owner.atk * MINE_ATTACK_DAMAGE_RATIO) *
                (1.0 + wLevel * 0.15),
          );
          hazards.removeAt(i);
          break;
        }
        final poisonLevel = owner.weaponLevels['poison'] ?? 0;
        final poisonDamage =
            (1.7 + owner.abilityPower * 0.45 + owner.weaponLevel * 0.18) *
                (1.0 + poisonLevel * 0.15) *
                (dt / 1000);
        _dealDamage(owner, target, poisonDamage);
      }
    }
  }

  void _updateEffects(int now) {
    for (int i = attacks.length - 1; i >= 0; i -= 1) {
      final attack = attacks[i];
      final elapsed = now - attack.createdAt;

      if (elapsed >= attack.durationMs) {
        attacks.removeAt(i);
        continue;
      }

      // Other ephemeral effects can be handled here
    }
  }

  void _checkRoundEnd(int now) {
    final p1 = _getPlayer('p1');
    if (p1 == null) return;

    if (!p1.alive) {
      roundState = 'gameover';
      winnerId = 'enemy';
      return;
    }

    final aliveEnemies = players.where((p) => p.isEnemy && p.alive).toList();
    if (aliveEnemies.isEmpty) {
      winnerId = p1.id;
      roundState = 'victory';
    }
  }

  void _applyCollisionDamage(
      PlayerData attacker, PlayerData defender, int now) {
    final hitKey = 'collision:${attacker.id}';
    final lastHitAt = defender.lastCollisionAt[hitKey] ?? 0;
    if (now - lastHitAt < COLLISION_DAMAGE_COOLDOWN_MS) return;
    defender.lastCollisionAt[hitKey] = now;
    defender.lastCollisionAt[attacker.id] = now;
    final raw = (attacker.atk - defender.def) * COLLISION_DAMAGE_MULTIPLIER;
    final damage = math.max(COLLISION_MIN_DAMAGE, raw);
    _dealDamage(attacker, defender, damage, isCollision: true);
  }

  void _dealDamage(
    PlayerData attacker,
    PlayerData defender,
    double raw, {
    bool isCollision = false,
  }) {
    if (!attacker.alive || !defender.alive || raw <= 0) return;
    var dmg = math.max(COLLISION_MIN_DAMAGE, raw);
    if ((isCollision || attacker.isEnemy) && defender.barrierHp > 0) {
      final absorbed = isCollision ? dmg : math.min(defender.barrierHp, dmg);
      defender.barrierHp =
          isCollision ? 0 : math.max(0, defender.barrierHp - absorbed);
      defender.damageTaken += absorbed;
      attacker.damageDealt += absorbed;
      if (defender.barrierHp <= 0 && isCollision) {
        _dealDamage(defender, attacker, BARRIER_DAMAGE);
      }
      dmg = dmg * BARRIER_COLLISION_LEAK_RATIO;
      if (dmg <= 0) return;
    }

    final shieldAbsorb = math.min(defender.shield, dmg);
    defender.shield = math.max(0, defender.shield - shieldAbsorb);
    final hpDamage = dmg - shieldAbsorb;
    if (hpDamage <= 0) {
      defender.damageTaken += shieldAbsorb;
      return;
    }

    final prev = defender.hp;
    defender.hp = math.max(0.0, defender.hp - hpDamage);
    final actual = prev - defender.hp;
    attacker.damageDealt += actual;
    defender.damageTaken += actual + shieldAbsorb;

    // ── Record Damage Event for UI ──
    _damageEvents.add(DamageEvent(
      victimId: defender.id,
      x: defender.pos.x,
      y: defender.pos.y,
      damage: actual + shieldAbsorb,
      isPlayer: !defender.isEnemy,
    ));

    if (attacker.lifesteal > 0 && actual > 0) {
      attacker.hp =
          math.min(attacker.maxHp, attacker.hp + actual * attacker.lifesteal);
    }
    _addGold(attacker, actual * 0.8);
    if (defender.hp <= 0 && defender.alive) {
      defender.alive = false;
      attacker.kills += 1;
      _addGold(attacker, 20);
      _handleEnemyDeath(defender);
    }
  }

  void _handleEnemyDeath(PlayerData enemy) {
    if (!enemy.isEnemy || enemy.enemyAbility != 'split') return;
    for (int i = 0; i < 2; i++) {
      final angle = _rand.nextDouble() * math.pi * 2;
      final child = _createEnemy('fast', currentStage);
      child
        ..id = _nextId('split')
        ..hp = math.max(20, enemy.maxHp * 0.24)
        ..maxHp = child.hp
        ..radius = enemy.radius * 0.55
        ..atk = math.max(4, enemy.atk * 0.7)
        ..pos = Vec2(
          x: (enemy.pos.x + math.cos(angle) * enemy.radius)
              .clamp(child.radius, ARENA_WIDTH - child.radius)
              .toDouble(),
          y: (enemy.pos.y + math.sin(angle) * enemy.radius)
              .clamp(child.radius, ARENA_HEIGHT - child.radius)
              .toDouble(),
        )
        ..vel = normalize(Vec2(x: math.cos(angle), y: math.sin(angle)))
        ..enemyAbility = 'none'
        ..enemyType = 'split_child';
      pendingSpawns.add(child);
    }
  }

  void _addGold(PlayerData player, double amount) {
    if (!player.alive || amount <= 0) return;
    final val = amount.roundToDouble();
    player.gold += val;
    player.totalGold += val;
  }

  double _getAbilityCooldown(PlayerData p, int base) {
    return base / (1 + math.max(0, p.speed - BASE_SPEED) * 0.55);
  }

  double _rotatingWeaponAngle(PlayerData p, int now) {
    final phase =
        p.id.codeUnits.fold<int>(0, (sum, code) => sum + code) * 0.017;
    return _normalizeAngle(
        now / 1000.0 * ROTATING_WEAPON_RADIANS_PER_SECOND + phase);
  }

  double _movementAngle(PlayerData p) {
    if (p.vel.x.abs() + p.vel.y.abs() <= 0.001) {
      return p.targetAngle;
    }
    return math.atan2(p.vel.y, p.vel.x);
  }

  double _rearAngle(PlayerData p) =>
      _normalizeAngle(_movementAngle(p) + math.pi);

  double _normalizeAngle(double angle) {
    const fullTurn = math.pi * 2;
    final normalized = angle % fullTurn;
    return normalized < 0 ? normalized + fullTurn : normalized;
  }

  double _distancePointToSegment(Vec2 point, Vec2 start, Vec2 end) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared <= 0) return distance(point, start);

    final t =
        (((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();
    return distance(
      point,
      Vec2(
        x: start.x + dx * t,
        y: start.y + dy * t,
      ),
    );
  }

  String _nextId(String prefix) {
    return '${prefix}_${idSeq++}';
  }

  void _broadcastSnapshot() {
    final snapshot = GameSnapshot(
      serverTime: DateTime.now().millisecondsSinceEpoch,
      currentStage: currentStage,
      currentCycle: currentCycle,
      stageInCycle: stageInCycle,
      totalStageNumber: totalStageNumber,
      isBossStage: isBossStage,
      arenaWidth: ARENA_WIDTH.toDouble(),
      arenaHeight: ARENA_HEIGHT.toDouble(),
      roundState: roundState,
      winnerId: winnerId,
      roundEndsAt: roundEndsAt,
      aliveCount: players.where((p) => p.alive).length,
      players: players.map((p) => p.toSnapshot()).toList(),
      foods: foods.map((f) => f.toSnapshot()).toList(),
      projectiles: projectiles.map((p) => p.toSnapshot()).toList(),
      hazards: hazards.map((h) => h.toSnapshot()).toList(),
      attacks: attacks.map((a) => a.toSnapshot()).toList(),
      obstacles: obstacles.map((o) => o.toSnapshot()).toList(),
      damageEvents: _damageEvents.map((e) => e.toSnapshot()).toList(),
    );

    // Clear events after broadcasting so they only appear once
    _damageEvents.clear();

    onUpdate(snapshot);
  }
}
