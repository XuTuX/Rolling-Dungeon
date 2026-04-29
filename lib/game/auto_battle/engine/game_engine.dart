import 'dart:async';
import 'dart:math' as math;
import '../models/game_snapshot.dart';
import '../models/player_snapshot.dart';
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

  Timer? timer;
  int lastTickAt = DateTime.now().millisecondsSinceEpoch;
  String roundState = 'waiting';
  int currentStage;
  String? winnerId;
  int? roundEndsAt;
  int idSeq = 0;

  final math.Random _rand = math.Random();

  GameEngine({
    required this.onUpdate,
    required this.currentStage,
    required PlayerData initialPlayer,
  }) {
    initialPlayer
      ..radius =
          initialPlayer.radius <= 0 ? PLAYER_BASE_RADIUS : initialPlayer.radius
      ..pos = Vec2(x: ARENA_WIDTH * 0.28, y: ARENA_HEIGHT * 0.5)
      ..vel = normalize(Vec2(x: 1, y: -0.28))
      ..characterType = initialPlayer.characterType == 'none'
          ? 'gunner'
          : initialPlayer.characterType
      ..weaponCount = math.max(1, initialPlayer.weaponCount)
      ..bulletsPerWeapon = math.max(1, initialPlayer.bulletsPerWeapon)
      ..barrierHp = initialPlayer.barrierMaxHp > 0
          ? math.max(initialPlayer.barrierHp, initialPlayer.barrierMaxHp)
          : initialPlayer.barrierHp;
    players.add(initialPlayer);
    _spawnEnemiesForStage(currentStage);
  }

  void start() {
    if (timer != null) return;
    lastTickAt = DateTime.now().millisecondsSinceEpoch;
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
    _cleanupEffects(now);
    _checkRoundEnd(now);
    _broadcastSnapshot();
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
    }
  }

  void _updateEnemyMovement(PlayerData player, int now) {
    if (!player.isEnemy) return;
    if (player.enemyAbility != 'dash') return;

    final inDashWindow = now - player.lastAbilityAt < DASH_ENEMY_DURATION_MS;
    if (now - player.lastAbilityAt >= DASH_ENEMY_INTERVAL_MS) {
      final target = _getPlayer('p1');
      player.lastAbilityAt = now;
      if (target != null && target.alive) {
        player.vel = normalize(Vec2(
          x: target.pos.x - player.pos.x,
          y: target.pos.y - player.pos.y,
        ));
      }
    }
    final stageSpeedMult =
        1 + math.max(0, currentStage - 1) * ENEMY_STAGE_SPEED_GROWTH;
    player.speed = ENEMY_BASE_SPEED *
        stageSpeedMult *
        (inDashWindow ? DASH_ENEMY_SPEED_MULTIPLIER : 0.9);
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
    if (attacker.isEnemy == victim.isEnemy) return; // Only collide with opponents
    if (attacker.characterType == 'none') return;

    double length = 0;
    switch (attacker.characterType) {
      case 'gunner':
        length = WEAPON_LENGTH * 1.5;
        break;
      case 'blade':
        length = BLADE_RANGE * 0.9;
        break;
      case 'laser':
        length = WEAPON_LENGTH * 2.0;
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
      x: attacker.pos.x + weaponDir.x * attacker.radius * 0.5,
      y: attacker.pos.y + weaponDir.y * attacker.radius * 0.5,
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
    if (stage == 1) {
      enemiesToSpawn.add({'type': 'basic', 'count': 1});
    } else if (stage == 2) {
      enemiesToSpawn.add({'type': 'dasher', 'count': 1});
      enemiesToSpawn.add({'type': 'basic', 'count': 1});
    } else if (stage == 3) {
      enemiesToSpawn.add({'type': 'shooter', 'count': 1});
      enemiesToSpawn.add({'type': 'fast', 'count': 1});
    } else if (stage == 4) {
      enemiesToSpawn.add({'type': 'tank', 'count': 1});
      enemiesToSpawn.add({'type': 'dasher', 'count': 2});
    } else if (stage == 5) {
      enemiesToSpawn.add({'type': 'shield', 'count': 1});
      enemiesToSpawn.add({'type': 'shooter', 'count': 2});
    } else if (stage == 6) {
      enemiesToSpawn.add({'type': 'splitter', 'count': 2});
      enemiesToSpawn.add({'type': 'fast', 'count': 2});
    } else if (stage == 7) {
      enemiesToSpawn.add({'type': 'bruiser', 'count': 2});
      enemiesToSpawn.add({'type': 'tank', 'count': 2});
    } else if (stage == 8) {
      enemiesToSpawn.add({'type': 'shooter', 'count': 3});
      enemiesToSpawn.add({'type': 'dasher', 'count': 2});
    } else if (stage == 9) {
      enemiesToSpawn.add({'type': 'shield', 'count': 2});
      enemiesToSpawn.add({'type': 'splitter', 'count': 2});
    } else if (stage >= 10) {
      enemiesToSpawn.add({'type': 'final_boss', 'count': 1});
    }

    for (final group in enemiesToSpawn) {
      for (int i = 0; i < (group['count'] as int); i++) {
        players.add(_createEnemy(group['type'] as String, stage));
      }
    }
  }

  PlayerData _createEnemy(String type, int stage) {
    final stageStep = math.max(0, stage - 1);
    final hpMult = 1 + stageStep * ENEMY_STAGE_HP_GROWTH;
    final speedMult = 1 + stageStep * ENEMY_STAGE_SPEED_GROWTH;
    double hp = stage == 1 ? STAGE_ONE_ENEMY_HP : 110 * hpMult;
    double speed =
        stage == 1 ? STAGE_ONE_ENEMY_SPEED : ENEMY_BASE_SPEED * speedMult;
    double radius = stage == 1 ? STAGE_ONE_ENEMY_RADIUS : ENEMY_BASE_RADIUS;
    String color = '#FF5E5E';
    double atk = stage == 1
        ? STAGE_ONE_ENEMY_ATTACK
        : 7.0 + stage * ENEMY_STAGE_ATTACK_GROWTH;
    double def = stage == 1
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
    } else if (type == 'final_boss') {
      speed = ENEMY_BASE_SPEED * speedMult * 0.92;
      hp = 780 * hpMult;
      radius = ENEMY_BASE_RADIUS * 1.9;
      color = '#000000';
      atk = 19 + stageStep * 0.9;
      def = 7 + stageStep * 0.35;
      ability = 'shield';
    }

    final angle = stage == 1 ? math.pi : _rand.nextDouble() * math.pi * 2;
    final spawnDist = stage == 1 ? 120.0 : 115 + _rand.nextDouble() * 95;
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
      pos: Vec2(
        x: (ARENA_WIDTH / 2 + math.cos(angle) * spawnDist)
            .clamp(radius, ARENA_WIDTH - radius)
            .toDouble(),
        y: (ARENA_HEIGHT / 2 + math.sin(angle) * spawnDist)
            .clamp(radius, ARENA_HEIGHT - radius)
            .toDouble(),
      ),
      vel: normalize(Vec2(x: -math.cos(angle), y: -math.sin(angle) + 0.24)),
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

  void _handleAbilities(int now) {
    for (final player in players) {
      if (!player.alive) continue;
      if (player.isEnemy) {
        _handleEnemyAbility(player, now);
      } else {
        player.targetAngle = _rotatingWeaponAngle(player, now);
        switch (player.characterType) {
          case 'miner':
            _dropMine(player, now);
            break;
          case 'laser':
            _fireLaser(player, now);
            break;
          case 'blade':
            _handleBladeAttack(player, now);
            break;
          default:
            _fireBullet(player, now);
            break;
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

  void _fireBullet(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, WEAPON_FIRE_INTERVAL_MS);
    if (now - player.lastShotAt < cooldown) return;
    if (!players.any((other) => other.alive && other.id != player.id)) return;
    player.lastShotAt = now;
    player.lastAttackAt = now;
    final baseAngle = _rotatingWeaponAngle(player, now);
    player.targetAngle = baseAngle;
    final weaponCount = math.max(1, player.weaponCount);
    final bulletsPerWeapon = math.max(1, player.bulletsPerWeapon);
    const bulletRadius = BULLET_RADIUS;
    final muzzleDist = player.radius + WEAPON_LENGTH + MUZZLE_OFFSET_EXTRA;

    for (int i = 0; i < weaponCount; i++) {
      final weaponAngle = baseAngle + math.pi * 2 * i / weaponCount;
      final spread = (bulletsPerWeapon - 1) * BULLET_BURST_SPREAD_RADIANS;
      for (int shot = 0; shot < bulletsPerWeapon; shot++) {
        final angle = bulletsPerWeapon == 1
            ? weaponAngle
            : weaponAngle - spread / 2 + spread * shot / (bulletsPerWeapon - 1);
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
          radius: bulletRadius,
          color: player.color,
          reflectsRemaining: player.bulletReflectCount,
        ));
      }
    }
  }

  void _dropMine(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, MINER_DROP_MS);
    if (now - player.lastMineDropAt < cooldown) return;
    if (!players.any((other) => other.alive && other.isEnemy)) return;
    player.lastMineDropAt = now;
    player.lastAttackAt = now;
    final baseAngle = _rotatingWeaponAngle(player, now);
    player.targetAngle = baseAngle;
    final mineCount = math.max(1, player.weaponCount);
    final mineDistance = player.radius + MINE_THROW_DISTANCE;

    for (int i = 0; i < mineCount; i++) {
      final angle = baseAngle + math.pi * 2 * i / mineCount;
      final minePos = Vec2(
        x: (player.pos.x + math.cos(angle) * mineDistance)
            .clamp(MINE_RADIUS, ARENA_WIDTH - MINE_RADIUS)
            .toDouble(),
        y: (player.pos.y + math.sin(angle) * mineDistance)
            .clamp(MINE_RADIUS, ARENA_HEIGHT - MINE_RADIUS)
            .toDouble(),
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

  void _fireLaser(PlayerData player, int now) {
    // This is now the Crossbow 'Bolt' attack
    final cooldown = _getAbilityCooldown(player, LASER_FIRE_MS);
    if (now - player.lastShotAt < cooldown) return;
    final target = _findNearestOpponent(player, LASER_RANGE);
    if (target == null) return;
    player.lastShotAt = now;
    player.lastAttackAt = now;

    final aimAngle =
        math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    player.targetAngle = aimAngle;
    final beamCount = math.max(1, player.weaponCount);
    final muzzleDist = player.radius + WEAPON_LENGTH + MUZZLE_OFFSET_EXTRA;

    for (int i = 0; i < beamCount; i++) {
      final angle =
          beamCount == 1 ? aimAngle : aimAngle + math.pi * 2 * i / beamCount;
      final dir = Vec2(x: math.cos(angle), y: math.sin(angle));
      final spawnPos = Vec2(
        x: player.pos.x + dir.x * muzzleDist,
        y: player.pos.y + dir.y * muzzleDist,
      );

      // Add the visual effect (Crossbow bolt trail)
      attacks.add(AttackEffectData(
        id: _nextId('bolt'),
        ownerId: player.id,
        type: 'laser', // Keep key for rendering consistency
        pos: spawnPos,
        radius: LASER_RANGE,
        angle: angle,
        createdAt: now,
        durationMs: 250, // Shorter for a bolt flash
        scale: LASER_WIDTH,
      ));

      final beamEnd = Vec2(
        x: spawnPos.x + dir.x * LASER_RANGE,
        y: spawnPos.y + dir.y * LASER_RANGE,
      );
      for (final enemy in players) {
        if (!enemy.alive || !enemy.isEnemy) continue;
        final hitDistance =
            _distancePointToSegment(enemy.pos, spawnPos, beamEnd);
        // Crossbow bolt hits everyone in a line
        if (hitDistance > enemy.radius + 8 * LASER_WIDTH) continue;
        _dealDamage(
          player,
          enemy,
          LASER_DAMAGE + player.atk * LASER_ATTACK_DAMAGE_RATIO,
        );
      }
    }
  }

  void _handleBladeAttack(PlayerData player, int now) {
    // This is now the Spear 'Thrust' attack
    final cooldown = _getAbilityCooldown(player, BLADE_ATTACK_MS);
    if (now - player.lastBladeAt < cooldown) return;
    final target = _findNearestOpponent(player, BLADE_RANGE + 40);
    if (target == null) return;
    
    player.lastBladeAt = now;
    player.lastAttackAt = now;
    
    final aimAngle = math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    player.targetAngle = aimAngle;
    
    final weaponCount = math.max(1, player.weaponCount);
    final muzzleDist = player.radius;

    for (int i = 0; i < weaponCount; i++) {
      final angle = aimAngle + (weaponCount == 1 ? 0 : (math.pi * 2 * i / weaponCount));
      final dir = Vec2(x: math.cos(angle), y: math.sin(angle));
      final spawnPos = Vec2(
        x: player.pos.x + dir.x * muzzleDist,
        y: player.pos.y + dir.y * muzzleDist,
      );

      // Add the visual effect (Spear thrust)
      attacks.add(AttackEffectData(
        id: _nextId('thrust'),
        ownerId: player.id,
        type: 'blade', // Keep key for rendering
        pos: spawnPos,
        radius: BLADE_RANGE,
        angle: angle,
        createdAt: now,
        durationMs: BLADE_EFFECT_MS,
      ));

      // Melee damage check
      final thrustEnd = Vec2(
        x: spawnPos.x + dir.x * BLADE_RANGE,
        y: spawnPos.y + dir.y * BLADE_RANGE,
      );
      
      for (final enemy in players) {
        if (!enemy.alive || !enemy.isEnemy) continue;
        final hitDistance = _distancePointToSegment(enemy.pos, spawnPos, thrustEnd);
        if (hitDistance > enemy.radius + 15) continue;
        
        _dealDamage(
          player,
          enemy,
          BASE_ATK + player.atk * 1.5, // High melee damage
        );
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
      bool hitWall = false;
      if (p.pos.x < 0 || p.pos.x > ARENA_WIDTH) {
        p.vel.x = -p.vel.x;
        p.pos.x = p.pos.x < 0 ? 0 : ARENA_WIDTH.toDouble();
        hitWall = true;
      }
      if (p.pos.y < 0 || p.pos.y > ARENA_HEIGHT) {
        p.vel.y = -p.vel.y;
        p.pos.y = p.pos.y < 0 ? 0 : ARENA_HEIGHT.toDouble();
        hitWall = true;
      }
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
      final damage = owner.isEnemy
          ? ENEMY_BULLET_DAMAGE
          : BASE_BULLET_DAMAGE + owner.atk * BULLET_ATTACK_DAMAGE_RATIO;
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
          _dealDamage(
            owner,
            target,
            MINE_DAMAGE + owner.atk * MINE_ATTACK_DAMAGE_RATIO,
          );
          hazards.removeAt(i);
          break;
        }
        final poisonDamage =
            (1.7 + owner.abilityPower * 0.45 + owner.weaponLevel * 0.18) *
                (dt / 1000);
        _dealDamage(owner, target, poisonDamage);
      }
    }
  }

  void _cleanupEffects(int now) {
    for (int i = attacks.length - 1; i >= 0; i -= 1) {
      if (now - attacks[i].createdAt >= attacks[i].durationMs) {
        attacks.removeAt(i);
      }
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
      players.add(child);
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

  double _normalizeAngle(double angle) {
    const fullTurn = math.pi * 2;
    final normalized = angle % fullTurn;
    return normalized < 0 ? normalized + fullTurn : normalized;
  }

  PlayerData? _findNearestOpponent(PlayerData player, double range) {
    PlayerData? best;
    var bestDistance = range;
    for (final other in players) {
      if (!other.alive || other.id == player.id) continue;
      if (other.isEnemy == player.isEnemy) continue;
      final d = distance(player.pos, other.pos);
      if (d >= bestDistance) continue;
      bestDistance = d;
      best = other;
    }
    return best;
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
      arenaWidth: ARENA_WIDTH.toDouble(),
      arenaHeight: ARENA_HEIGHT.toDouble(),
      roundState: roundState,
      winnerId: winnerId,
      roundEndsAt: roundEndsAt,
      aliveCount: players.where((p) => p.alive).length,
      players: players
          .map((p) => PlayerSnapshot(
                id: p.id,
                characterType: p.characterType,
                isEnemy: p.isEnemy,
                hp: p.hp,
                maxHp: p.maxHp,
                atk: p.atk,
                def: p.def,
                speed: p.speed,
                abilityPower: p.abilityPower,
                shield: p.shield,
                maxShield: p.maxShield,
                weaponLevel: p.weaponLevel,
                weaponCount: p.weaponCount,
                bulletReflectCount: p.bulletReflectCount,
                bulletsPerWeapon: p.bulletsPerWeapon,
                regen: p.regen,
                lifesteal: p.lifesteal,
                barrierHp: p.barrierHp,
                barrierMaxHp: p.barrierMaxHp,
                gold: p.gold,
                totalGold: p.totalGold,
                unspentUpgrades: p.pendingUpgradeCount,
                upgradeChoices: p.upgradeChoices
                    .map((u) => UpgradeOption(
                          type: u.type,
                          rarity: u.rarity,
                          title: u.title,
                          description: u.description,
                          statPreview: u.statPreview,
                        ))
                    .toList(),
                kills: p.kills,
                damageDealt: p.damageDealt.roundToDouble(),
                damageTaken: p.damageTaken.roundToDouble(),
                x: p.pos.x,
                y: p.pos.y,
                vx: p.vel.x,
                vy: p.vel.y,
                radius: p.radius,
                color: p.color,
                alive: p.alive,
                lives: p.lives,
                maxLives: p.maxLives,
                lastAttackAt: p.lastAttackAt,
                targetAngle: p.targetAngle,
              ))
          .toList(),
      foods: foods
          .map((f) => FoodSnapshot(
                id: f.id,
                x: f.pos.x,
                y: f.pos.y,
                radius: f.radius,
                gold: f.gold,
                kind: f.kind,
              ))
          .toList(),
      projectiles: projectiles
          .map((p) => ProjectileSnapshot(
                id: p.id,
                ownerId: p.ownerId,
                x: p.pos.x,
                y: p.pos.y,
                vx: p.vel.x,
                vy: p.vel.y,
                radius: p.radius,
                color: p.color,
                reflectsRemaining: p.reflectsRemaining,
              ))
          .toList(),
      hazards: hazards
          .map((h) => HazardSnapshot(
                id: h.id,
                ownerId: h.ownerId,
                type: h.type,
                x: h.pos.x,
                y: h.pos.y,
                radius: h.radius,
                expiresAt: h.expiresAt,
              ))
          .toList(),
      attacks: attacks
          .map((a) => AttackSnapshot(
                id: a.id,
                ownerId: a.ownerId,
                type: a.type,
                x: a.pos.x,
                y: a.pos.y,
                radius: a.radius,
                angle: a.angle,
                createdAt: a.createdAt,
                durationMs: a.durationMs,
                scale: a.scale,
              ))
          .toList(),
    );
    onUpdate(snapshot);
  }
}
