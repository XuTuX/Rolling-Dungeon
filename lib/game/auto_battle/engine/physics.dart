import 'dart:math' as math;
import 'constants.dart';
import 'types.dart';

double clamp(double value, double min, double max) {
  return math.max(min, math.min(max, value));
}

Vec2 normalize(Vec2 vec) {
  final length = math.sqrt(vec.x * vec.x + vec.y * vec.y);
  if (length == 0) {
    final angle = math.Random().nextDouble() * math.pi * 2;
    return Vec2(x: math.cos(angle), y: math.sin(angle));
  }
  return Vec2(
    x: vec.x / length,
    y: vec.y / length,
  );
}

Vec2 randomDir() {
  final angle = math.Random().nextDouble() * math.pi * 2;
  return Vec2(
    x: math.cos(angle),
    y: math.sin(angle),
  );
}

double distance(Vec2 a, Vec2 b) {
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}

void updatePosition(PlayerData player, double dtMs) {
  if (!player.alive) return;

  final pixels = player.speed * dtMs * 0.12;
  player.pos.x += player.vel.x * pixels;
  player.pos.y += player.vel.y * pixels;
}

void handleWallCollision(PlayerData player) {
  if (!player.alive) return;

  final minX = player.radius;
  final maxX = ARENA_WIDTH - player.radius;
  final minY = player.radius;
  final maxY = ARENA_HEIGHT - player.radius;

  if (player.pos.x < minX || player.pos.x > maxX) {
    player.pos.x = clamp(player.pos.x, minX, maxX);
    player.vel.x *= -1;
  }

  if (player.pos.y < minY || player.pos.y > maxY) {
    player.pos.y = clamp(player.pos.y, minY, maxY);
    player.vel.y *= -1;
  }

  player.vel = normalize(player.vel);
}

bool checkCircleCollision(PlayerData a, PlayerData b) {
  if (!a.alive || !b.alive) return false;
  return distance(a.pos, b.pos) <= a.radius + b.radius;
}

void resolveCircleCollision(PlayerData a, PlayerData b) {
  if (!a.alive || !b.alive) return;

  final dx = b.pos.x - a.pos.x;
  final dy = b.pos.y - a.pos.y;
  var dist = math.sqrt(dx * dx + dy * dy);
  if (dist == 0) dist = 0.0001;

  final minDistance = a.radius + b.radius;
  final overlap = minDistance - dist;

  if (overlap > 0) {
    final nx = dx / dist;
    final ny = dy / dist;
    final separation = overlap / 2;

    a.pos.x -= nx * separation;
    a.pos.y -= ny * separation;
    b.pos.x += nx * separation;
    b.pos.y += ny * separation;

    final dotA = a.vel.x * nx + a.vel.y * ny;
    final dotB = b.vel.x * nx + b.vel.y * ny;

    a.vel.x = a.vel.x - (dotA - dotB) * nx;
    a.vel.y = a.vel.y - (dotA - dotB) * ny;
    b.vel.x = b.vel.x - (dotB - dotA) * nx;
    b.vel.y = b.vel.y - (dotB - dotA) * ny;

    a.vel.x -= nx * COLLISION_BOUNCE_IMPULSE;
    a.vel.y -= ny * COLLISION_BOUNCE_IMPULSE;
    b.vel.x += nx * COLLISION_BOUNCE_IMPULSE;
    b.vel.y += ny * COLLISION_BOUNCE_IMPULSE;

    a.vel = normalize(a.vel);
    b.vel = normalize(b.vel);
  }

  handleWallCollision(a);
  handleWallCollision(b);
}

bool checkLineCircleCollision(Vec2 start, Vec2 end, Vec2 circleCenter, double radius) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return distance(start, circleCenter) <= radius;

  final t = (((circleCenter.x - start.x) * dx + (circleCenter.y - start.y) * dy) / lengthSquared).clamp(0.0, 1.0);
  final projection = Vec2(
    x: start.x + dx * t,
    y: start.y + dy * t,
  );
  return distance(projection, circleCenter) <= radius;
}

void resolveWeaponCollision(PlayerData attacker, PlayerData victim, Vec2 wStart, Vec2 wEnd) {
  if (!attacker.alive || !victim.alive) return;

  final dx = wEnd.x - wStart.x;
  final dy = wEnd.y - wStart.y;
  final lengthSq = dx * dx + dy * dy;
  if (lengthSq == 0) return;

  final t = (((victim.pos.x - wStart.x) * dx + (victim.pos.y - wStart.y) * dy) / lengthSq).clamp(0.0, 1.0);
  final closest = Vec2(
    x: wStart.x + dx * t,
    y: wStart.y + dy * t,
  );

  final dist = distance(closest, victim.pos);
  final overlap = (victim.radius * 0.8) - dist; // Slightly tighter for weapons

  if (overlap > 0) {
    final nx = (victim.pos.x - closest.x) / (dist == 0 ? 0.001 : dist);
    final ny = (victim.pos.y - closest.y) / (dist == 0 ? 0.001 : dist);
    
    // Push the victim away from the weapon
    victim.pos.x += nx * overlap;
    victim.pos.y += ny * overlap;
    
    // Transfer some momentum
    victim.vel.x += nx * 0.12;
    victim.vel.y += ny * 0.12;
    victim.vel = normalize(victim.vel);
  }
}
