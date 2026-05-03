import 'dart:math' as math;
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';
import 'package:get/get.dart';

/// Upgrade card data used during the upgrade selection phase.
class UpgradeCard {
  final String type;
  final String rarity; // 'common', 'rare', 'epic'
  final String title;
  final String description;
  final String statPreview;
  final double multiplier;

  const UpgradeCard({
    required this.type,
    required this.rarity,
    required this.title,
    required this.description,
    required this.statPreview,
    required this.multiplier,
  });
}

class ShopItem {
  final String id;
  final String title;
  final String description;
  final int price;
  final String weaponType;
  final String icon;

  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.weaponType,
    required this.icon,
  });
}

class _UpgradeDraft {
  final String type;
  final String title;
  final String description;
  final String statPreview;

  const _UpgradeDraft({
    required this.type,
    required this.title,
    required this.description,
    required this.statPreview,
  });
}

class GameProgressController extends GetxController {
  // ── Run State ──
  var currentStage = 1.obs;
  var lives = 3.obs;
  var gold = 0.obs;

  // ── Cycle System ──
  var currentCycle = 1.obs;
  var stageInCycle = 1.obs;
  var totalStageNumber = 1.obs;
  bool get isBossStage => stageInCycle.value >= BOSS_STAGE_IN_CYCLE;

  // ── Run Stats (for achievements at end of run) ──
  var runEnemiesKilled = 0.obs;
  var runBossesDefeated = 0.obs;
  var runDamageDealt = 0.0.obs;

  // ── Player Stats (accumulated across stages) ──
  var playerMaxHp = PLAYER_BASE_HP.obs;
  var playerCurrentHp = PLAYER_BASE_HP.obs;
  var playerAtk = PLAYER_BASE_ATTACK.obs;
  var playerDef = PLAYER_BASE_DEFENSE.obs;
  var playerSpd = PLAYER_BASE_SPEED.obs;
  var playerRadius = PLAYER_BASE_RADIUS.obs;
  var playerAbilityPower = 1.0.obs;
  var playerShield = 0.0.obs;
  var playerMaxShield = 0.0.obs;
  var playerWeaponLevel = 0.obs;
  var playerWeaponCount = PLAYER_STARTING_WEAPON_COUNT.obs;
  var playerBulletReflectCount = PLAYER_STARTING_BULLET_REFLECTS.obs;
  var playerBulletsPerWeapon = PLAYER_STARTING_BULLETS_PER_WEAPON.obs;
  var playerRegen = 0.0.obs;
  var playerLifesteal = 0.0.obs;
  var playerCritChance = 0.0.obs;
  var playerBarrierHp = 0.0.obs;
  var playerBarrierMaxHp = 0.0.obs;

  // ── Character Type ──
  // ── Character Type & Weapons ──
  var characterType =
      'none'.obs; // character ID: 'square', 'triangle', 'circle'
  var characterShape = 'circle'.obs; // 'circle', 'square', 'triangle'
  final runUnlockedWeapons = <String>['gunner'].obs;
  final activeEquipment = <String, EquipmentShopDef>{}.obs;
  final ownedWeapons = <String>[].obs;
  final shopItems = <ShopItem>[].obs;

  // ── Upgrade history for display ──
  final appliedUpgrades = <String>[].obs;

  // ── Random for card generation ──
  final math.Random _rand = math.Random();

