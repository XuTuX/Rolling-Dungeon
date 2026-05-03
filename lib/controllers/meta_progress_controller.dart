import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:circle_war/game/auto_battle/engine/constants.dart';
import 'package:circle_war/game/auto_battle/models/meta_data.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:circle_war/services/persistence_service.dart';

const double kMetaHpGainPerLevel = 14.0;
const double kMetaAtkGainPerLevel = 1.0;
const double kMetaSpeedGainPerLevel = 0.05;
const double kMetaRegenGainPerLevel = 0.25;
const double kMetaCritGainPerLevel = 0.015;

class CharacterShopDef {
  final String id;
  final String title;
  final String description;
  final int price;
  final String icon;
  final double hpBonus;
  final double atkBonus;
  final double speedBonus;
  final double defBonus;
  final double critBonus;
  final String shape; // 'circle', 'square', 'triangle'
  final String trait;

  const CharacterShopDef({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.shape,
    this.hpBonus = 0,
    this.atkBonus = 0,
    this.speedBonus = 0,
    this.defBonus = 0,
    this.critBonus = 0,
    this.trait = '',
  });

  String get shopSummary => ShopStatPresenter.characterSummary(this);
}

const List<CharacterShopDef> kAllCharacters = [
  CharacterShopDef(
    id: 'circle',
    title: '동그라미',
    description: '',
    price: 0,
    icon: '🔴',
    shape: 'circle',
    hpBonus: 0,
    atkBonus: 0,
    speedBonus: 0,
    trait: '',
  ),
  CharacterShopDef(
    id: 'square',
    title: '네모',
    description: '',
    price: 300,
    icon: '🟦',
    shape: 'square',
    hpBonus: 40,
    defBonus: 2.0,
    speedBonus: -0.2,
    trait: '',
  ),
  CharacterShopDef(
    id: 'triangle',
    title: '세모',
    description: '',
    price: 450,
    icon: '▲',
    shape: 'triangle',
    hpBonus: -20,
    atkBonus: 5.0,
    speedBonus: 0.35,
    critBonus: 0.10,
    trait: '',
  ),
  CharacterShopDef(
    id: 'pentagon',
    title: '오각형',
    description: '',
    price: 800,
    icon: '⬔',
    shape: 'pentagon',
    hpBonus: 10,
    atkBonus: 2.0,
    defBonus: 1.0,
    speedBonus: 0.15,
    critBonus: 0.05,
    trait: '',
  ),
];

class EquipmentShopDef {
  final String id;
  final String slot; // weapon, hand, armor, boots
  final String title;
  final String description;
  final int price;
  final String icon;
  final String? weaponType; // Only for weapon slot
  final double hpBonus;
  final double atkBonus;
  final double defBonus;
  final double speedBonus;
  final double critBonus;
  final int weaponCountBonus;
  final int bulletsPerWeaponBonus;
  final int bulletReflectBonus;
  final double barrierBonus;

  const EquipmentShopDef({
    required this.id,
    required this.slot,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    this.weaponType,
    this.hpBonus = 0,
    this.atkBonus = 0,
    this.defBonus = 0,
    this.speedBonus = 0,
    this.critBonus = 0,
    this.weaponCountBonus = 0,
    this.bulletsPerWeaponBonus = 0,
    this.bulletReflectBonus = 0,
    this.barrierBonus = 0,
  });

  String get statSummary {
    return ShopStatPresenter.equipmentSummary(this);
  }
}

class ShopStatPresenter {
  const ShopStatPresenter._();

  static String characterSummary(CharacterShopDef character) {
    final power = _powerScore(
      hpBonus: character.hpBonus,
      atkBonus: character.atkBonus,
      defBonus: character.defBonus,
      speedBonus: character.speedBonus,
      critBonus: character.critBonus,
    );
    final metrics = _topMetrics(
      hpBonus: character.hpBonus,
      atkBonus: character.atkBonus,
      defBonus: character.defBonus,
      speedBonus: character.speedBonus,
      critBonus: character.critBonus,
    );
    return _summary(power, metrics);
  }

