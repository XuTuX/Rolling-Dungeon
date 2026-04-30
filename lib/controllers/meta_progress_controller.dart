import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:circle_war/game/auto_battle/models/meta_data.dart';
import 'package:circle_war/game/auto_battle/models/achievement_data.dart';
import 'package:circle_war/services/persistence_service.dart';

/// Weapon definition for the persistent shop.
class WeaponShopDef {
  final String id;
  final String weaponType;
  final String title;
  final String description;
  final int price;
  final String icon;

  const WeaponShopDef({
    required this.id,
    required this.weaponType,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
  });
}

/// All weapons available for purchase in the meta shop.
const List<WeaponShopDef> kAllShopWeapons = [
  WeaponShopDef(
    id: 'minigun',
    weaponType: 'minigun',
    title: '미니건',
    description: '빠른 연사 속도로 적을 압도합니다.',
    price: 120,
    icon: '🔫',
  ),
  WeaponShopDef(
    id: 'long_gun',
    weaponType: 'long_gun',
    title: '장거리 포',
    description: '느리지만 강력한 대구경 탄환을 발사합니다.',
    price: 180,
    icon: '🚀',
  ),
  WeaponShopDef(
    id: 'poison_gun',
    weaponType: 'poison',
    title: '독 가스 분무기',
    description: '지나가는 자리에 치명적인 독구름을 남깁니다.',
    price: 150,
    icon: '☣️',
  ),
  WeaponShopDef(
    id: 'blade_master',
    weaponType: 'blade',
    title: '회전 칼날',
    description: '공 주변을 회전하며 근접한 적을 베어버립니다.',
    price: 200,
    icon: '⚔️',
  ),
  WeaponShopDef(
    id: 'mine_layer',
    weaponType: 'miner',
    title: '지뢰 매설기',
    description: '뒤쪽으로 강력한 폭발 지뢰를 투척합니다.',
    price: 160,
    icon: '💣',
  ),
  WeaponShopDef(
    id: 'footsteps',
    weaponType: 'footsteps',
    title: '불타는 발자국',
    description: '지나간 자리에 불꽃 자취를 남겨 지속 피해를 줍니다.',
    price: 170,
    icon: '👣',
  ),
  WeaponShopDef(
    id: 'burst_gun',
    weaponType: 'burst',
    title: '전방위 버스트',
    description: '사방으로 퍼지는 탄환을 발사합니다.',
    price: 220,
    icon: '💢',
  ),
  WeaponShopDef(
    id: 'heavy_blade',
    weaponType: 'heavy_blade',
    title: '거대 대검',
    description: '매우 크고 강력한 칼날이 천천히 회전합니다.',
    price: 250,
    icon: '🗡️',
  ),
  WeaponShopDef(
    id: 'ricochet',
    weaponType: 'ricochet',
    title: '도탄 사격',
    description: '벽에 여러 번 튕기는 특수 탄환을 사용합니다.',
    price: 190,
    icon: '✨',
  ),
  WeaponShopDef(
    id: 'aura',
    weaponType: 'aura',
    title: '수호자의 오라',
    description: '주변의 적에게 지속적인 피해를 주는 영역을 생성합니다.',
    price: 280,
    icon: '🌀',
  ),
];

/// Controller for persistent meta-progression (shop, achievements, currency).
/// This persists across runs and app restarts.
class MetaProgressController extends GetxController {
  // ── Observable meta data ──
  final currency = 0.obs;
  final unlockedWeapons = <String>['gunner'].obs;
  final unlockedSkills = <String>[].obs;
  final equippedWeapon = 'gunner'.obs;
  final achievements = <String, bool>{}.obs;
  final totalEnemiesKilled = 0.obs;
  final totalBossesDefeated = 0.obs;
  final totalDamageDealt = 0.0.obs;
  final highestStage = 0.obs;
  final highestCycle = 0.obs;
  final totalRunCount = 0.obs;

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
    currency.value = data.currency;
    unlockedWeapons.value = List<String>.from(data.unlockedWeapons);
    if (!unlockedWeapons.contains('gunner')) {
      unlockedWeapons.insert(0, 'gunner');
    }
    unlockedSkills.value = List<String>.from(data.unlockedSkills);
    equippedWeapon.value = data.equippedWeapon;
    achievements.value = Map<String, bool>.from(data.achievements);
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
      unlockedWeapons: List<String>.from(unlockedWeapons),
      unlockedSkills: List<String>.from(unlockedSkills),
      equippedWeapon: equippedWeapon.value,
      achievements: Map<String, bool>.from(achievements),
      totalEnemiesKilled: totalEnemiesKilled.value,
      totalBossesDefeated: totalBossesDefeated.value,
      totalDamageDealt: totalDamageDealt.value,
      highestStage: highestStage.value,
      highestCycle: highestCycle.value,
      totalRunCount: totalRunCount.value,
    );
  }

  // ──────────────────────────────────────────
  //  Shop: Buy Weapon
  // ──────────────────────────────────────────
  bool buyWeapon(WeaponShopDef weapon) {
    if (currency.value < weapon.price) return false;
    if (unlockedWeapons.contains(weapon.weaponType)) return false;
    currency.value -= weapon.price;
    unlockedWeapons.add(weapon.weaponType);
    saveToDisk();
    return true;
  }

  bool isWeaponUnlocked(String weaponType) {
    return unlockedWeapons.contains(weaponType);
  }

  void equipWeapon(String weaponType) {
    if (unlockedWeapons.contains(weaponType)) {
      equippedWeapon.value = weaponType;
      saveToDisk();
    }
  }

  // ──────────────────────────────────────────
  //  Run End: Accumulate Stats & Check Achievements
  // ──────────────────────────────────────────
  /// Called at the end of a run with the run's stats.
  /// Returns the list of newly completed achievements.
  List<AchievementDef> endRun({
    required int enemiesKilled,
    required int bossesDefeated,
    required double damageDealt,
    required int stageReached,
    required int cycleReached,
  }) {
    // Accumulate stats
    totalEnemiesKilled.value += enemiesKilled;
    totalBossesDefeated.value += bossesDefeated;
    totalDamageDealt.value += damageDealt;
    highestStage.value = math.max(highestStage.value, stageReached);
    highestCycle.value = math.max(highestCycle.value, cycleReached);
    totalRunCount.value += 1;

    // Check achievements
    final newlyCompleted = <AchievementDef>[];
    for (final ach in kAllAchievements) {
      if (achievements[ach.id] == true) continue; // already completed

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

  /// Reset everything (debug only).
  Future<void> resetAll() async {
    await PersistenceService.resetMeta();
    await loadFromDisk();
  }
}
