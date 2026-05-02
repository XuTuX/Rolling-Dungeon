// Persistent meta-progression data that survives across runs.
// Saved/loaded via PersistenceService.

class MetaProgressData {
  /// Currency earned from achievements (NOT from runs).
  int currency;

  /// Permanently unlocked weapon IDs (e.g., 'minigun', 'blade').
  List<String> unlockedWeapons;

  /// Permanently unlocked skill IDs (future expansion).
  List<String> unlockedSkills;

  /// Permanently unlocked character IDs.
  List<String> unlockedCharacters;

  /// The character selected for the run.
  String selectedCharacter;

  /// Permanently unlocked equipment IDs.
  List<String> unlockedEquipment;

  /// Legacy field for backward compatibility or simple weapon-only checks.
  String equippedWeapon;

  /// Equipped item IDs mapped by slot.
  Map<String, String> equippedEquipment;

  /// Achievements completed (id -> true).
  Map<String, bool> achievements;

  /// Current level of each weapon type.
  Map<String, int> weaponLevels;

  /// Current level of each stat upgrade.
  Map<String, int> statLevels;

  // Stats
  int totalEnemiesKilled;
  int totalBossesDefeated;
  double totalDamageDealt;
  int highestStage;
  int highestCycle;
  int totalRunCount;

  MetaProgressData({
    this.currency = 0,
    List<String>? unlockedWeapons,
    List<String>? unlockedSkills,
    List<String>? unlockedEquipment,
    List<String>? unlockedCharacters,
    this.equippedWeapon = 'gunner',
    this.selectedCharacter = 'circle',
    Map<String, String>? equippedEquipment,
    Map<String, bool>? achievements,
    Map<String, int>? weaponLevels,
    Map<String, int>? statLevels,
    this.totalEnemiesKilled = 0,
    this.totalBossesDefeated = 0,
    this.totalDamageDealt = 0,
    this.highestStage = 0,
    this.highestCycle = 0,
    this.totalRunCount = 0,
  })  : unlockedWeapons = unlockedWeapons ?? ['gunner'],
        unlockedSkills = unlockedSkills ?? [],
        unlockedEquipment = unlockedEquipment ?? [],
        unlockedCharacters = unlockedCharacters ?? ['circle'],
        equippedEquipment = equippedEquipment ?? {},
        achievements = achievements ?? {},
        weaponLevels = weaponLevels ?? {},
        statLevels = statLevels ?? {};

  /// Serialize to JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'currency': currency,
        'unlockedWeapons': unlockedWeapons,
        'unlockedSkills': unlockedSkills,
        'unlockedEquipment': unlockedEquipment,
        'unlockedCharacters': unlockedCharacters,
        'equippedWeapon': equippedWeapon,
        'selectedCharacter': selectedCharacter,
        'equippedEquipment': equippedEquipment,
        'achievements': achievements,
        'weaponLevels': weaponLevels,
        'statLevels': statLevels,
        'totalEnemiesKilled': totalEnemiesKilled,
        'totalBossesDefeated': totalBossesDefeated,
        'totalDamageDealt': totalDamageDealt,
        'highestStage': highestStage,
        'highestCycle': highestCycle,
        'totalRunCount': totalRunCount,
      };

  /// Deserialize from JSON map.
  factory MetaProgressData.fromJson(Map<String, dynamic> json) {
    return MetaProgressData(
      currency: json['currency'] as int? ?? 0,
      unlockedWeapons: (json['unlockedWeapons'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ['gunner'],
      unlockedSkills: (json['unlockedSkills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      unlockedEquipment: (json['unlockedEquipment'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      unlockedCharacters: (json['unlockedCharacters'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ['circle'],
      equippedWeapon: json['equippedWeapon'] as String? ?? 'gunner',
      selectedCharacter: json['selectedCharacter'] as String? ?? 'circle',
      equippedEquipment: (json['equippedEquipment'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      achievements: (json['achievements'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v == true),
          ) ??
          {},
      weaponLevels: (json['weaponLevels'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
      statLevels: (json['statLevels'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
      totalEnemiesKilled: json['totalEnemiesKilled'] as int? ?? 0,
      totalBossesDefeated: json['totalBossesDefeated'] as int? ?? 0,
      totalDamageDealt: (json['totalDamageDealt'] as num?)?.toDouble() ?? 0,
      highestStage: json['highestStage'] as int? ?? 0,
      highestCycle: json['highestCycle'] as int? ?? 0,
      totalRunCount: json['totalRunCount'] as int? ?? 0,
    );
  }
}