  static String equipmentSummary(EquipmentShopDef equipment) {
    final power = _powerScore(
      hpBonus: equipment.hpBonus,
      atkBonus: equipment.atkBonus,
      defBonus: equipment.defBonus,
      speedBonus: equipment.speedBonus,
      critBonus: equipment.critBonus,
      weaponCountBonus: equipment.weaponCountBonus,
      bulletsPerWeaponBonus: equipment.bulletsPerWeaponBonus,
      bulletReflectBonus: equipment.bulletReflectBonus,
      barrierBonus: equipment.barrierBonus,
    );
    final metrics = _topMetrics(
      hpBonus: equipment.hpBonus,
      atkBonus: equipment.atkBonus,
      defBonus: equipment.defBonus,
      speedBonus: equipment.speedBonus,
      critBonus: equipment.critBonus,
      weaponCountBonus: equipment.weaponCountBonus,
      bulletsPerWeaponBonus: equipment.bulletsPerWeaponBonus,
      bulletReflectBonus: equipment.bulletReflectBonus,
      barrierBonus: equipment.barrierBonus,
    );
    return _summary(power, metrics);
  }

  static String statUpgradeSummary(StatShopDef stat) {
    final power = switch (stat.statType) {
      'hp' => _powerScore(hpBonus: kMetaHpGainPerLevel),
      'atk' => _powerScore(atkBonus: kMetaAtkGainPerLevel),
      'speed' => _powerScore(speedBonus: kMetaSpeedGainPerLevel),
      'regen' => _powerScore(regenBonus: kMetaRegenGainPerLevel),
      'crit' => _powerScore(critBonus: kMetaCritGainPerLevel),
      _ => 100,
    };
    return '전투력 +${math.max(1, power - 100)}';
  }

  static String statUpgradeGain(StatShopDef stat) {
    return switch (stat.statType) {
      'hp' => '체력 +${kMetaHpGainPerLevel.round()}',
      'atk' => '공격 +${kMetaAtkGainPerLevel.toStringAsFixed(0)}',
      'speed' => '속도 +${(kMetaSpeedGainPerLevel * 100).round()}',
      'regen' => '회복 +${kMetaRegenGainPerLevel.toStringAsFixed(2)}',
      'crit' => '치명 +${(kMetaCritGainPerLevel * 100).toStringAsFixed(1)}%',
      _ => '',
    };
  }

  static String _summary(int power, List<String> metrics) {
    final firstLine = '전투력 $power';
    if (metrics.isEmpty) return '$firstLine\n기본형';
    return '$firstLine\n${metrics.take(2).join(' · ')}';
  }

  static int _powerScore({
    double hpBonus = 0,
    double atkBonus = 0,
    double defBonus = 0,
    double speedBonus = 0,
    double critBonus = 0,
    double regenBonus = 0,
    double barrierBonus = 0,
    int weaponCountBonus = 0,
    int bulletsPerWeaponBonus = 0,
    int bulletReflectBonus = 0,
  }) {
    final score = 100 +
        hpBonus / PLAYER_BASE_HP * 45 +
        atkBonus / PLAYER_BASE_ATTACK * 50 +
        defBonus / PLAYER_BASE_DEFENSE * 20 +
        speedBonus / PLAYER_BASE_SPEED * 45 +
        critBonus * 150 +
        regenBonus * 8 +
        barrierBonus / PLAYER_BASE_HP * 35 +
        weaponCountBonus * 20 +
        bulletsPerWeaponBonus * 18 +
        bulletReflectBonus * 8;
    return math.max(60, score.round());
  }

