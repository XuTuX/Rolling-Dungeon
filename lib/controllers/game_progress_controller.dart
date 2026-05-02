import 'dart:math' as math;
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
  var playerBarrierHp = 0.0.obs;
  var playerBarrierMaxHp = 0.0.obs;

  // ── Character Type ──
  // ── Character Type & Weapons ──
  var characterType = 'none'.obs; // 'gunner', 'blade', 'miner', 'poison'
  final ownedWeapons = <String>[].obs;
  final shopItems = <ShopItem>[].obs;

  // ── Upgrade history for display ──
  final appliedUpgrades = <String>[].obs;

  // ── Random for card generation ──
  final math.Random _rand = math.Random();

  // ───────────────────────────────────────────
  //  New Run
  // ───────────────────────────────────────────
  void startNewRun(String selectedCharacter) {
    currentStage.value = 1;
    currentCycle.value = 1;
    stageInCycle.value = 1;
    totalStageNumber.value = 1;
    lives.value = 3;
    gold.value = 0;
    appliedUpgrades.clear();
    ownedWeapons.clear();
    shopItems.clear();

    // Run stats reset
    runEnemiesKilled.value = 0;
    runBossesDefeated.value = 0;
    runDamageDealt.value = 0;

    characterType.value =
        selectedCharacter == 'none' ? 'gunner' : selectedCharacter;

    playerMaxHp.value = PLAYER_BASE_HP;
    playerAtk.value = PLAYER_BASE_ATTACK;
    playerDef.value = PLAYER_BASE_DEFENSE;
    playerSpd.value = PLAYER_BASE_SPEED;
    playerRadius.value = PLAYER_BASE_RADIUS;

    playerCurrentHp.value = playerMaxHp.value;
    playerAbilityPower.value = 1.0;
    playerShield.value = 0;
    playerMaxShield.value = 0;
    playerWeaponLevel.value = 0;
    playerWeaponCount.value = PLAYER_STARTING_WEAPON_COUNT;
    playerBulletReflectCount.value = PLAYER_STARTING_BULLET_REFLECTS;
    playerBulletsPerWeapon.value = PLAYER_STARTING_BULLETS_PER_WEAPON;
    playerRegen.value = 0;
    playerLifesteal.value = 0;
    playerBarrierHp.value = 0;
    playerBarrierMaxHp.value = 0;
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
    ];
    if (playerWeaponCount.value < PLAYER_MAX_WEAPON_COUNT) {
      allTypes.add('weapon_count');
    }
    allTypes.shuffle(_rand);
    final selected = allTypes.sublist(0, 3);

    return selected.map((type) {
      switch (type) {
        case 'attack_up':
          return UpgradeCard(
            type: type,
            rarity: 'common',
            title: '공격력 증가',
            description:
                '충돌 피해와 총알 피해가 함께 강해집니다.\nATK +${UPGRADE_ATTACK_GAIN.toStringAsFixed(0)}',
            statPreview: 'ATK +${UPGRADE_ATTACK_GAIN.toStringAsFixed(0)}',
            multiplier: 1,
          );
        case 'weapon_count':
          return const UpgradeCard(
            type: 'weapon_count',
            rarity: 'common',
            title: '무기 수 증가',
            description:
                '공 주변 무기를 1개 늘립니다.\n최대 $PLAYER_MAX_WEAPON_COUNT개까지 중첩됩니다.',
            statPreview: 'WPN +1',
            multiplier: 1,
          );
        case 'bullet_burst':
          return const UpgradeCard(
            type: 'bullet_burst',
            rarity: 'common',
            title: '2연발',
            description: '각 총구가 한 번에 총알을 1발 더 발사합니다.\n총알 계열 무기에 특히 강력합니다.',
            statPreview: 'SHOT +1',
            multiplier: 1,
          );
        case 'bullet_reflect':
          return const UpgradeCard(
            type: 'bullet_reflect',
            rarity: 'common',
            title: '무기 반사',
            description: '총알이 벽에 닿았을 때 1회 더 튕깁니다.\n중첩 가능합니다.',
            statPreview: 'REF +1',
            multiplier: 1,
          );
        case 'body_big':
          return const UpgradeCard(
            type: 'body_big',
            rarity: 'common',
            title: '플레이어 몸집 크게',
            description: '몸집과 체력이 증가합니다.\n충돌이 잦아지는 탱커형 증강입니다.',
            statPreview: 'SIZE/HP',
            multiplier: 1,
          );
        case 'body_small':
          return const UpgradeCard(
            type: 'body_small',
            rarity: 'common',
            title: '플레이어 몸집 작게',
            description: '몸집이 작아지고 속도가 증가합니다.\n빠르게 튕기는 회피형 증강입니다.',
            statPreview: 'SIZE-/SPD',
            multiplier: 1,
          );
        case 'defense_up':
          return UpgradeCard(
            type: type,
            rarity: 'common',
            title: '방어력 증가',
            description: '충돌 시 받는 피해를 줄입니다.\n최소 피해는 1 이상 유지됩니다.',
            statPreview: 'DEF +${UPGRADE_DEFENSE_GAIN.toStringAsFixed(1)}',
            multiplier: 1,
          );
        case 'barrier':
          return UpgradeCard(
            type: type,
            rarity: 'common',
            title: '베리어',
            description: '공보다 큰 보호막을 생성합니다.\n직접 충돌 시 먼저 깨지며 반격 피해를 줍니다.',
            statPreview: 'BAR +${UPGRADE_BARRIER_HP_GAIN.toStringAsFixed(0)}',
            multiplier: 1,
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
    switch (card.type) {
      case 'attack_up':
        playerAtk.value += UPGRADE_ATTACK_GAIN;
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
          playerRadius.value + UPGRADE_BIG_RADIUS_GAIN,
        );
        playerMaxHp.value += UPGRADE_BIG_HP_GAIN;
        heal(UPGRADE_BIG_HP_GAIN);
        playerSpd.value =
            math.max(2.4, playerSpd.value - UPGRADE_BIG_SPEED_PENALTY);
        break;
      case 'body_small':
        playerRadius.value = math.max(
          PLAYER_MIN_RADIUS,
          playerRadius.value - UPGRADE_SMALL_RADIUS_LOSS,
        );
        playerSpd.value =
            math.min(MAX_SPEED, playerSpd.value + UPGRADE_SMALL_SPEED_GAIN);
        break;
      case 'defense_up':
        playerDef.value += UPGRADE_DEFENSE_GAIN;
        break;
      case 'barrier':
        playerBarrierMaxHp.value += UPGRADE_BARRIER_HP_GAIN;
        playerBarrierHp.value = playerBarrierMaxHp.value;
        break;
    }
    _clampRunScalingStats();
    appliedUpgrades.add(card.type);
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
    final allWeapons = [
      const ShopItem(
          id: 'minigun',
          title: '미니건',
          description: '빠른 연사 속도로 적을 압도합니다.',
          price: 150,
          weaponType: 'minigun',
          icon: '🔫'),
      const ShopItem(
          id: 'long_gun',
          title: '장거리 포',
          description: '느리지만 강력한 대구경 탄환을 발사합니다.',
          price: 200,
          weaponType: 'long_gun',
          icon: '🚀'),
      const ShopItem(
          id: 'poison_gun',
          title: '독 가스 분무기',
          description: '지나가는 자리에 치명적인 독구름을 남깁니다.',
          price: 180,
          weaponType: 'poison',
          icon: '☣️'),
      const ShopItem(
          id: 'blade_master',
          title: '회전 칼날',
          description: '공 주변을 회전하며 근접한 적을 베어버립니다.',
          price: 220,
          weaponType: 'blade',
          icon: '⚔️'),
      const ShopItem(
          id: 'mine_layer',
          title: '지뢰 매설기',
          description: '뒤쪽으로 강력한 폭발 지뢰를 투척합니다.',
          price: 170,
          weaponType: 'miner',
          icon: '💣'),
      const ShopItem(
          id: 'footsteps',
          title: '불타는 발자국',
          description: '지나간 자리에 불꽃 자취를 남겨 지속 피해를 줍니다.',
          price: 190,
          weaponType: 'footsteps',
          icon: '👣'),
      const ShopItem(
          id: 'burst_gun',
          title: '전방위 버스트',
          description: '사방으로 퍼지는 탄환을 발사합니다.',
          price: 250,
          weaponType: 'burst',
          icon: '💢'),
      const ShopItem(
          id: 'heavy_blade',
          title: '거대 대검',
          description: '매우 크고 강력한 칼날이 천천히 회전합니다.',
          price: 280,
          weaponType: 'heavy_blade',
          icon: '🗡️'),
      const ShopItem(
          id: 'ricochet',
          title: '도탄 사격',
          description: '벽에 여러 번 튕기는 특수 탄환을 사용합니다.',
          price: 210,
          weaponType: 'ricochet',
          icon: '✨'),
      const ShopItem(
          id: 'aura',
          title: '수호자의 오라',
          description: '주변의 적에게 지속적인 피해를 주는 영역을 생성합니다.',
          price: 300,
          weaponType: 'aura',
          icon: '🌀'),
    ];

    // Filter out already owned weapons
    final available =
        allWeapons.where((w) => !ownedWeapons.contains(w.weaponType)).toList();
    available.shuffle(_rand);
    shopItems.value = available.take(2).toList();
  }

  bool buyWeapon(ShopItem item) {
    if (gold.value >= item.price && !ownedWeapons.contains(item.weaponType)) {
      gold.value -= item.price;
      ownedWeapons.add(item.weaponType);
      return true;
    }
    return false;
  }
}
