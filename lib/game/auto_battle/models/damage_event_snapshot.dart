class DamageEventSnapshot {
  final String victimId;
  final double damage;
  final double x;
  final double y;
  final bool isCritical;

  const DamageEventSnapshot({
    required this.victimId,
    required this.damage,
    required this.x,
    required this.y,
    this.isCritical = false,
  });

  factory DamageEventSnapshot.fromJson(Map<String, dynamic> json) {
    return DamageEventSnapshot(
      victimId: json['victimId']?.toString() ?? '',
      damage: (json['damage'] as num?)?.toDouble() ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      isCritical: json['isCritical'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'victimId': victimId,
        'damage': damage,
        'x': x,
        'y': y,
        'isCritical': isCritical,
      };
}