  // ───────────────────────────────────────────
  //  New Run
  // ───────────────────────────────────────────
  void startNewRun(
    String selectedCharacter,
    String selectedShape, {
    Iterable<String>? unlockedWeapons,
    Map<String, String>? equippedEquipment,
    Map<String, int>? statLevels,
  }) {
    currentStage.value = 1;
    currentCycle.value = 1;
    stageInCycle.value = 1;
    totalStageNumber.value = 1;
    lives.value = 3;
    gold.value = 0;
    appliedUpgrades.clear();
    activeEquipment.clear();
    ownedWeapons.clear();
    shopItems.clear();

    // Run stats reset
    runEnemiesKilled.value = 0;
    runBossesDefeated.value = 0;
    runDamageDealt.value = 0;

    final unlockedSet = <String>{
      'gunner',
      ...?unlockedWeapons,
    };
    characterType.value = selectedCharacter;
    characterShape.value = selectedShape;
    runUnlockedWeapons.value = _orderedRunWeapons(unlockedSet);
    activeEquipment.value = _resolvedEquipment(equippedEquipment ?? const {});

    playerRadius.value = PLAYER_BASE_RADIUS;

    playerAbilityPower.value = 1.0;
    playerShield.value = 0;
    playerMaxShield.value = 0;

    final charDef = kAllCharacters.firstWhere(
      (c) => c.id == selectedCharacter,
      orElse: () => kAllCharacters.first,
    );
    final loadoutStats = MetaProgressController.buildLoadoutStats(
      character: charDef,
      equipment: activeEquipment.values,
      statLevels: statLevels ?? const {},
    );
    playerMaxHp.value = loadoutStats.maxHp;
    playerAtk.value = loadoutStats.atk;
    playerDef.value = loadoutStats.def;
    playerSpd.value = loadoutStats.speed;
    playerWeaponCount.value = loadoutStats.weaponCount;
    playerBulletReflectCount.value = loadoutStats.bulletReflects;
    playerBulletsPerWeapon.value = loadoutStats.bulletsPerWeapon;
    playerRegen.value = loadoutStats.regen;
    playerLifesteal.value = 0;
    playerCritChance.value = loadoutStats.critChance;
    playerBarrierHp.value = loadoutStats.barrierHp;
    playerBarrierMaxHp.value = loadoutStats.barrierHp;
    _clampRunScalingStats();
    playerCurrentHp.value = playerMaxHp.value;
  }

  // ───────────────────────────────────────────
  //  Gold
  // ───────────────────────────────────────────
  void addGold(int amount) {
    gold.value += amount;
  }

  void spendGold(int amount) {
    if (gold.value >= amount) {
      gold.value -= amount;
    }
  }

  // ───────────────────────────────────────────
  //  HP helpers
  // ───────────────────────────────────────────
  void heal(double amount) {
    playerCurrentHp.value =
        math.min(playerMaxHp.value, playerCurrentHp.value + amount);
  }

  void fullHeal() {
    playerCurrentHp.value = playerMaxHp.value;
  }

  // ───────────────────────────────────────────
  //  Life management
  // ───────────────────────────────────────────
  void loseLife() {
    lives.value -= 1;
    if (lives.value > 0) {
      // Partial heal on retry (defeat compensation)
      playerCurrentHp.value = playerMaxHp.value * 0.6;
    }
  }

  // ───────────────────────────────────────────
  //  Stage progression (infinite)
  // ───────────────────────────────────────────
  void nextStage() {
    _clampRunScalingStats();

    currentStage.value += 1;
    totalStageNumber.value += 1;

    // Advance cycle tracking
    if (stageInCycle.value >= TOTAL_STAGES_IN_CYCLE) {
      // Boss was just cleared — advance to next cycle
      currentCycle.value += 1;
      stageInCycle.value = 1;
      runBossesDefeated.value += 1;
    } else {
      stageInCycle.value += 1;
    }

    // Heal to full when advancing
    fullHeal();
    playerShield.value = playerMaxShield.value;
    playerBarrierHp.value = playerBarrierMaxHp.value;
  }

  // Game is never "final" — infinite progression
  bool get isFinalStage => false;

