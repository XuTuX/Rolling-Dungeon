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

class GameProgressController extends GetxController {
  // ── Run State ──
  var currentStage = 1.obs;
  var maxStage = 10;
  var lives = 3.obs;
  var gold = 0.obs;

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
  var characterType = 'none'.obs; // 'gunner', 'blade', 'miner', 'poison'

  // ── Upgrade history for display ──
  final appliedUpgrades = <String>[].obs;

  // ── Random for card generation ──
  final math.Random _rand = math.Random();

  // ───────────────────────────────────────────
  //  New Run
  // ───────────────────────────────────────────
  void startNewRun(String selectedCharacter) {
    currentStage.value = 1;
    lives.value = 3;
    gold.value = 0;
    appliedUpgrades.clear();

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
  //  Stage progression
  // ───────────────────────────────────────────
  void nextStage() {
    if (currentStage.value < maxStage) {
      currentStage.value += 1;
      // Heal to full when advancing to next stage
      fullHeal();
      playerShield.value = playerMaxShield.value;
      playerBarrierHp.value = playerBarrierMaxHp.value;
    }
  }

  bool get isFinalStage => currentStage.value >= maxStage;

  // ───────────────────────────────────────────
  //  Upgrade Card Generation
  // ───────────────────────────────────────────
  List<UpgradeCard> generateUpgradeChoices() {
    final allTypes = [
      'attack_up',
      'weapon_count',
      'bullet_burst',
      'bullet_reflect',
      'body_big',
      'body_small',
      'defense_up',
      'barrier',
    ];
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
            description: '공 주변 무기를 1개 늘립니다.\n각 무기가 독립적으로 발사합니다.',
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
        playerWeaponCount.value += UPGRADE_WEAPON_COUNT_GAIN;
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
    appliedUpgrades.add(card.type);
  }
}
