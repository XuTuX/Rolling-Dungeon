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
  int currentStage = 1;
  String? winnerId;
  int? roundEndsAt;
  int idSeq = 0;

  final math.Random _rand = math.Random();

  GameEngine({required this.onUpdate}) {
    players.add(_createPlayer());
    _spawnEnemiesForStage(currentStage);
    _fillFoods();
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

  void handleUpgrade(String type) {
    final player = _getPlayer('p1');
    if (player == null || player.pendingUpgradeCount <= 0) return;

    final selected = player.upgradeChoices.cast<UpgradeOptionData?>().firstWhere(
      (c) => c?.type == type,
      orElse: () => null,
    );
    if (selected == null) return;

    _applyUpgrade(player, selected);
    player.pendingUpgradeCount -= 1;
    
    if (player.pendingUpgradeCount > 0) {
      player.upgradeChoices = _createUpgradeChoices(player);
    } else {
      player.upgradeChoices = [];
    }
  }

  void _tick(int dt) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final p1 = _getPlayer('p1');
    
    if (p1 == null) return;

    if (roundState == 'waiting') {
      roundState = 'running';
    }

    if (roundState == 'ended') {
      if (roundEndsAt != null && now >= roundEndsAt!) {
        _resetRound(now);
      }
      _broadcastSnapshot();
      return;
    }

    if (roundState == 'upgrading') {
      _checkUpgradingStatus(now);
      _broadcastSnapshot();
      return;
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

  void _checkUpgradingStatus(int now) {
    final stillUpgrading = players.any((p) => p.pendingUpgradeCount > 0);
    
    if (!stillUpgrading) {
      for (final p in players) {
        p.pendingUpgradeCount = 0;
        p.upgradeChoices = [];
      }
      roundState = 'ended';
      roundEndsAt = now + ROUND_RESTART_MS;
    }
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

  PlayerData _createPlayer() {
    return PlayerData(
      id: 'p1',
      characterType: 'none',
      hp: BASE_HP,
      maxHp: BASE_HP,
      atk: BASE_ATK,
      def: BASE_DEF,
      speed: BASE_SPEED,
      abilityPower: 1,
      gold: 0,
      totalGold: 0,
      pendingUpgradeCount: 0,
      upgradeChoices: [],
      kills: 0,
      damageDealt: 0,
      damageTaken: 0,
      pos: Vec2(x: 250, y: 250),
      vel: normalize(Vec2(x: 1, y: 0.1)),
      radius: PLAYER_RADIUS,
      activeEffects: [],
      color: '#4F8CFF',
      alive: true,
      lives: MAX_LIVES,
      maxLives: MAX_LIVES,
      lastCollisionAt: {},
      lastPoisonDropAt: 0,
      lastShotAt: 0,
      lastBladeAt: 0,
      lastMineDropAt: 0,
    );
  }

  void _resetPlayerForNextRound(PlayerData player, int now) {
    player.hp = player.maxHp;
    player.pos = Vec2(x: 250, y: 250);
    player.vel = normalize(Vec2(x: 1, y: 0.1));
    player.alive = true;
    player.lastCollisionAt = {};
    player.lastPoisonDropAt = now;
    player.lastShotAt = now;
    player.lastBladeAt = now;
    player.lastMineDropAt = now;
    player.activeEffects = [];
  }

  void _resetRound(int now) {
    final player = _getPlayer('p1');
    if (player == null) return;

    if (winnerId == player.id) {
      currentStage += 1;
    }

    players = [player];
    _resetPlayerForNextRound(player, now);
    _spawnEnemiesForStage(currentStage);

    foods.clear();
    projectiles.clear();
    hazards.clear();
    attacks.clear();
    roundState = 'running';
    winnerId = null;
    roundEndsAt = null;
    lastFoodSpawnAt = now;
    _fillFoods();
  }

  void _spawnEnemiesForStage(int stage) {
    final List<Map<String, dynamic>> enemiesToSpawn = [];
    if (stage == 1) {
      enemiesToSpawn.add({'type': 'basic', 'count': 3});
    } else if (stage == 2) {
      enemiesToSpawn.add({'type': 'basic', 'count': 5});
    } else if (stage == 3) {
      enemiesToSpawn.add({'type': 'basic', 'count': 1});
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
      enemiesToSpawn.add({'type': 'basic', 'count': 10});
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
    final hpMult = stage * 0.5 + 0.5;
    
    double hp = 100 * hpMult;
    double speed = 2.0;
    double radius = PLAYER_RADIUS;
    String color = '#FF5E5E';
    double atk = 5.0 + stage;
    double def = 1.0 + stage * 0.5;

    if (type == 'fast') {
      speed = 4.0;
      hp = 50 * hpMult;
      color = '#FFB84D';
    } else if (type == 'tank') {
      speed = 1.2;
      hp = 250 * hpMult;
      radius = PLAYER_RADIUS * 1.5;
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

  void _triggerUpgrades() {
    final p1 = _getPlayer('p1');
    if (p1 != null && winnerId == p1.id) {
      p1.pendingUpgradeCount = 1;
      p1.upgradeChoices = _createUpgradeChoices(p1);
      roundState = 'upgrading';
    } else {
      roundState = 'ended';
      roundEndsAt = DateTime.now().millisecondsSinceEpoch + ROUND_RESTART_MS;
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
    }
  }

  void _dropPoison(PlayerData player, int now) {
    if (now - player.lastPoisonDropAt < _getAbilityCooldown(player, POISON_DROP_MS)) return;
    player.lastPoisonDropAt = now;
    hazards.add(HazardData(
      id: _nextId('poison'),
      ownerId: player.id,
      type: 'poison',
      pos: player.pos.clone(),
      radius: POISON_RADIUS,
      expiresAt: now + POISON_DURATION_MS,
      lastDamageAt: {},
    ));
  }

  void _fireBullet(PlayerData player, int now) {
    if (now - player.lastShotAt < _getAbilityCooldown(player, GUNNER_FIRE_MS)) return;
    final target = _findNearestEnemy(player, GUNNER_RANGE);
    if (target == null) return;
    player.lastShotAt = now;
    final direction = normalize(Vec2(x: target.pos.x - player.pos.x, y: target.pos.y - player.pos.y));
    projectiles.add(ProjectileData(
      id: _nextId('bullet'),
      ownerId: player.id,
      pos: player.pos.clone(),
      vel: direction,
      radius: BULLET_RADIUS,
      color: player.color,
    ));
  }

  void _fireLaser(PlayerData player, int now) {
    if (now - player.lastShotAt < _getAbilityCooldown(player, LASER_FIRE_MS)) return;
    final target = _findNearestEnemy(player, LASER_RANGE);
    if (target == null) return;
    player.lastShotAt = now;
    final angle = math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    attacks.add(AttackEffectData(
      id: _nextId('laser'),
      ownerId: player.id,
      type: 'laser',
      pos: player.pos.clone(),
      radius: LASER_RANGE,
      angle: angle,
      createdAt: now,
      durationMs: LASER_DURATION_MS,
    ));
    _dealDamage(player, target, 15 + player.atk * 0.5 + player.abilityPower * 1.8);
  }

  void _swingBlade(PlayerData player, int now) {
    if (now - player.lastBladeAt < _getAbilityCooldown(player, BLADE_ATTACK_MS)) return;
    final target = _findNearestEnemy(player, BLADE_RANGE);
    if (target == null) return;
    player.lastBladeAt = now;
    final angle = math.atan2(target.pos.y - player.pos.y, target.pos.x - player.pos.x);
    _dealDamage(player, target, 10 + player.atk * 0.8 + player.abilityPower * 1.4);
    attacks.add(AttackEffectData(
      id: _nextId('blade'),
      ownerId: player.id,
      type: 'blade',
      pos: player.pos.clone(),
      radius: BLADE_RANGE,
      angle: angle,
      createdAt: now,
      durationMs: BLADE_EFFECT_MS,
    ));
  }

  void _dropMine(PlayerData player, int now) {
    if (now - player.lastMineDropAt < _getAbilityCooldown(player, MINER_DROP_MS)) return;
    player.lastMineDropAt = now;
    hazards.add(HazardData(
      id: _nextId('mine'),
      ownerId: player.id,
      type: 'mine',
      pos: player.pos.clone(),
      radius: MINE_RADIUS,
      expiresAt: now + MINE_DURATION_MS,
      lastDamageAt: {},
    ));
  }

  void _updateProjectiles(double dt) {
    for (int i = projectiles.length - 1; i >= 0; i -= 1) {
      final p = projectiles[i];
      p.pos.x += p.vel.x * BULLET_SPEED * dt;
      p.pos.y += p.vel.y * BULLET_SPEED * dt;
      if (p.pos.x < 0 || p.pos.x > ARENA_WIDTH || p.pos.y < 0 || p.pos.y > ARENA_HEIGHT) {
        projectiles.removeAt(i);
        continue;
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
      p1.lives -= 1;
      if (p1.lives <= 0) {
        roundState = 'gameover';
      } else {
        roundState = 'ended';
        winnerId = 'enemy';
        roundEndsAt = now + ROUND_RESTART_MS;
      }
      return;
    }

    final aliveEnemies = players.where((p) => p.isEnemy && p.alive).toList();
    if (aliveEnemies.isEmpty) {
      winnerId = p1.id;
      if (currentStage >= VICTORY_STAGE) {
        roundState = 'victory';
      } else {
        _triggerUpgrades();
      }
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

  void _applyUpgrade(PlayerData player, UpgradeOptionData option) {
    final type = option.type;
    final rarity = option.rarity;
    final mult = rarity == 'epic' ? 2.5 : rarity == 'rare' ? 1.6 : 1.0;
    switch (type) {
      case 'assault': player.atk += (UPGRADE_ASSAULT_ATK_GAIN * mult).round(); break;
      case 'guard': player.def += (UPGRADE_GUARD_DEF_GAIN * mult).round(); player.maxHp += (UPGRADE_GUARD_HP_GAIN * mult).round(); player.hp = math.min(player.maxHp, player.hp + 14); break;
      case 'haste': player.speed = math.min(MAX_SPEED, player.speed + UPGRADE_HASTE_SPEED_GAIN * mult); break;
      case 'vitality': player.maxHp += (UPGRADE_VITALITY_HP_GAIN * mult).round(); player.hp = math.min(player.maxHp, player.hp + (UPGRADE_VITALITY_HEAL * mult).round()); break;
      case 'mastery': player.atk += (UPGRADE_MASTERY_ATK_GAIN * mult).round(); player.abilityPower += UPGRADE_MASTERY_POWER_GAIN * mult; break;
      case 'weapon_gun': player.characterType = 'gunner'; break;
      case 'weapon_blade': player.characterType = 'blade'; break;
      case 'weapon_mine': player.characterType = 'miner'; break;
      case 'weapon_laser': player.characterType = 'laser'; break;
    }
  }

  List<UpgradeOptionData> _createUpgradeChoices(PlayerData player) {
    final choices = <UpgradeOptionData>[];
    if (player.characterType == 'none') {
      final weapons = ['weapon_gun', 'weapon_blade', 'weapon_mine', 'weapon_laser'];
      for (final t in weapons) {
        String title = '', desc = '';
        switch (t) {
          case 'weapon_gun': title = '원거리 사격 (총)'; desc = '멀리서 총을 쏴서 적을 공격합니다.'; break;
          case 'weapon_blade': title = '근접 베기 (칼)'; desc = '주변의 적을 강력하게 베어버립니다.'; break;
          case 'weapon_mine': title = '지뢰 매설'; desc = '바닥에 지뢰를 깔아 밟은 적에게 피해를 줍니다.'; break;
          case 'weapon_laser': title = '정밀 레이저'; desc = '가장 가까운 적에게 지속적인 레이저를 쏩니다.'; break;
        }
        choices.add(UpgradeOptionData(type: t, rarity: 'epic', title: title, description: desc, statPreview: 'WEAPON UNLOCK'));
      }
      choices.shuffle(_rand);
      return choices.sublist(0, 3);
    }
    final types = ['assault', 'guard', 'haste', 'vitality', 'mastery'];
    types.shuffle(_rand);
    final selected = types.sublist(0, LEVEL_CHOICE_COUNT);
    for (final t in selected) {
      final roll = _rand.nextDouble();
      final rar = roll < 0.1 ? 'epic' : roll < 0.3 ? 'rare' : 'common';
      final mult = rar == 'epic' ? 2.5 : rar == 'rare' ? 1.6 : 1.0;
      String title = '', desc = '', stat = '';
      switch (t) {
        case 'assault': title = rar == 'epic' ? '광폭화 공격' : rar == 'rare' ? '강력한 공격' : '공격 강화'; desc = '공격력을 대폭 올립니다.'; stat = 'ATK +${(UPGRADE_ASSAULT_ATK_GAIN * mult).round()}'; break;
        case 'guard': title = rar == 'epic' ? '철벽 방어' : rar == 'rare' ? '단단한 가드' : '방어 강화'; desc = '방어력과 체력을 높입니다.'; stat = 'DEF +${(UPGRADE_GUARD_DEF_GAIN * mult).round()}'; break;
        case 'haste': title = rar == 'epic' ? '광속 이동' : rar == 'rare' ? '빠른 몸놀림' : '속도 강화'; desc = '이동 속도가 빨라집니다.'; stat = 'SPD +${(UPGRADE_HASTE_SPEED_GAIN * mult).toStringAsFixed(2)}'; break;
        case 'vitality': title = rar == 'epic' ? '무한한 생명' : rar == 'rare' ? '강인한 생명력' : '생존 본능'; desc = '최대 체력을 키우고 회복합니다.'; stat = 'HP +${(UPGRADE_VITALITY_HP_GAIN * mult).round()}'; break;
        case 'mastery': title = _getMasteryTitle(player.characterType, rar); desc = _getMasteryDescription(player.characterType); stat = 'PWR +${(UPGRADE_MASTERY_POWER_GAIN * mult).toStringAsFixed(1)}'; break;
      }
      choices.add(UpgradeOptionData(type: t, rarity: rar, title: title, description: desc, statPreview: stat));
    }
    return choices;
  }

  String _getMasteryTitle(String t, String r) {
    final s = r == 'epic' ? ' 극의' : r == 'rare' ? ' 숙련' : ' 강화';
    switch (t) {
      case 'poison': return '독성$s';
      case 'gunner': return '탄도$s';
      case 'blade': return '검술$s';
      case 'miner': return '설계$s';
      case 'laser': return '광학$s';
      default: return '숙련$s';
    }
  }

  String _getMasteryDescription(String t) {
    switch (t) {
      case 'poison': return '독 피해를 키웁니다.';
      case 'gunner': return '총알 피해를 키웁니다.';
      case 'blade': return '베기 피해를 키웁니다.';
      case 'miner': return '지뢰 피해를 키웁니다.';
      case 'laser': return '레이저 대미지를 키웁니다.';
      default: return '능력을 강화합니다.';
    }
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
      )).toList(),
    );
    onUpdate(snapshot);
  }
}
