import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:circle_war/game/auto_battle/models/meta_data.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:circle_war/services/persistence_service.dart';

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
    this.trait = '',
  });
}

const List<CharacterShopDef> kAllCharacters = [
  CharacterShopDef(
    id: 'circle',
    title: '동그라미',
    description: '가장 균형 잡힌 기본 형태입니다. 모든 능력치가 평범합니다.',
    price: 0,
    icon: '🔴',
    shape: 'circle',
    hpBonus: 0,
    atkBonus: 0,
    speedBonus: 0,
    trait: '균형 잡힌 성장',
  ),
  CharacterShopDef(
    id: 'square',
    title: '네모',
    description: '단단하고 묵직한 형태입니다. 체력과 방어력이 높지만 느립니다.',
    price: 300,
    icon: '🟦',
    shape: 'square',
    hpBonus: 40,
    defBonus: 2.0,
    speedBonus: -0.2,
    trait: '충돌 저항력 증가',
  ),
  CharacterShopDef(
    id: 'triangle',
    title: '세모',
    description: '날카롭고 민첩한 형태입니다. 공격력과 속도가 높지만 약합니다.',
    price: 450,
    icon: '▲',
    shape: 'triangle',
    hpBonus: -20,
    atkBonus: 5.0,
    speedBonus: 0.35,
    trait: '치명적인 돌진',
  ),
  CharacterShopDef(
    id: 'pentagon',
    title: '오각형',
    description: '신비로운 마력을 지닌 형태입니다. 다양한 유틸리티 보너스를 제공합니다.',
    price: 800,
    icon: '⬔',
    shape: 'pentagon',
    hpBonus: 10,
    atkBonus: 2.0,
    defBonus: 1.0,
    speedBonus: 0.15,
    trait: '고대의 지혜',
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
    this.weaponCountBonus = 0,
    this.bulletsPerWeaponBonus = 0,
    this.bulletReflectBonus = 0,
    this.barrierBonus = 0,
  });

  String get statSummary {
    final parts = <String>[];
    if (hpBonus != 0) parts.add('HP ${hpBonus > 0 ? "+" : ""}${hpBonus.toStringAsFixed(0)}');
    if (atkBonus != 0) parts.add('ATK ${atkBonus > 0 ? "+" : ""}${atkBonus.toStringAsFixed(1)}');
    if (defBonus != 0) parts.add('DEF ${defBonus > 0 ? "+" : ""}${defBonus.toStringAsFixed(1)}');
    if (speedBonus != 0) parts.add('SPD ${speedBonus > 0 ? "+" : ""}${speedBonus.toStringAsFixed(2)}');
    if (weaponCountBonus != 0) parts.add('WPN +$weaponCountBonus');
    if (bulletsPerWeaponBonus != 0) parts.add('SHOT +$bulletsPerWeaponBonus');
    if (bulletReflectBonus != 0) parts.add('REF +$bulletReflectBonus');
    if (barrierBonus != 0) parts.add('BAR +${barrierBonus.toStringAsFixed(0)}');
    return parts.join(' / ');
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
    description: '안정적인 사격이 가능한 표준 총기입니다.',
    price: 0,
    icon: '🔫',
    weaponType: 'gunner',
  ),
  EquipmentShopDef(
    id: 'wpn_minigun',
    slot: 'weapon',
    title: '미니건',
    description: '매우 빠른 연사 속도로 탄환을 퍼부어 적을 압도합니다.',
    price: 300,
    icon: '🔥',
    weaponType: 'minigun',
    speedBonus: -0.1,
  ),
  EquipmentShopDef(
    id: 'wpn_blade_master',
    slot: 'weapon',
    title: '회전 칼날',
    description: '주변을 회전하며 근접한 적을 베어버리는 강력한 칼날입니다.',
    price: 450,
    icon: '⚔️',
    weaponType: 'blade',
    atkBonus: 2.0,
  ),
  EquipmentShopDef(
    id: 'wpn_aura',
    slot: 'weapon',
    title: '수호자의 오라',
    description: '주변 적에게 지속 피해를 주는 영역을 생성합니다.',
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
    description: '손 장비. 사격 밀도를 높여 더 많은 탄환을 발사합니다.',
    price: 150,
    icon: '🧤',
    bulletsPerWeaponBonus: 1,
    speedBonus: 0.1,
  ),
  EquipmentShopDef(
    id: 'scope_ring',
    slot: 'hand',
    title: '조준 반지',
    description: '장신구. 공격력과 도탄 능력을 향상시킵니다.',
    price: 250,
    icon: '💍',
    atkBonus: 3.0,
    bulletReflectBonus: 1,
  ),
  EquipmentShopDef(
    id: 'magic_pendant',
    slot: 'hand',
    title: '마법 펜던트',
    description: '장신구. 보호막과 공격력을 동시에 챙깁니다.',
    price: 350,
    icon: '📿',
    atkBonus: 1.5,
    barrierBonus: 25,
  ),
  EquipmentShopDef(
    id: 'power_bracelet',
    slot: 'hand',
    title: '힘의 팔찌',
    description: '손 장비. 체력을 희생하여 막강한 공격력을 얻습니다.',
    price: 450,
    icon: '⌚',
    atkBonus: 5.0,
    hpBonus: -15,
  ),

  // ── Armor (4 items) ──
  EquipmentShopDef(
    id: 'plate_armor',
    slot: 'armor',
    title: '판금 갑옷',
    description: '옷 장비. 최대 체력과 방어력을 안정적으로 올립니다.',
    price: 200,
    icon: '🛡️',
    hpBonus: 40,
    defBonus: 1.0,
  ),
  EquipmentShopDef(
    id: 'reactive_coat',
    slot: 'armor',
    title: '반응 코트',
    description: '옷 장비. 피격 시 충격을 흡수하는 보호막을 생성합니다.',
    price: 300,
    icon: '🦺',
    hpBonus: 20,
    barrierBonus: 45,
  ),
  EquipmentShopDef(
    id: 'spiked_armor',
    slot: 'armor',
    title: '가시 갑옷',
    description: '옷 장비. 적의 공격을 버텨내며 반격의 기회를 엿봅니다.',
    price: 400,
    icon: '🥋',
    atkBonus: 2.5,
    defBonus: 1.5,
  ),
  EquipmentShopDef(
    id: 'wind_tunic',
    slot: 'armor',
    title: '바람의 튜닉',
    description: '옷 장비. 가벼운 소재로 제작되어 이동 속도를 높여줍니다.',
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
    description: '발 장비. 이동 속도를 크게 향상시킵니다.',
    price: 180,
    icon: '👟',
    speedBonus: 0.5,
  ),
  EquipmentShopDef(
    id: 'knockback_boots',
    slot: 'boots',
    title: '반동 부츠',
    description: '발 장비. 빠른 기동성과 함께 공격 성능을 보조합니다.',
    price: 280,
    icon: '🥾',
    speedBonus: 0.3,
    atkBonus: 1.5,
  ),
  EquipmentShopDef(
    id: 'heavy_boots',
    slot: 'boots',
    title: '헤비 부츠',
    description: '발 장비. 느려지지만 매우 단단한 방어력을 제공합니다.',
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
    description: '발 장비. 폭발적인 속도로 전장을 누빕니다.',
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
    description: '공의 최대 체력을 영구적으로 증가시킵니다.',
    basePrice: 50,
    icon: '❤️',
  ),
  StatShopDef(
    id: 'atk',
    statType: 'atk',
    title: '공격력',
    description: '모든 무기의 기본 공격력을 영구적으로 증가시킵니다.',
    basePrice: 60,
    icon: '⚔️',
  ),
  StatShopDef(
    id: 'spd',
    statType: 'speed',
    title: '이동 속도',
    description: '공의 이동 속도를 영구적으로 증가시킵니다.',
    basePrice: 80,
    icon: '👟',
  ),
  StatShopDef(
    id: 'regen',
    statType: 'regen',
    title: '자동 회복',
    description: '초당 체력 회복량을 영구적으로 증가시킵니다.',
    basePrice: 100,
    icon: '🧪',
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
      .where((id) => equipmentDefById(id)?.slot == 'weapon')
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
    // For simulation/testing: force currency to 10000
    currency.value = 10000;
    
    unlockedCharacters.value = _normalizedUnlockedCharacters(data.unlockedCharacters);
    selectedCharacter.value = unlockedCharacters.contains(data.selectedCharacter)
        ? data.selectedCharacter
        : 'circle';
        
    unlockedEquipment.value = _normalizedUnlockedEquipment(data.unlockedEquipment);
    equippedEquipment.value = _normalizedEquippedEquipment(data.equippedEquipment);
    
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
      equippedWeapon: equippedWeaponType, // For backward compatibility if needed
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
    return kAllCharacters.firstWhere((c) => c.id == selectedCharacter.value, orElse: () => kAllCharacters.first);
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
    final def = kAllEquipment.firstWhereOrNull((e) => e.weaponType == weaponType);
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
        case 'kill': completed = totalEnemiesKilled.value >= ach.threshold; break;
        case 'stage': completed = highestStage.value >= ach.threshold; break;
        case 'boss': completed = totalBossesDefeated.value >= ach.threshold; break;
        case 'damage': completed = totalDamageDealt.value >= ach.threshold; break;
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
