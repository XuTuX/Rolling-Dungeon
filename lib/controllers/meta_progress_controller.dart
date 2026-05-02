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
  // ── Weapons ──
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
    description: '빠른 연사 속도로 적을 압도합니다.',
    price: 120,
    icon: '🔫',
    weaponType: 'minigun',
  ),
  EquipmentShopDef(
    id: 'wpn_long_gun',
    slot: 'weapon',
    title: '장거리 포',
    description: '느리지만 강력한 대구경 탄환을 발사합니다.',
    price: 180,
    icon: '🚀',
    weaponType: 'long_gun',
  ),
  EquipmentShopDef(
    id: 'wpn_poison_gun',
    slot: 'weapon',
    title: '독 가스 분무기',
    description: '지나가는 자리에 치명적인 독구름을 남깁니다.',
    price: 150,
    icon: '☣️',
    weaponType: 'poison',
  ),
  EquipmentShopDef(
    id: 'wpn_blade_master',
    slot: 'weapon',
    title: '회전 칼날',
    description: '공 주변을 회전하며 근접한 적을 베어버립니다.',
    price: 200,
    icon: '⚔️',
    weaponType: 'blade',
  ),
  EquipmentShopDef(
    id: 'wpn_mine_layer',
    slot: 'weapon',
    title: '지뢰 매설기',
    description: '뒤쪽으로 강력한 폭발 지뢰를 투척합니다.',
    price: 160,
    icon: '💣',
    weaponType: 'miner',
  ),
  EquipmentShopDef(
    id: 'wpn_footsteps',
    slot: 'weapon',
    title: '불타는 발자국',
    description: '지나간 자리에 불꽃 자취를 남겨 지속 피해를 줍니다.',
    price: 170,
    icon: '👣',
    weaponType: 'footsteps',
  ),
  EquipmentShopDef(
    id: 'wpn_burst_gun',
    slot: 'weapon',
    title: '전방위 버스트',
    description: '사방으로 퍼지는 탄환을 발사합니다.',
    price: 220,
    icon: '💢',
    weaponType: 'burst',
  ),
  EquipmentShopDef(
    id: 'wpn_heavy_blade',
    slot: 'weapon',
    title: '거대 대검',
    description: '매우 크고 강력한 칼날이 천천히 회전합니다.',
    price: 250,
    icon: '🗡️',
    weaponType: 'heavy_blade',
  ),
  EquipmentShopDef(
    id: 'wpn_ricochet',
    slot: 'weapon',
    title: '도탄 사격',
    description: '벽에 여러 번 튕기는 특수 탄환을 사용합니다.',
    price: 190,
    icon: '✨',
    weaponType: 'ricochet',
  ),
  EquipmentShopDef(
    id: 'wpn_aura',
    slot: 'weapon',
    title: '수호자의 오라',
    description: '주변의 적에게 지속적인 피해를 주는 영역을 생성합니다.',
    price: 280,
    icon: '🌀',
    weaponType: 'aura',
  ),

  // ── Accessories ──
  EquipmentShopDef(
    id: 'rapid_glove',
    slot: 'hand',
    title: '속사 장갑',
    description: '손 장비. 투사체 계열 무기의 발사 밀도를 올립니다.',
    price: 140,
    icon: '🧤',
    bulletsPerWeaponBonus: 1,
    speedBonus: 0.12,
  ),
  EquipmentShopDef(
    id: 'scope_ring',
    slot: 'hand',
    title: '조준 반지',
    description: '장신구. 공격 보조와 치명타 감각을 공격력으로 환산합니다.',
    price: 160,
    icon: '💍',
    atkBonus: 2.0,
    bulletReflectBonus: 1,
  ),
  EquipmentShopDef(
    id: 'spring_boots',
    slot: 'boots',
    title: '스프링 부츠',
    description: '발 장비. 이동 속도와 회피 여지를 늘립니다.',
    price: 130,
    icon: '👟',
    speedBonus: 0.42,
  ),
  EquipmentShopDef(
    id: 'knockback_boots',
    slot: 'boots',
    title: '반동 부츠',
    description: '발 장비. 더 빠른 충돌 템포로 전장을 휘젓습니다.',
    price: 170,
    icon: '🥾',
    speedBonus: 0.24,
    atkBonus: 1.0,
  ),
  EquipmentShopDef(
    id: 'plate_armor',
    slot: 'armor',
    title: '판금 갑옷',
    description: '옷 장비. 최대 체력과 방어력을 안정적으로 올립니다.',
    price: 150,
    icon: '🛡️',
    hpBonus: 32,
    defBonus: 0.8,
  ),
  EquipmentShopDef(
    id: 'reactive_coat',
    slot: 'armor',
    title: '반응 코트',
    description: '옷 장비. 피격 전 보호막을 먼저 두릅니다.',
    price: 190,
    icon: '🦺',
    hpBonus: 16,
    barrierBonus: 36,
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