  static List<String> _topMetrics({
    double hpBonus = 0,
    double atkBonus = 0,
    double defBonus = 0,
    double speedBonus = 0,
    double critBonus = 0,
    double barrierBonus = 0,
    int weaponCountBonus = 0,
    int bulletsPerWeaponBonus = 0,
    int bulletReflectBonus = 0,
  }) {
    final metrics = <({String text, double weight})>[];
    if (hpBonus != 0) {
      metrics.add((
        text: _scoreLabel('체력', PLAYER_BASE_HP, hpBonus),
        weight: hpBonus.abs() / PLAYER_BASE_HP
      ));
    }
    if (atkBonus != 0) {
      metrics.add((
        text: _scoreLabel('공격', PLAYER_BASE_ATTACK, atkBonus),
        weight: atkBonus.abs() / PLAYER_BASE_ATTACK
      ));
    }
    if (defBonus != 0) {
      metrics.add((
        text: _scoreLabel('방어', PLAYER_BASE_DEFENSE, defBonus),
        weight: defBonus.abs() / PLAYER_BASE_DEFENSE
      ));
    }
    if (speedBonus != 0) {
      metrics.add((
        text: _scoreLabel('속도', PLAYER_BASE_SPEED, speedBonus),
        weight: speedBonus.abs() / PLAYER_BASE_SPEED
      ));
    }
    if (critBonus != 0) {
      metrics.add(
          (text: '치명 ${(critBonus * 100).round()}%', weight: critBonus * 2));
    }
    if (weaponCountBonus != 0 ||
        bulletsPerWeaponBonus != 0 ||
        bulletReflectBonus != 0) {
      final attackUtility = weaponCountBonus * 12 +
          bulletsPerWeaponBonus * 10 +
          bulletReflectBonus * 5;
      metrics.add((text: '공격 보조 +$attackUtility', weight: attackUtility / 100));
    }
    if (barrierBonus != 0) {
      metrics.add((
        text: '생존 +${(barrierBonus / PLAYER_BASE_HP * 100).round()}',
        weight: barrierBonus / PLAYER_BASE_HP
      ));
    }
    metrics.sort((a, b) => b.weight.compareTo(a.weight));
    return metrics.map((metric) => metric.text).toList();
  }

  static String _scoreLabel(String label, double base, double bonus) {
    final score = ((base + bonus) / base * 100).round();
    return '$label $score';
  }
}

class LoadoutStatProfile {
  final double maxHp;
  final double atk;
  final double def;
  final double speed;
  final double regen;
  final double critChance;
  final double barrierHp;
  final int weaponCount;
  final int bulletsPerWeapon;
  final int bulletReflects;

  const LoadoutStatProfile({
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.speed,
    required this.regen,
    required this.critChance,
    required this.barrierHp,
    required this.weaponCount,
    required this.bulletsPerWeapon,
    required this.bulletReflects,
  });

  int get hpScore => _score(maxHp, PLAYER_BASE_HP);
  int get atkScore => _score(atk, PLAYER_BASE_ATTACK);
  int get defScore => _score(def, PLAYER_BASE_DEFENSE);
  int get speedScore => _score(speed, PLAYER_BASE_SPEED);

  static int _score(double value, double base) {
    return (value / base * 100).round();
  }
}

const Map<String, String> kEquipmentSlotLabels = {
  'weapon': '무기 장착',
  'hand': '장신구/손',
  'armor': '갑옷/옷',
  'boots': '신발/발',
};

