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
  int lastFoodSpawnAt = 0;
  
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
    // Apply stage-based radius to the player
    initialPlayer.radius = _getPlayerRadius();
    players.add(initialPlayer);
    _spawnEnemiesForStage(currentStage);
    _fillFoods();
  }

  // ── Stage Scaling Helpers ──
  /// Linearly interpolate a value from stage 1 to stage 10.
  double _lerpStage(double start, double end) {
    final t = ((currentStage - 1) / 9.0).clamp(0.0, 1.0);
    return start + (end - start) * t;
  }

  int _lerpStageInt(int start, int end) {
    return _lerpStage(start.toDouble(), end.toDouble()).round();
  }

  double _getPlayerRadius() {
    return _lerpStage(PLAYER_RADIUS_STAGE_1, PLAYER_RADIUS_STAGE_10);
  }

  double _getEnemyRadiusMult() {
    return _lerpStage(ENEMY_RADIUS_MULT_STAGE_1, ENEMY_RADIUS_MULT_STAGE_10);
  }

  double _getEnemyHpMult() {
    return _lerpStage(ENEMY_HP_MULT_STAGE_1, ENEMY_HP_MULT_STAGE_10);
  }

  int _getStageShotCount() {
    return _lerpStageInt(GUNNER_SHOTS_STAGE_1, GUNNER_SHOTS_STAGE_10);
  }

  double _getStageSpread() {
    return _lerpStage(GUNNER_SPREAD_STAGE_1, GUNNER_SPREAD_STAGE_10);
  }

  int _getStageReflect() {
    return _lerpStageInt(BULLET_REFLECT_STAGE_1, BULLET_REFLECT_STAGE_10);
  }

  double _getFireRateMult() {
    return _lerpStage(FIRE_RATE_MULT_STAGE_1, FIRE_RATE_MULT_STAGE_10);
  }

  double _getBladeRangeMult() {
    return _lerpStage(BLADE_RANGE_MULT_STAGE_1, BLADE_RANGE_MULT_STAGE_10);
  }

  double _getLaserWidth() {
    return _lerpStage(LASER_WIDTH_STAGE_1, LASER_WIDTH_STAGE_10);
  }

  int _getStageMineCount() {
    return _lerpStageInt(MINE_COUNT_STAGE_1, MINE_COUNT_STAGE_10);
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

    _spawnFoodOverTime(now);
    _updatePlayers(dt.toDouble(), now);
    _handleCollisions(now);
    _handleFoodPickup();
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
      updatePosition(player, dt);
      handleWallCollision(player);
    }
  }

  void _handleCollisions(int now) {
    for (int i = 0; i < players.length; i += 1) {
      for (int j = i + 1; j < players.length; j += 1) {
        final a = players[i];
        final b = players[j];
        if (!a.alive || !b.alive) continue;
        if (!checkCircleCollision(a, b)) continue;

        resolveCircleCollision(a, b);
        _applyCollisionDamage(a, b, now);
        _applyCollisionDamage(b, a, now);
      }
    }
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
      enemiesToSpawn.add({'type': 'basic', 'count': 3});
    } else if (stage == 2) {
      enemiesToSpawn.add({'type': 'basic', 'count': 5});
    } else if (stage == 3) {
      enemiesToSpawn.add({'type': 'basic', 'count': 7});
    } else if (stage == 4) {
      enemiesToSpawn.add({'type': 'fast', 'count': 3});
      enemiesToSpawn.add({'type': 'basic', 'count': 2});
    } else if (stage == 5) {
      enemiesToSpawn.add({'type': 'boss', 'count': 1});
    } else if (stage == 6) {
      enemiesToSpawn.add({'type': 'tank', 'count': 2});
      enemiesToSpawn.add({'type': 'basic', 'count': 4});
    } else if (stage == 7) {
      enemiesToSpawn.add({'type': 'fast', 'count': 5});
      enemiesToSpawn.add({'type': 'tank', 'count': 2});
    } else if (stage == 8) {
      enemiesToSpawn.add({'type': 'fast', 'count': 4});
      enemiesToSpawn.add({'type': 'tank', 'count': 4});
    } else if (stage == 9) {
      enemiesToSpawn.add({'type': 'basic', 'count': 12});
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
    final stageHpMult = stage * 0.5 + 0.5;
    final earlyHpMult = _getEnemyHpMult(); // lower early = faster kills
    final radiusMult = _getEnemyRadiusMult();
    
    double hp = 100 * stageHpMult * earlyHpMult;
    double speed = 2.0;
    double radius = PLAYER_RADIUS * radiusMult;
    String color = '#FF5E5E';
    double atk = 5.0 + stage;
    double def = 1.0 + stage * 0.5;

    if (type == 'fast') {
      speed = 4.0;
      hp = 50 * stageHpMult * earlyHpMult;
      radius = PLAYER_RADIUS * radiusMult * 0.85;
      color = '#FFB84D';
    } else if (type == 'tank') {
      speed = 1.2;
      hp = 250 * stageHpMult * earlyHpMult;
      radius = PLAYER_RADIUS * radiusMult * 1.5;
      color = '#8A2BE2';
      def = 5.0 + stage;
    } else if (type == 'boss') {
      speed = 2.5;
      hp = 1000;
      radius = PLAYER_RADIUS * 2.5;
      color = '#FF0000';
      atk = 15;
    } else if (type == 'final_boss') {
      speed = 3.0;
      hp = 3000;
      radius = PLAYER_RADIUS * 3;
      color = '#000000';
      atk = 25;
      def = 10;
    }

    final angle = _rand.nextDouble() * math.pi * 2;
    final spawnDist = 150 + _rand.nextDouble() * 50;
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
      gold: 0,
      totalGold: 0,
      pendingUpgradeCount: 0,
      upgradeChoices: [],
      kills: 0,
      damageDealt: 0,
      damageTaken: 0,
      pos: Vec2(x: ARENA_WIDTH / 2 + math.cos(angle) * spawnDist, y: ARENA_HEIGHT / 2 + math.sin(angle) * spawnDist),
      vel: normalize(Vec2(x: math.cos(angle), y: math.sin(angle))),
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
      activeEffects: [],
    );
  }

  void _spawnFoodOverTime(int now) {
    if (now - lastFoodSpawnAt < FOOD_SPAWN_MS) return;
    lastFoodSpawnAt = now;
    final maxFood = currentStage == 3 ? FOOD_MAX_COUNT * 2 : FOOD_MAX_COUNT;
    if (foods.length < maxFood) {
      foods.add(_createFood());
    }
  }

  void _fillFoods() {
    final maxFood = currentStage == 3 ? FOOD_MAX_COUNT * 2 : FOOD_MAX_COUNT;
    while (foods.length < maxFood) {
      foods.add(_createFood());
    }
  }

  FoodData _createFood() {
    final isBig = _rand.nextDouble() < FOOD_BIG_CHANCE;
    final radius = isBig ? 7.0 : 4.0;
    return FoodData(
      id: _nextId('food'),
      pos: Vec2(
        x: radius + _rand.nextDouble() * (ARENA_WIDTH - radius * 2),
        y: radius + _rand.nextDouble() * (ARENA_HEIGHT - radius * 2),
      ),
      radius: radius,
      gold: isBig ? FOOD_BIG_GOLD : FOOD_SMALL_GOLD,
      kind: isBig ? 'big' : 'small',
    );
  }

  void _handleFoodPickup() {
    for (final player in players) {
      if (!player.alive) continue;
      for (int i = foods.length - 1; i >= 0; i -= 1) {
        final food = foods[i];
        if (distance(player.pos, food.pos) > player.radius + food.radius) continue;
        foods.removeAt(i);
        _addGold(player, food.gold);
      }
    }
  }

  void _handleAbilities(int now) {
    for (final player in players) {
      if (!player.alive || player.isEnemy) continue;
      switch (player.characterType) {
        case 'poison': _dropPoison(player, now); break;
        case 'gunner': _fireBullet(player, now); break;
        case 'blade': _swingBlade(player, now); break;
        case 'miner': _dropMine(player, now); break;
        case 'laser': _fireLaser(player, now); break;
      }
      
      // Update targetAngle for rendering (point at nearest enemy if any)
      final nearest = _findNearestEnemy(player, 600.0);
      if (nearest != null) {
        player.targetAngle = math.atan2(nearest.pos.y - player.pos.y, nearest.pos.x - player.pos.x);
      } else {
        // Fallback to velocity if no enemy
        if (math.sqrt(player.vel.x * player.vel.x + player.vel.y * player.vel.y) > 0.01) {
          player.targetAngle = math.atan2(player.vel.y, player.vel.x);
        }
      }
    }
  }

  void _dropPoison(PlayerData player, int now) {
    if (now - player.lastPoisonDropAt < _getAbilityCooldown(player, POISON_DROP_MS)) return;
    player.lastPoisonDropAt = now;
    player.lastAttackAt = now;
    // Drop slightly forward (~0.5x radius)
    final forwardDist = player.radius * 0.5;
    final spawnPos = Vec2(
      x: player.pos.x + player.vel.x * forwardDist,
      y: player.pos.y + player.vel.y * forwardDist,
    );

    hazards.add(HazardData(
      id: _nextId('poison'),
      ownerId: player.id,
      type: 'poison',
      pos: spawnPos,
      radius: POISON_RADIUS,
      expiresAt: now + POISON_DURATION_MS,
      lastDamageAt: {},
    ));
  }

  void _fireBullet(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, GUNNER_FIRE_MS) * _getFireRateMult();
    if (now - player.lastShotAt < cooldown) return;
    final target = _findNearestEnemy(player, GUNNER_RANGE);
    if (target == null) return;
    player.lastShotAt = now;
    player.lastAttackAt = now;
    final baseAngle = math.atan2(
      target.pos.y - player.pos.y,
      target.pos.x - player.pos.x,
    );
    final shotCount = _getStageShotCount();
    final spread = _getStageSpread();
    final reflectCount = _getStageReflect();

    for (int i = 0; i < shotCount; i++) {
      double angle = baseAngle;
      if (shotCount > 1) {
        // Evenly distribute shots across the spread arc
        angle = baseAngle - spread / 2 + spread * (i / (shotCount - 1));
      }
      final direction = Vec2(x: math.cos(angle), y: math.sin(angle));
      
      // Spawn bullet from muzzle (~2.2x radius)
      final muzzleDist = player.radius * 2.2;
      final spawnPos = Vec2(
        x: player.pos.x + direction.x * muzzleDist,
        y: player.pos.y + direction.y * muzzleDist,
      );

      projectiles.add(ProjectileData(
        id: _nextId('bullet'),
        ownerId: player.id,
        pos: spawnPos,
        vel: direction,
        radius: BULLET_RADIUS,
        color: player.color,
        reflectsRemaining: reflectCount,
      ));
    }
  }

  void _fireLaser(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, LASER_FIRE_MS) * _getFireRateMult();
    if (now - player.lastShotAt < cooldown) return;
    final target = _findNearestEnemy(player, LASER_RANGE);
    if (target == null) return;
    player.lastShotAt = now;
    player.lastAttackAt = now;
    final angle = math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    final laserWidth = _getLaserWidth();
    
    // Laser spawns from cannon tip (~2.4x radius)
    final muzzleDist = player.radius * 2.4;
    final spawnPos = Vec2(
      x: player.pos.x + math.cos(angle) * muzzleDist,
      y: player.pos.y + math.sin(angle) * muzzleDist,
    );

    attacks.add(AttackEffectData(
      id: _nextId('laser'),
      ownerId: player.id,
      type: 'laser',
      pos: spawnPos,
      radius: LASER_RANGE,
      angle: angle,
      createdAt: now,
      durationMs: LASER_DURATION_MS,
      scale: laserWidth,
    ));
    _dealDamage(player, target, 15 + player.atk * 0.5 + player.abilityPower * 1.8);
  }

  void _swingBlade(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, BLADE_ATTACK_MS) * _getFireRateMult();
    final bladeRange = BLADE_RANGE * _getBladeRangeMult();
    if (now - player.lastBladeAt < cooldown) return;
    final target = _findNearestEnemy(player, bladeRange);
    if (target == null) return;
    player.lastBladeAt = now;
    player.lastAttackAt = now;
    final angle = math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    
    // Blade slash centered a bit forward (~1.2x radius)
    final forwardDist = player.radius * 1.2;
    final slashPos = Vec2(
      x: player.pos.x + math.cos(angle) * forwardDist,
      y: player.pos.y + math.sin(angle) * forwardDist,
    );

    // Hit ALL enemies in blade range
    for (final enemy in players) {
      if (!enemy.alive || enemy.id == player.id) continue;
      if (distance(player.pos, enemy.pos) <= bladeRange) {
        _dealDamage(player, enemy, 10 + player.atk * 0.8 + player.abilityPower * 1.4);
      }
    }
    attacks.add(AttackEffectData(
      id: _nextId('blade'),
      ownerId: player.id,
      type: 'blade',
      pos: slashPos,
      radius: bladeRange,
      angle: angle,
      createdAt: now,
      durationMs: BLADE_EFFECT_MS,
    ));
  }

  void _dropMine(PlayerData player, int now) {
    final cooldown = _getAbilityCooldown(player, MINER_DROP_MS) * _getFireRateMult();
    if (now - player.lastMineDropAt < cooldown) return;
    player.lastMineDropAt = now;
    player.lastAttackAt = now;
    final mineCount = _getStageMineCount();
    for (int i = 0; i < mineCount; i++) {
      final offset = i == 0
          ? Vec2(x: 0, y: 0)
          : Vec2(
              x: (_rand.nextDouble() - 0.5) * 40,
              y: (_rand.nextDouble() - 0.5) * 40,
            );
      final minePos = Vec2(
        x: (player.pos.x + offset.x + player.vel.x * 20).clamp(MINE_RADIUS, ARENA_WIDTH - MINE_RADIUS),
        y: (player.pos.y + offset.y + player.vel.y * 20).clamp(MINE_RADIUS, ARENA_HEIGHT - MINE_RADIUS),
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
      if (owner == null) { projectiles.removeAt(i); continue; }
      final target = players.cast<PlayerData?>().firstWhere(
        (pl) => pl != null && pl.alive && pl.id != p.ownerId && distance(pl.pos, p.pos) <= pl.radius + p.radius,
        orElse: () => null,
      );
      if (target == null) continue;
      _dealDamage(owner, target, 8 + owner.atk * 0.7 + owner.abilityPower * 1.1);
      projectiles.removeAt(i);
    }
  }

  void _updateHazards(int now, double dt) {
    for (int i = hazards.length - 1; i >= 0; i -= 1) {
      final hazard = hazards[i];
      if (now >= hazard.expiresAt) { hazards.removeAt(i); continue; }
      final owner = _getPlayer(hazard.ownerId);
      if (owner == null) { hazards.removeAt(i); continue; }
      for (final target in players) {
        if (!target.alive || target.id == hazard.ownerId) continue;
        if (distance(target.pos, hazard.pos) > target.radius + hazard.radius) continue;
        if (hazard.type == 'mine') {
          _dealDamage(owner, target, 10 + owner.atk * 0.55 + owner.abilityPower * 1.8);
          hazards.removeAt(i);
          break;
        }
        final poisonDamage = (1.7 + owner.abilityPower * 0.45) * (dt / 1000);
        _dealDamage(owner, target, poisonDamage);
      }
    }
  }

  void _cleanupEffects(int now) {
    for (int i = attacks.length - 1; i >= 0; i -= 1) {
      if (now - attacks[i].createdAt >= attacks[i].durationMs) attacks.removeAt(i);
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

  void _applyCollisionDamage(PlayerData attacker, PlayerData defender, int now) {
    defender.lastCollisionAt[attacker.id] = now;
    _dealDamage(attacker, defender, attacker.atk);
  }

  void _dealDamage(PlayerData attacker, PlayerData defender, double raw) {
    if (!attacker.alive || !defender.alive || raw <= 0) return;
    final dmg = math.max(0.25, raw - defender.def * 0.35);
    final prev = defender.hp;
    defender.hp = math.max(0.0, defender.hp - dmg);
    final actual = prev - defender.hp;
    attacker.damageDealt += actual;
    defender.damageTaken += actual;
    _addGold(attacker, actual * 0.8);
    if (defender.hp <= 0 && defender.alive) {
      defender.alive = false;
      attacker.kills += 1;
      _addGold(attacker, 20);
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

  PlayerData? _findNearestEnemy(PlayerData p, double range) {
    PlayerData? best;
    double bestDist = range;
    for (final other in players) {
      if (!other.alive || other.id == p.id) continue;
      final d = distance(p.pos, other.pos);
      if (d < bestDist) { bestDist = d; best = other; }
    }
    return best;
  }

  String _nextId(String prefix) { return '${prefix}_${idSeq++}'; }

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
      players: players.map((p) => PlayerSnapshot(
        id: p.id,
        characterType: p.characterType,
        isEnemy: p.isEnemy,
        hp: p.hp,
        maxHp: p.maxHp,
        atk: p.atk,
        def: p.def,
        speed: p.speed,
        abilityPower: p.abilityPower,
        gold: p.gold,
        totalGold: p.totalGold,
        unspentUpgrades: p.pendingUpgradeCount,
        upgradeChoices: p.upgradeChoices.map((u) => UpgradeOption(
          type: u.type,
          rarity: u.rarity,
          title: u.title,
          description: u.description,
          statPreview: u.statPreview,
        )).toList(),
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
      )).toList(),
      foods: foods.map((f) => FoodSnapshot(
        id: f.id,
        x: f.pos.x,
        y: f.pos.y,
        radius: f.radius,
        gold: f.gold,
        kind: f.kind,
      )).toList(),
      projectiles: projectiles.map((p) => ProjectileSnapshot(
        id: p.id,
        ownerId: p.ownerId,
        x: p.pos.x,
        y: p.pos.y,
        vx: p.vel.x,
        vy: p.vel.y,
        radius: p.radius,
        color: p.color,
        reflectsRemaining: p.reflectsRemaining,
      )).toList(),
      hazards: hazards.map((h) => HazardSnapshot(
        id: h.id,
        ownerId: h.ownerId,
        type: h.type,
        x: h.pos.x,
        y: h.pos.y,
        radius: h.radius,
        expiresAt: h.expiresAt,
      )).toList(),
      attacks: attacks.map((a) => AttackSnapshot(
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
      )).toList(),
    );
    onUpdate(snapshot);
  }
}
