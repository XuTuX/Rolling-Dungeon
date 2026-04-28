import 'dart:math' as math;
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
  var playerMaxHp = 200.0.obs;
  var playerCurrentHp = 200.0.obs;
  var playerAtk = 5.0.obs;
  var playerDef = 2.0.obs;
  var playerSpd = 2.8.obs;      // matches BASE_SPEED in constants
  var playerAbilityPower = 1.0.obs;

  // ── Character Type ──
  var characterType = 'none'.obs; // 'gunner', 'blade', 'miner', 'laser'

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

    characterType.value = selectedCharacter;

    // Base stats per character class (tuned to engine constant scale)
    switch (selectedCharacter) {
      case 'gunner':
        playerMaxHp.value = 180;
        playerAtk.value = 4;
        playerDef.value = 1.5;
        playerSpd.value = 3.0;
        break;
      case 'blade':
        playerMaxHp.value = 220;
        playerAtk.value = 6;
        playerDef.value = 2.5;
        playerSpd.value = 2.6;
        break;
      case 'miner':
        playerMaxHp.value = 160;
        playerAtk.value = 5;
        playerDef.value = 1.5;
        playerSpd.value = 3.4;
        break;
      case 'laser':
        playerMaxHp.value = 200;
        playerAtk.value = 5;
        playerDef.value = 2.0;
        playerSpd.value = 2.8;
        break;
      default:
        playerMaxHp.value = 200;
        playerAtk.value = 5;
        playerDef.value = 2.0;
        playerSpd.value = 2.8;
    }

    playerCurrentHp.value = playerMaxHp.value;
    playerAbilityPower.value = 1.0;
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
    }
  }

  bool get isFinalStage => currentStage.value >= maxStage;

  // ───────────────────────────────────────────
  //  Upgrade Card Generation
  // ───────────────────────────────────────────
  List<UpgradeCard> generateUpgradeChoices() {
    final allTypes = ['assault', 'guard', 'haste', 'vitality', 'mastery'];
    allTypes.shuffle(_rand);
    final selected = allTypes.sublist(0, 3);

    return selected.map((type) {
      final roll = _rand.nextDouble();
      final rarity = roll < 0.10 ? 'epic' : roll < 0.35 ? 'rare' : 'common';
      final mult = rarity == 'epic' ? 2.5 : rarity == 'rare' ? 1.6 : 1.0;

      switch (type) {
        case 'assault':
          final gain = (3.5 * mult).round();
          return UpgradeCard(
            type: type,
            rarity: rarity,
            title: rarity == 'epic'
                ? '광폭화 공격'
                : rarity == 'rare'
                    ? '강력한 공격'
                    : '공격 강화',
            description: '공격력을 대폭 올립니다.\nATK +$gain',
            statPreview: 'ATK +$gain',
            multiplier: mult,
          );
        case 'guard':
          final defGain = (1.1 * mult).toStringAsFixed(1);
          final hpGain = (4.0 * mult).round();
          return UpgradeCard(
            type: type,
            rarity: rarity,
            title: rarity == 'epic'
                ? '철벽 방어'
                : rarity == 'rare'
                    ? '단단한 가드'
                    : '방어 강화',
            description: '방어력과 체력을 높입니다.\nDEF +$defGain / HP +$hpGain',
            statPreview: 'DEF +$defGain',
            multiplier: mult,
          );
        case 'haste':
          final spdGain = (0.12 * mult).toStringAsFixed(2);
          return UpgradeCard(
            type: type,
            rarity: rarity,
            title: rarity == 'epic'
                ? '광속 이동'
                : rarity == 'rare'
                    ? '빠른 몸놀림'
                    : '속도 강화',
            description: '이동 속도가 빨라지고\n스킬 쿨타임이 줄어듭니다.',
            statPreview: 'SPD +$spdGain',
            multiplier: mult,
          );
        case 'vitality':
          final hpGain = (20.0 * mult).round();
          final healAmt = (40.0 * mult).round();
          return UpgradeCard(
            type: type,
            rarity: rarity,
            title: rarity == 'epic'
                ? '무한한 생명'
                : rarity == 'rare'
                    ? '강인한 생명력'
                    : '생존 본능',
            description: '최대 체력 +$hpGain\n즉시 $healAmt HP 회복.',
            statPreview: 'HP +$hpGain',
            multiplier: mult,
          );
        case 'mastery':
          final pwrGain = (1.0 * mult).toStringAsFixed(1);
          final weaponName = _weaponKorean(characterType.value);
          return UpgradeCard(
            type: type,
            rarity: rarity,
            title: rarity == 'epic'
                ? '$weaponName 극의'
                : rarity == 'rare'
                    ? '$weaponName 숙련'
                    : '$weaponName 강화',
            description: '$weaponName 위력을 높입니다.\nPWR +$pwrGain',
            statPreview: 'PWR +$pwrGain',
            multiplier: mult,
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

  String _weaponKorean(String type) {
    switch (type) {
      case 'gunner':
        return '탄도';
      case 'blade':
        return '검술';
      case 'miner':
        return '설계';
      case 'laser':
        return '광학';
      default:
        return '숙련';
    }
  }

  // ───────────────────────────────────────────
  //  Apply Upgrade
  // ───────────────────────────────────────────
  void applyUpgrade(UpgradeCard card) {
    final m = card.multiplier;
    switch (card.type) {
      case 'assault':
        playerAtk.value += 3.5 * m;
        break;
      case 'guard':
        playerDef.value += 1.1 * m;
        playerMaxHp.value += 4.0 * m;
        heal(14);
        break;
      case 'haste':
        playerSpd.value =
            math.min(10.0, playerSpd.value + 0.12 * m);
        break;
      case 'vitality':
        playerMaxHp.value += 20.0 * m;
        heal(40.0 * m);
        break;
      case 'mastery':
        playerAtk.value += 1.2 * m;
        playerAbilityPower.value += 1.0 * m;
        break;
    }
    appliedUpgrades.add(card.type);
  }
}
