// Achievement definitions for the meta-progression system.
// Currency is earned ONLY through completing achievements (not from runs).

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final int currencyReward;
  final String category; // 'kill', 'stage', 'boss', 'survival', 'damage'

  /// The threshold value to check against cumulative stats.
  final int threshold;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.currencyReward,
    required this.category,
    required this.threshold,
  });
}

/// All achievements available in the game.
const List<AchievementDef> kAllAchievements = [
  // ── Kill Achievements ──
  AchievementDef(
    id: 'kill_10',
    title: '초보 사냥꾼',
    description: '적 10마리 처치',
    currencyReward: 50,
    category: 'kill',
    threshold: 10,
  ),
  AchievementDef(
    id: 'kill_50',
    title: '숙련된 전사',
    description: '적 50마리 처치',
    currencyReward: 100,
    category: 'kill',
    threshold: 50,
  ),
  AchievementDef(
    id: 'kill_100',
    title: '전설의 사냥꾼',
    description: '적 100마리 처치',
    currencyReward: 150,
    category: 'kill',
    threshold: 100,
  ),
  AchievementDef(
    id: 'kill_200',
    title: '학살자',
    description: '적 200마리 처치',
    currencyReward: 200,
    category: 'kill',
    threshold: 200,
  ),

  // ── Stage Achievements ──
  AchievementDef(
    id: 'reach_stage_5',
    title: '탐험 시작',
    description: '스테이지 5 도달',
    currencyReward: 30,
    category: 'stage',
    threshold: 5,
  ),
  AchievementDef(
    id: 'reach_stage_10',
    title: '깊은 던전',
    description: '스테이지 10 도달',
    currencyReward: 80,
    category: 'stage',
    threshold: 10,
  ),
  AchievementDef(
    id: 'reach_stage_20',
    title: '심연의 탐험가',
    description: '스테이지 20 도달',
    currencyReward: 150,
    category: 'stage',
    threshold: 20,
  ),
  AchievementDef(
    id: 'reach_stage_30',
    title: '끝없는 던전',
    description: '스테이지 30 도달',
    currencyReward: 250,
    category: 'stage',
    threshold: 30,
  ),

  // ── Boss Achievements ──
  AchievementDef(
    id: 'boss_1',
    title: '첫 번째 승리',
    description: '보스 1마리 처치',
    currencyReward: 100,
    category: 'boss',
    threshold: 1,
  ),
  AchievementDef(
    id: 'boss_3',
    title: '보스 사냥꾼',
    description: '보스 3마리 처치',
    currencyReward: 200,
    category: 'boss',
    threshold: 3,
  ),
  AchievementDef(
    id: 'boss_5',
    title: '보스 학살자',
    description: '보스 5마리 처치',
    currencyReward: 350,
    category: 'boss',
    threshold: 5,
  ),
  AchievementDef(
    id: 'boss_10',
    title: '던전 마스터',
    description: '보스 10마리 처치',
    currencyReward: 500,
    category: 'boss',
    threshold: 10,
  ),

  // ── Damage Achievements ──
  AchievementDef(
    id: 'damage_1000',
    title: '꾸준한 공격',
    description: '총 피해 1,000 달성',
    currencyReward: 60,
    category: 'damage',
    threshold: 1000,
  ),
  AchievementDef(
    id: 'damage_5000',
    title: '파괴자',
    description: '총 피해 5,000 달성',
    currencyReward: 120,
    category: 'damage',
    threshold: 5000,
  ),
  AchievementDef(
    id: 'damage_20000',
    title: '대재앙',
    description: '총 피해 20,000 달성',
    currencyReward: 300,
    category: 'damage',
    threshold: 20000,
  ),
];