const List<EquipmentShopDef> kAllEquipment = [
  // ── Weapons (Exactly 4 characteristic ones) ──
  EquipmentShopDef(
    id: 'wpn_gunner',
    slot: 'weapon',
    title: '기본 거너',
    description: '',
    price: 0,
    icon: '🔫',
    weaponType: 'gunner',
  ),
  EquipmentShopDef(
    id: 'wpn_minigun',
    slot: 'weapon',
    title: '미니건',
    description: '',
    price: 300,
    icon: '🔥',
    weaponType: 'minigun',
    speedBonus: -0.1,
  ),
  EquipmentShopDef(
    id: 'wpn_blade_master',
    slot: 'weapon',
    title: '회전 칼날',
    description: '',
    price: 450,
    icon: '⚔️',
    weaponType: 'blade',
    atkBonus: 2.0,
    critBonus: 0.06,
  ),
  EquipmentShopDef(
    id: 'wpn_aura',
    slot: 'weapon',
    title: '수호자의 오라',
    description: '',
    price: 600,
    icon: '🌀',
    weaponType: 'aura',
    hpBonus: 20,
  ),

  // ── Hand / Accessories (4 items) ──
  EquipmentShopDef(
    id: 'rapid_glove',
    slot: 'hand',
    title: '속사 장갑',
    description: '',
    price: 150,
    icon: '🧤',
    bulletsPerWeaponBonus: 1,
    speedBonus: 0.1,
    critBonus: 0.04,
  ),
  EquipmentShopDef(
    id: 'scope_ring',
    slot: 'hand',
    title: '조준 반지',
    description: '',
    price: 250,
    icon: '💍',
    atkBonus: 3.0,
    bulletReflectBonus: 1,
    critBonus: 0.10,
  ),
  EquipmentShopDef(
    id: 'magic_pendant',
    slot: 'hand',
    title: '마법 펜던트',
    description: '',
    price: 350,
    icon: '📿',
    atkBonus: 1.5,
    barrierBonus: 25,
    critBonus: 0.04,
  ),
  EquipmentShopDef(
    id: 'power_bracelet',
    slot: 'hand',
    title: '힘의 팔찌',
    description: '',
    price: 450,
    icon: '⌚',
    atkBonus: 5.0,
    hpBonus: -15,
    critBonus: 0.14,
  ),

  // ── Armor (4 items) ──
  EquipmentShopDef(
    id: 'plate_armor',
    slot: 'armor',
    title: '판금 갑옷',
    description: '',
    price: 200,
    icon: '🛡️',
    hpBonus: 40,
    defBonus: 1.0,
  ),
  EquipmentShopDef(
    id: 'reactive_coat',
    slot: 'armor',
    title: '반응 코트',
    description: '',
    price: 300,
    icon: '🦺',
    hpBonus: 20,
    barrierBonus: 45,
  ),
  EquipmentShopDef(
    id: 'spiked_armor',
    slot: 'armor',
    title: '가시 갑옷',
    description: '',
    price: 400,
    icon: '🥋',
    atkBonus: 2.5,
    defBonus: 1.5,
  ),
  EquipmentShopDef(
    id: 'wind_tunic',
    slot: 'armor',
    title: '바람의 튜닉',
    description: '',
    price: 500,
    icon: '👕',
    speedBonus: 0.35,
    hpBonus: 25,
  ),

  // ── Boots (4 items) ──
  EquipmentShopDef(
    id: 'spring_boots',
    slot: 'boots',
    title: '스프링 부츠',
    description: '',
    price: 180,
    icon: '👟',
    speedBonus: 0.5,
  ),
  EquipmentShopDef(
    id: 'knockback_boots',
    slot: 'boots',
    title: '반동 부츠',
    description: '',
    price: 280,
    icon: '🥾',
    speedBonus: 0.3,
    atkBonus: 1.5,
    critBonus: 0.03,
  ),
  EquipmentShopDef(
    id: 'heavy_boots',
    slot: 'boots',
    title: '헤비 부츠',
    description: '',
    price: 380,
    icon: '👞',
    hpBonus: 35,
    defBonus: 2.0,
    speedBonus: -0.15,
  ),
  EquipmentShopDef(
    id: 'rocket_boots',
    slot: 'boots',
    title: '로켓 부츠',
    description: '',
    price: 550,
    icon: '🚀',
    speedBonus: 0.75,
    hpBonus: -10,
  ),
];

/// Stat upgrade definition for the meta shop.
class StatShopDef {
  final String id;
  final String statType;
  final String title;
  final String description;
  final int basePrice;
  final String icon;

  const StatShopDef({
    required this.id,
    required this.statType,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.icon,
  });
}

const List<StatShopDef> kAllStatUpgrades = [
  StatShopDef(
    id: 'hp',
    statType: 'hp',
    title: '최대 체력',
    description: '',
    basePrice: 50,
    icon: '❤️',
  ),
  StatShopDef(
    id: 'atk',
    statType: 'atk',
    title: '공격력',
    description: '',
    basePrice: 60,
    icon: '⚔️',
  ),
  StatShopDef(
    id: 'spd',
    statType: 'speed',
    title: '이동 속도',
    description: '',
    basePrice: 80,
    icon: '👟',
  ),
  StatShopDef(
    id: 'regen',
    statType: 'regen',
    title: '자동 회복',
    description: '',
    basePrice: 100,
    icon: '🧪',
  ),
  StatShopDef(
    id: 'crit',
    statType: 'crit',
    title: '치명타',
    description: '',
    basePrice: 90,
    icon: '🎯',
  ),
];

