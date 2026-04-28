// ignore_for_file: constant_identifier_names

const int ARENA_WIDTH = 500;
const int ARENA_HEIGHT = 500;

const int TICK_RATE = 30;
const int TICK_MS = 1000 ~/ TICK_RATE;

const int MAX_PLAYERS = 2;
const int MAX_LIVES = 3;
const int VICTORY_STAGE = 10;

const double BASE_HP = 200.0;
const double BASE_ATK = 5.0;
const double BASE_DEF = 2.0;
const double BASE_SPEED = 2.8;
const double MAX_SPEED = 10.0;
const double PLAYER_RADIUS = 12.0;

const int FOOD_MAX_COUNT = 35;
const int FOOD_SPAWN_MS = 400;
const double FOOD_SMALL_GOLD = 4.0;
const double FOOD_BIG_GOLD = 12.0;
const double FOOD_BIG_CHANCE = 0.15;

const int LEVEL_BASE_XP = 40;
const int LEVEL_XP_GROWTH = 15;
const int LEVEL_HEAL_AMOUNT = 12;
const int LEVEL_CHOICE_COUNT = 3;

const double UPGRADE_ASSAULT_ATK_GAIN = 3.5;
const double UPGRADE_GUARD_DEF_GAIN = 1.1;
const double UPGRADE_GUARD_HP_GAIN = 4.0;
const double UPGRADE_HASTE_SPEED_GAIN = 0.12;
const double UPGRADE_VITALITY_HP_GAIN = 20.0;
const double UPGRADE_VITALITY_HEAL = 40.0;
const double UPGRADE_MASTERY_ATK_GAIN = 1.2;
const double UPGRADE_MASTERY_POWER_GAIN = 1.0;

const int ROUND_RESTART_MS = 5000;

const int POISON_DROP_MS = 520;
const int POISON_DURATION_MS = 2600;
const double POISON_RADIUS = 16.0;

const int GUNNER_FIRE_MS = 900;
const double GUNNER_RANGE = 260.0;
const double BULLET_SPEED = 0.36;
const double BULLET_RADIUS = 5.0;

const int BLADE_ATTACK_MS = 850;
const double BLADE_RANGE = 62.0;
const int BLADE_EFFECT_MS = 220;

const int MINER_DROP_MS = 2300;
const int MINE_DURATION_MS = 6200;
const double MINE_RADIUS = 20.0;

const int LASER_FIRE_MS = 1200;
const double LASER_RANGE = 300.0;
const int LASER_DURATION_MS = 400;
const int LASER_DAMAGE_TICK_MS = 100;
