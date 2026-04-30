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

/// ⬢ Hexagonal Wall Collision
/// Checks collision against 6 edges of a regular hexagon.
void handleWallCollision(PlayerData player) {
  if (!player.alive) return;

  final centerX = ARENA_WIDTH / 2;
  final centerY = ARENA_HEIGHT / 2;
  final radius = (ARENA_WIDTH / 2) - 10.0; // Margin from the edge
  final playerRadius = player.radius;

  // The distance from the center to each edge of a regular hexagon
  final distToEdge = radius * math.cos(math.pi / 6);
  final limit = distToEdge - playerRadius;

  // Check 6 planes (normals of the hexagon edges)
  for (int i = 0; i < 6; i++) {
    // Normal angle of the i-th edge
    final angle = i * math.pi / 3 + math.pi / 6;
    final nx = math.cos(angle);
    final ny = math.sin(angle);

    // Vector from center to player
    final dx = player.pos.x - centerX;
    final dy = player.pos.y - centerY;

    // Projection onto normal
    final projection = dx * nx + dy * ny;

    if (projection > limit) {
      // Collision detected! 
      // 1. Push back
      final overlap = projection - limit;
      player.pos.x -= nx * overlap;
      player.pos.y -= ny * overlap;

      // 2. Reflect velocity (Elastic bounce)
      // v_new = v - 2 * (v dot n) * n
      final dot = player.vel.x * nx + player.vel.y * ny;
      if (dot > 0) { // Only reflect if moving towards the wall
        player.vel.x -= 2 * dot * nx;
        player.vel.y -= 2 * dot * ny;
      }
    }
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