/// Controller for persistent meta-progression (shop, achievements, currency).
class MetaProgressController extends GetxController {
  // ── Observable meta data ──
  final currency = 0.obs;
  final unlockedCharacters = <String>['circle'].obs;
  final selectedCharacter = 'circle'.obs;
  final unlockedEquipment = <String>['wpn_gunner'].obs;
  final equippedEquipment = <String, String>{
    'weapon': 'wpn_gunner',
  }.obs;
  final achievements = <String, bool>{}.obs;
  final weaponLevels = <String, int>{}.obs;
  final statLevels = <String, int>{}.obs;
  final totalEnemiesKilled = 0.obs;
  final totalBossesDefeated = 0.obs;
  final totalDamageDealt = 0.0.obs;
  final highestStage = 0.obs;
  final highestCycle = 0.obs;
  final totalRunCount = 0.obs;

  List<String> get unlockedWeapons => unlockedEquipment
      .map(equipmentDefById)
      .whereType<EquipmentShopDef>()
      .where((equipment) => equipment.slot == 'weapon')
      .map((equipment) => equipment.weaponType)
      .whereType<String>()
      .toList();

  /// Whether data has been loaded from disk.
  final isLoaded = false.obs;

  /// Achievements newly completed in the latest run (for results screen).
  final newlyCompletedAchievements = <AchievementDef>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFromDisk();
  }

  /// Load persistent data from SharedPreferences.
  Future<void> loadFromDisk() async {
    final data = await PersistenceService.loadMeta();

    unlockedCharacters.value =
        _normalizedUnlockedCharacters(data.unlockedCharacters);
    selectedCharacter.value =
        unlockedCharacters.contains(data.selectedCharacter)
            ? data.selectedCharacter
            : 'circle';

    unlockedEquipment.value =
        _normalizedUnlockedEquipment(data.unlockedEquipment);
    equippedEquipment.value =
        _normalizedEquippedEquipment(data.equippedEquipment);

    achievements.value = Map<String, bool>.from(data.achievements);
    weaponLevels.value = Map<String, int>.from(data.weaponLevels);
    statLevels.value = Map<String, int>.from(data.statLevels);
    totalEnemiesKilled.value = data.totalEnemiesKilled;
    totalBossesDefeated.value = data.totalBossesDefeated;
    totalDamageDealt.value = data.totalDamageDealt;
    highestStage.value = data.highestStage;
    highestCycle.value = data.highestCycle;
    totalRunCount.value = data.totalRunCount;
    isLoaded.value = true;
  }

  /// Save current state to SharedPreferences.
  Future<void> saveToDisk() async {
    await PersistenceService.saveMeta(_toMetaData());
  }

  MetaProgressData _toMetaData() {
    return MetaProgressData(
      currency: currency.value,
      unlockedCharacters: List<String>.from(unlockedCharacters),
      selectedCharacter: selectedCharacter.value,
      unlockedEquipment: List<String>.from(unlockedEquipment),
      equippedWeapon:
          equippedWeaponType, // For backward compatibility if needed
      equippedEquipment: Map<String, String>.from(equippedEquipment),
      achievements: Map<String, bool>.from(achievements),
      weaponLevels: Map<String, int>.from(weaponLevels),
      statLevels: Map<String, int>.from(statLevels),
      totalEnemiesKilled: totalEnemiesKilled.value,
      totalBossesDefeated: totalBossesDefeated.value,
      totalDamageDealt: totalDamageDealt.value,
      highestStage: highestStage.value,
      highestCycle: highestCycle.value,
      totalRunCount: totalRunCount.value,
    );
  }

  String get equippedWeaponType {
    final id = equippedEquipment['weapon'];
    if (id == null) return 'gunner';
    final def = equipmentDefById(id);
    return def?.weaponType ?? 'gunner';
  }

  // ── Character Logic ──
  bool buyCharacter(CharacterShopDef char) {
    if (currency.value < char.price) return false;
    if (unlockedCharacters.contains(char.id)) return false;
    currency.value -= char.price;
    unlockedCharacters.add(char.id);
    selectedCharacter.value = char.id;
    saveToDisk();
    return true;
  }

  void selectCharacter(String charId) {
    if (unlockedCharacters.contains(charId)) {
      selectedCharacter.value = charId;
      saveToDisk();
    }
  }

  CharacterShopDef get currentCharacterDef {
    return kAllCharacters.firstWhere((c) => c.id == selectedCharacter.value,
        orElse: () => kAllCharacters.first);
  }

  LoadoutStatProfile get currentLoadoutStats {
    final equipped = kEquipmentSlotLabels.keys
        .map(equippedDefForSlot)
        .whereType<EquipmentShopDef>();
    return buildLoadoutStats(
      character: currentCharacterDef,
      equipment: equipped,
      statLevels: statLevels,
    );
  }

  static LoadoutStatProfile buildLoadoutStats({
    required CharacterShopDef character,
    required Iterable<EquipmentShopDef> equipment,
    required Map<String, int> statLevels,
  }) {
    double maxHp = PLAYER_BASE_HP + character.hpBonus;
    double atk = PLAYER_BASE_ATTACK + character.atkBonus;
    double def = PLAYER_BASE_DEFENSE + character.defBonus;
    double speed = PLAYER_BASE_SPEED + character.speedBonus;
    double regen = 0;
    double critChance = character.critBonus;
    double barrierHp = 0;
    int weaponCount = PLAYER_STARTING_WEAPON_COUNT;
    int bulletsPerWeapon = PLAYER_STARTING_BULLETS_PER_WEAPON;
    int bulletReflects = PLAYER_STARTING_BULLET_REFLECTS;

    for (final item in equipment) {
      maxHp += item.hpBonus;
      atk += item.atkBonus;
      def += item.defBonus;
      speed += item.speedBonus;
      critChance += item.critBonus;
      barrierHp += item.barrierBonus;
      weaponCount += item.weaponCountBonus;
      bulletsPerWeapon += item.bulletsPerWeaponBonus;
      bulletReflects += item.bulletReflectBonus;
    }

    maxHp += (statLevels['hp'] ?? 0) * kMetaHpGainPerLevel;
    atk += (statLevels['atk'] ?? 0) * kMetaAtkGainPerLevel;
    speed += (statLevels['speed'] ?? 0) * kMetaSpeedGainPerLevel;
    regen += (statLevels['regen'] ?? 0) * kMetaRegenGainPerLevel;
    critChance += (statLevels['crit'] ?? 0) * kMetaCritGainPerLevel;

    return LoadoutStatProfile(
      maxHp: math.max(1, maxHp),
      atk: math.max(1, atk),
      def: math.max(0, def),
      speed: math.min(MAX_SPEED, math.max(1, speed)),
      regen: math.max(0, regen),
      critChance: math.min(0.6, math.max(0, critChance)),
      barrierHp: math.max(0, barrierHp),
      weaponCount: math.min(
        PLAYER_MAX_WEAPON_COUNT,
        math.max(PLAYER_STARTING_WEAPON_COUNT, weaponCount),
      ),
      bulletsPerWeapon: math.min(
        PLAYER_MAX_BULLETS_PER_WEAPON,
        math.max(PLAYER_STARTING_BULLETS_PER_WEAPON, bulletsPerWeapon),
      ),
      bulletReflects: math.max(PLAYER_STARTING_BULLET_REFLECTS, bulletReflects),
    );
  }

  // ── Equipment Logic ──
  bool buyEquipment(EquipmentShopDef equipment) {
    if (currency.value < equipment.price) return false;
    if (unlockedEquipment.contains(equipment.id)) return false;
    currency.value -= equipment.price;
    unlockedEquipment.add(equipment.id);
    equippedEquipment[equipment.slot] = equipment.id;
    saveToDisk();
    return true;
  }

  void equipEquipment(EquipmentShopDef equipment) {
    if (!unlockedEquipment.contains(equipment.id)) return;
    equippedEquipment[equipment.slot] = equipment.id;
    saveToDisk();
  }

  EquipmentShopDef? equippedDefForSlot(String slot) {
    final id = equippedEquipment[slot];
    if (id == null) return null;
    return equipmentDefById(id);
  }

  EquipmentShopDef? equipmentDefById(String id) {
    for (final equipment in kAllEquipment) {
      if (equipment.id == id) return equipment;
    }
    return null;
  }

  List<String> _normalizedUnlockedCharacters(List<String> chars) {
    final normalized = <String>['circle'];
    for (final c in chars) {
      if (!normalized.contains(c)) normalized.add(c);
    }
    return normalized;
  }

  List<String> _normalizedUnlockedEquipment(List<String> equipment) {
    final validIds = kAllEquipment.map((e) => e.id).toSet();
    final normalized = <String>['wpn_gunner'];
    for (final id in equipment) {
      if (validIds.contains(id) && !normalized.contains(id)) {
        normalized.add(id);
      }
    }
    return normalized;
  }

  Map<String, String> _normalizedEquippedEquipment(Map<String, String> saved) {
    final normalized = <String, String>{};
    // Default weapon if not set
    normalized['weapon'] = 'wpn_gunner';

    for (final entry in saved.entries) {
      final equipment = equipmentDefById(entry.value);
      if (equipment == null) continue;
      if (equipment.slot != entry.key) continue;
      if (!unlockedEquipment.contains(equipment.id)) continue;
      normalized[entry.key] = equipment.id;
    }
    return normalized;
  }

  // ── Weapon Upgrade Logic ──
  int getWeaponLevel(String weaponType) {
    return weaponLevels[weaponType] ?? 0;
  }

  int getWeaponUpgradeCost(String weaponType) {
    final def =
        kAllEquipment.firstWhereOrNull((e) => e.weaponType == weaponType);
    if (def == null) return 100;
    final level = getWeaponLevel(weaponType);
    return def.price + (level * (def.price ~/ 2 + 10));
  }

  bool upgradeWeapon(String weaponType) {
    final cost = getWeaponUpgradeCost(weaponType);
    if (currency.value < cost) return false;

    currency.value -= cost;
    final currentLevel = getWeaponLevel(weaponType);
    weaponLevels[weaponType] = currentLevel + 1;
    saveToDisk();
    return true;
  }

  // ── Stat Upgrade Logic ──
  int getStatLevel(String statType) {
    return statLevels[statType] ?? 0;
  }

  int getStatUpgradeCost(StatShopDef stat) {
    final level = getStatLevel(stat.statType);
    return stat.basePrice + (level * (stat.basePrice ~/ 1.5).round());
  }

  bool upgradeStat(StatShopDef stat) {
    final cost = getStatUpgradeCost(stat);
    if (currency.value < cost) return false;

    currency.value -= cost;
    final currentLevel = getStatLevel(stat.statType);
    statLevels[stat.statType] = currentLevel + 1;
    saveToDisk();
    return true;
  }

  // ── Run End logic ──
  List<AchievementDef> endRun({
    required int enemiesKilled,
    required int bossesDefeated,
    required double damageDealt,
    required int stageReached,
    required int cycleReached,
  }) {
    totalEnemiesKilled.value += enemiesKilled;
    totalBossesDefeated.value += bossesDefeated;
    totalDamageDealt.value += damageDealt;
    highestStage.value = math.max(highestStage.value, stageReached);
    highestCycle.value = math.max(highestCycle.value, cycleReached);
    totalRunCount.value += 1;

    final newlyCompleted = <AchievementDef>[];
    for (final ach in kAllAchievements) {
      if (achievements[ach.id] == true) continue;

      bool completed = false;
      switch (ach.category) {
        case 'kill':
          completed = totalEnemiesKilled.value >= ach.threshold;
          break;
        case 'stage':
          completed = highestStage.value >= ach.threshold;
          break;
        case 'boss':
          completed = totalBossesDefeated.value >= ach.threshold;
          break;
        case 'damage':
          completed = totalDamageDealt.value >= ach.threshold;
          break;
      }

      if (completed) {
        achievements[ach.id] = true;
        currency.value += ach.currencyReward;
        newlyCompleted.add(ach);
      }
    }

    newlyCompletedAchievements.value = newlyCompleted;
    saveToDisk();
    return newlyCompleted;
  }

  Future<void> resetAll() async {
    await PersistenceService.resetMeta();
    await loadFromDisk();
  }
}