  // ───────────────────────────────────────────
  //  Upgrade Card Generation
  // ───────────────────────────────────────────
  List<UpgradeCard> generateUpgradeChoices() {
    final allTypes = [
      'attack_up',
      'bullet_burst',
      'bullet_reflect',
      'body_big',
      'body_small',
      'defense_up',
      'barrier',
      'character_core',
      'battle_trance',
      'vampiric_edge',
      'second_wind',
    ];
    if (activeEquipment.containsKey('hand')) {
      allTypes.add('hand_tune');
    }
    if (activeEquipment.containsKey('boots')) {
      allTypes.add('boots_tune');
    }
    if (activeEquipment.containsKey('armor')) {
      allTypes.add('armor_tune');
    }
    if (playerWeaponCount.value < PLAYER_MAX_WEAPON_COUNT) {
      allTypes.add('weapon_count');
    }
    allTypes.shuffle(_rand);
    final selected = allTypes.sublist(0, 3);

    return selected.map((type) {
      final rarity = _rollUpgradeRarity();
      final multiplier = _rarityMultiplier(rarity);
      switch (type) {
        case 'attack_up':
          return _buildUpgradeCard(
            type: type,
            title: '공격력 증가',
            description:
                '충돌 피해와 총알 피해가 함께 강해집니다.\nATK +${_fmt(UPGRADE_ATTACK_GAIN * multiplier)}',
            statPreview: 'ATK +${_fmt(UPGRADE_ATTACK_GAIN * multiplier)}',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'weapon_count':
          return _buildUpgradeCard(
            type: 'weapon_count',
            title: '주무기 증폭',
            description:
                '새 무기를 해금하지 않고 현재 무기의 발사 축을 늘립니다.\n최대 $PLAYER_MAX_WEAPON_COUNT개까지 중첩됩니다.',
            statPreview: 'WPN +1',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'bullet_burst':
          return _buildUpgradeCard(
            type: 'bullet_burst',
            title: '2연발',
            description: '각 총구가 한 번에 총알을 1발 더 발사합니다.\n총알 계열 무기에 특히 강력합니다.',
            statPreview: 'SHOT +1',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'bullet_reflect':
          return _buildUpgradeCard(
            type: 'bullet_reflect',
            title: '무기 반사',
            description: '총알이 벽에 닿았을 때 1회 더 튕깁니다.\n중첩 가능합니다.',
            statPreview: 'REF +1',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'body_big':
          return _buildUpgradeCard(
            type: 'body_big',
            title: '플레이어 몸집 크게',
            description: '몸집과 체력이 증가합니다.\n충돌이 잦아지는 탱커형 증강입니다.',
            statPreview: 'SIZE/HP',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'body_small':
          return _buildUpgradeCard(
            type: 'body_small',
            title: '플레이어 몸집 작게',
            description: '몸집이 작아지고 속도가 증가합니다.\n빠르게 튕기는 회피형 증강입니다.',
            statPreview: 'SIZE-/SPD',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'defense_up':
          return _buildUpgradeCard(
            type: type,
            title: '방어력 증가',
            description: '충돌 시 받는 피해를 줄입니다.\n최소 피해는 1 이상 유지됩니다.',
            statPreview: 'DEF +${_fmt(UPGRADE_DEFENSE_GAIN * multiplier)}',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'barrier':
          return _buildUpgradeCard(
            type: type,
            title: '베리어',
            description: '공보다 큰 보호막을 생성합니다.\n직접 충돌 시 먼저 깨지며 반격 피해를 줍니다.',
            statPreview: 'BAR +${_fmt(UPGRADE_BARRIER_HP_GAIN * multiplier)}',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'character_core':
          final draft = _characterCoreDraft();
          return _buildUpgradeCard(
            type: draft.type,
            title: draft.title,
            description: draft.description,
            statPreview: draft.statPreview,
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'battle_trance':
          return _buildUpgradeCard(
            type: type,
            title: '전투 고양',
            description: '공격 속도 감각과 치명타 확률이 함께 오릅니다.\n빠른 무기일수록 체감이 큽니다.',
            statPreview: 'SPD/CRIT',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'vampiric_edge':
          return _buildUpgradeCard(
            type: type,
            title: '흡혈 본능',
            description: '입힌 피해 일부로 체력을 회복합니다.\n공격적인 생존 빌드에 어울립니다.',
            statPreview: 'LIFE/ATK',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'second_wind':
          return _buildUpgradeCard(
            type: type,
            title: '재정비',
            description: '최대 체력과 초당 회복을 얻습니다.\n장기전에 강해지는 증강입니다.',
            statPreview: 'HP/REG',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'hand_tune':
          return _buildUpgradeCard(
            type: type,
            title: '${activeEquipment['hand']?.title ?? '손 장비'} 개조',
            description: '손/장신구 슬롯을 발전시킵니다.\n투사체 수, 반사, 공격 보조가 강화됩니다.',
            statPreview: 'HAND+',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'boots_tune':
          return _buildUpgradeCard(
            type: type,
            title: '${activeEquipment['boots']?.title ?? '신발'} 개조',
            description: '신발/발 슬롯을 발전시킵니다.\n이동 속도가 올라 일부 무기 쿨타임도 짧아집니다.',
            statPreview: 'SPD/CD',
            rarity: rarity,
            multiplier: multiplier,
          );
        case 'armor_tune':
          return _buildUpgradeCard(
            type: type,
            title: '${activeEquipment['armor']?.title ?? '갑옷'} 개조',
            description: '갑옷/옷 슬롯을 발전시킵니다.\n체력, 방어, 피격 전 보호막이 강화됩니다.',
            statPreview: 'HP/DEF',
            rarity: rarity,
            multiplier: multiplier,
          );
        default:
          return UpgradeCard(
            type: type,
            rarity: 'common',
            title: 'UNKNOWN',
            description: '',
            statPreview: '',
            multiplier: 1.0,
          );
      }
    }).toList();
  }

  // ───────────────────────────────────────────
  //  Apply Upgrade
  // ───────────────────────────────────────────
  void applyUpgrade(UpgradeCard card) {
    final m = card.multiplier;
    switch (card.type) {
      case 'attack_up':
        playerAtk.value += UPGRADE_ATTACK_GAIN * m;
        break;
      case 'weapon_count':
        playerWeaponCount.value = math.min(
          PLAYER_MAX_WEAPON_COUNT,
          playerWeaponCount.value + UPGRADE_WEAPON_COUNT_GAIN,
        );
        playerWeaponLevel.value = playerWeaponCount.value - 1;
        break;
      case 'bullet_burst':
        playerBulletsPerWeapon.value = math.min(
          PLAYER_MAX_BULLETS_PER_WEAPON,
          playerBulletsPerWeapon.value + UPGRADE_BULLET_BURST_GAIN,
        );
        break;
      case 'bullet_reflect':
        playerBulletReflectCount.value += UPGRADE_BULLET_REFLECT_GAIN;
        break;
      case 'body_big':
        playerRadius.value = math.min(
          PLAYER_MAX_RADIUS,
          playerRadius.value + UPGRADE_BIG_RADIUS_GAIN * m,
        );
        playerMaxHp.value += UPGRADE_BIG_HP_GAIN * m;
        heal(UPGRADE_BIG_HP_GAIN * m);
        playerSpd.value =
            math.max(2.4, playerSpd.value - UPGRADE_BIG_SPEED_PENALTY / m);
        break;
      case 'body_small':
        playerRadius.value = math.max(
          PLAYER_MIN_RADIUS,
          playerRadius.value - UPGRADE_SMALL_RADIUS_LOSS * m,
        );
        playerSpd.value =
            math.min(MAX_SPEED, playerSpd.value + UPGRADE_SMALL_SPEED_GAIN * m);
        break;
      case 'defense_up':
        playerDef.value += UPGRADE_DEFENSE_GAIN * m;
        break;
      case 'barrier':
        playerBarrierMaxHp.value += UPGRADE_BARRIER_HP_GAIN * m;
        playerBarrierHp.value = playerBarrierMaxHp.value;
        break;
      case 'character_core':
        _applyCharacterCore(m);
        break;
      case 'battle_trance':
        playerSpd.value = math.min(MAX_SPEED, playerSpd.value + 0.28 * m);
        playerCritChance.value =
            math.min(0.75, playerCritChance.value + 0.06 * m);
        break;
      case 'vampiric_edge':
        playerAtk.value += 1.4 * m;
        playerLifesteal.value =
            math.min(0.35, playerLifesteal.value + 0.04 * m);
        break;
      case 'second_wind':
        playerMaxHp.value += 24 * m;
        heal(24 * m);
        playerRegen.value += 0.32 * m;
        break;
      case 'hand_tune':
        playerAtk.value += 1.2 * m;
        if (m >= 1.75 && playerCritChance.value < 0.75) {
          playerCritChance.value =
              math.min(0.75, playerCritChance.value + 0.05);
        }
        if (playerBulletsPerWeapon.value < PLAYER_MAX_BULLETS_PER_WEAPON) {
          playerBulletsPerWeapon.value += 1;
        } else if (playerWeaponCount.value < PLAYER_MAX_WEAPON_COUNT) {
          playerWeaponCount.value += 1;
        } else {
          playerBulletReflectCount.value += 1;
        }
        break;
      case 'boots_tune':
        playerSpd.value = math.min(MAX_SPEED, playerSpd.value + 0.34 * m);
        playerRadius.value = math.max(
          PLAYER_MIN_RADIUS,
          playerRadius.value - 1.5 * m,
        );
        break;
      case 'armor_tune':
        playerMaxHp.value += 26 * m;
        heal(26 * m);
        playerDef.value += 0.7 * m;
        playerBarrierMaxHp.value += 24 * m;
        playerBarrierHp.value = playerBarrierMaxHp.value;
        break;
    }
    _clampRunScalingStats();
    appliedUpgrades.add(card.type);
  }

  UpgradeCard _buildUpgradeCard({
    required String type,
    required String title,
    required String description,
    required String statPreview,
    required String rarity,
    required double multiplier,
  }) {
    return UpgradeCard(
      type: type,
      rarity: rarity,
      title: title,
      description: _rarityPrefix(rarity) + description,
      statPreview: statPreview,
      multiplier: multiplier,
    );
  }

  String _rollUpgradeRarity() {
    final roll = _rand.nextDouble();
    if (roll < 0.14) return 'epic';
    if (roll < 0.42) return 'rare';
    return 'common';
  }

  double _rarityMultiplier(String rarity) {
    switch (rarity) {
      case 'epic':
        return 2.0;
      case 'rare':
        return 1.45;
      case 'common':
      default:
        return 1.0;
    }
  }

  String _rarityPrefix(String rarity) {
    switch (rarity) {
      case 'epic':
        return '[EPIC] ';
      case 'rare':
        return '[RARE] ';
      case 'common':
      default:
        return '[COMMON] ';
    }
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  _UpgradeDraft _characterCoreDraft() {
    final charDef = kAllCharacters.firstWhere(
      (c) => c.id == characterType.value,
      orElse: () => kAllCharacters.first,
    );
    switch (charDef.shape) {
      case 'square':
        return _UpgradeDraft(
          type: 'character_core',
          title: '${charDef.title} 각성',
          description: '최대 체력, 방어, 베리어 증가',
          statPreview: 'HP/DEF/BAR',
        );
      case 'triangle':
        return _UpgradeDraft(
          type: 'character_core',
          title: '${charDef.title} 각성',
          description: '공격력, 속도, 치명타 증가',
          statPreview: 'ATK/SPD/CRIT',
        );
      case 'pentagon':
        return _UpgradeDraft(
          type: 'character_core',
          title: '${charDef.title} 각성',
          description: '공격 보조, 회복, 반사 증가',
          statPreview: 'POW/REG/REF',
        );
      case 'circle':
      default:
        return _UpgradeDraft(
          type: 'character_core',
          title: '${charDef.title} 각성',
          description: '체력, 공격력, 속도 증가',
          statPreview: 'HP/ATK/SPD',
        );
    }
  }

  void _applyCharacterCore(double multiplier) {
    final charDef = kAllCharacters.firstWhere(
      (c) => c.id == characterType.value,
      orElse: () => kAllCharacters.first,
    );
    switch (charDef.shape) {
      case 'square':
        playerMaxHp.value += 32 * multiplier;
        heal(32 * multiplier);
        playerDef.value += 0.9 * multiplier;
        playerBarrierMaxHp.value += 20 * multiplier;
        playerBarrierHp.value = playerBarrierMaxHp.value;
        break;
      case 'triangle':
        playerAtk.value += 2.1 * multiplier;
        playerSpd.value =
            math.min(MAX_SPEED, playerSpd.value + 0.22 * multiplier);
        playerCritChance.value =
            math.min(0.75, playerCritChance.value + 0.045 * multiplier);
        break;
      case 'pentagon':
        playerAbilityPower.value += 0.18 * multiplier;
        playerRegen.value += 0.22 * multiplier;
        playerBulletReflectCount.value += 1;
        break;
      case 'circle':
      default:
        playerMaxHp.value += 20 * multiplier;
        heal(20 * multiplier);
        playerAtk.value += 1.6 * multiplier;
        playerSpd.value =
            math.min(MAX_SPEED, playerSpd.value + 0.14 * multiplier);
        break;
    }
  }

  Map<String, EquipmentShopDef> _resolvedEquipment(
    Map<String, String> equippedEquipment,
  ) {
    final resolved = <String, EquipmentShopDef>{};
    for (final entry in equippedEquipment.entries) {
      for (final equipment in kAllEquipment) {
        if (equipment.id == entry.value && equipment.slot == entry.key) {
          resolved[entry.key] = equipment;
          break;
        }
      }
    }
    return resolved;
  }

  void _clampRunScalingStats() {
    playerWeaponCount.value = math.min(
      PLAYER_MAX_WEAPON_COUNT,
      math.max(
        PLAYER_STARTING_WEAPON_COUNT,
        playerWeaponCount.value,
      ),
    );
    playerWeaponLevel.value = math.max(0, playerWeaponCount.value - 1);
    playerBulletsPerWeapon.value = math.min(
      PLAYER_MAX_BULLETS_PER_WEAPON,
      math.max(
        PLAYER_STARTING_BULLETS_PER_WEAPON,
        playerBulletsPerWeapon.value,
      ),
    );
  }

  // ───────────────────────────────────────────
  //  Shop Logic
  // ───────────────────────────────────────────
  void generateShopItems() {
    final unlocked = runUnlockedWeapons.toSet();
    final allWeapons = kAllEquipment
        .where((e) => e.slot == 'weapon' && unlocked.contains(e.weaponType))
        .map(_shopItemFromMetaWeapon)
        .toList();

    // During a run, only permanently unlocked weapons can appear.
    final available = allWeapons
        .where((w) =>
            w.weaponType != characterType.value &&
            !ownedWeapons.contains(w.weaponType))
        .toList();
    available.shuffle(_rand);
    shopItems.value = available.take(2).toList();
  }

  bool buyWeapon(ShopItem item) {
    if (item.weaponType == characterType.value) return false;
    if (!runUnlockedWeapons.contains(item.weaponType)) return false;
    if (gold.value >= item.price && !ownedWeapons.contains(item.weaponType)) {
      gold.value -= item.price;
      ownedWeapons.add(item.weaponType);
      return true;
    }
    return false;
  }

  List<String> _orderedRunWeapons(Set<String> unlockedSet) {
    final ordered = <String>['gunner'];
    final allWeaponDefs = kAllEquipment.where((e) => e.slot == 'weapon');

    for (final def in allWeaponDefs) {
      final wType = def.weaponType;
      if (wType != null && unlockedSet.contains(wType)) {
        if (!ordered.contains(wType)) {
          ordered.add(wType);
        }
      }
    }
    for (final wType in unlockedSet) {
      if (!ordered.contains(wType)) {
        ordered.add(wType);
      }
    }
    return ordered;
  }

  ShopItem _shopItemFromMetaWeapon(EquipmentShopDef weapon) {
    return ShopItem(
      id: weapon.id,
      title: weapon.title,
      description: weapon.description,
      price: _runWeaponPrice(weapon),
      weaponType: weapon.weaponType ?? 'gunner',
      icon: weapon.icon,
    );
  }

  int _runWeaponPrice(EquipmentShopDef weapon) {
    const overrides = {
      'minigun': 150,
      'long_gun': 200,
      'poison': 180,
      'blade': 220,
      'miner': 170,
      'footsteps': 190,
      'burst': 250,
      'heavy_blade': 280,
      'ricochet': 210,
      'aura': 300,
    };
    return overrides[weapon.weaponType ?? ''] ?? weapon.price;
  }
}
