import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/controllers/meta_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown after character select. Player chooses a weapon from their
/// permanently unlocked collection before entering a run.
class EquipWeaponScreen extends StatelessWidget {
  const EquipWeaponScreen({super.key});

  static const _weaponInfo = <String, _WeaponDisplayInfo>{
    'gunner': _WeaponDisplayInfo(
      name: '기본 사격',
      desc: '회전하며 자동으로 탄환을 발사합니다.',
      icon: Icons.gps_fixed,
      color: AutoBattlePalette.primary,
      emoji: '🔫',
    ),
    'minigun': _WeaponDisplayInfo(
      name: '미니건',
      desc: '빠른 연사 속도로 적을 압도합니다.',
      icon: Icons.bolt,
      color: Color(0xFF475569),
      emoji: '🔫',
    ),
    'long_gun': _WeaponDisplayInfo(
      name: '장거리 포',
      desc: '느리지만 강력한 대구경 탄환을 발사합니다.',
      icon: Icons.center_focus_strong,
      color: Color(0xFFDC2626),
      emoji: '🚀',
    ),
    'poison': _WeaponDisplayInfo(
      name: '독 가스 분무기',
      desc: '지나가는 자리에 치명적인 독구름을 남깁니다.',
      icon: Icons.bubble_chart,
      color: Color(0xFF16A34A),
      emoji: '☣️',
    ),
    'blade': _WeaponDisplayInfo(
      name: '회전 칼날',
      desc: '공 주변을 회전하며 근접한 적을 베어버립니다.',
      icon: Icons.autorenew,
      color: Color(0xFF7C3AED),
      emoji: '⚔️',
    ),
    'miner': _WeaponDisplayInfo(
      name: '지뢰 매설기',
      desc: '뒤쪽으로 강력한 폭발 지뢰를 투척합니다.',
      icon: Icons.dangerous,
      color: Color(0xFFEF4444),
      emoji: '💣',
    ),
    'footsteps': _WeaponDisplayInfo(
      name: '불타는 발자국',
      desc: '지나간 자리에 불꽃 자취를 남겨 지속 피해를 줍니다.',
      icon: Icons.whatshot,
      color: Color(0xFFF97316),
      emoji: '👣',
    ),
    'burst': _WeaponDisplayInfo(
      name: '전방위 버스트',
      desc: '사방으로 퍼지는 탄환을 발사합니다.',
      icon: Icons.flare,
      color: Color(0xFFFACC15),
      emoji: '💢',
    ),
    'heavy_blade': _WeaponDisplayInfo(
      name: '거대 대검',
      desc: '매우 크고 강력한 칼날이 천천히 회전합니다.',
      icon: Icons.gavel,
      color: Color(0xFF0F172A),
      emoji: '🗡️',
    ),
    'ricochet': _WeaponDisplayInfo(
      name: '도탄 사격',
      desc: '벽에 여러 번 튕기는 특수 탄환을 사용합니다.',
      icon: Icons.keyboard_return,
      color: Color(0xFF0284C7),
      emoji: '✨',
    ),
    'aura': _WeaponDisplayInfo(
      name: '수호자의 오라',
      desc: '주변의 적에게 지속적인 피해를 주는 영역을 생성합니다.',
      icon: Icons.shield,
      color: Color(0xFFA855F7),
      emoji: '🌀',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final metaCtrl = Get.find<MetaProgressController>();
    final runCtrl = Get.find<GameProgressController>();

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SketchBgPainter())),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Title
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: AutoBattlePalette.ink, width: 4),
                    boxShadow: const [
                      BoxShadow(
                          color: AutoBattlePalette.ink, offset: Offset(6, 6)),
                    ],
                  ),
                  child: const Text(
                    'EQUIP WEAPON',
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '전투에 사용할 무기를 선택하세요',
                  style: TextStyle(
                    color: AutoBattlePalette.inkSubtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Weapon Grid
                Expanded(
                  child: Obx(() {
                    final unlocked = metaCtrl.unlockedWeapons;
                    final selected = metaCtrl.equippedWeapon.value;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: unlocked.map((weaponType) {
                            final info = _weaponInfo[weaponType];
                            if (info == null) return const SizedBox.shrink();
                            final isSelected = weaponType == selected;
                            return _EquipWeaponCard(
                              weaponType: weaponType,
                              info: info,
                              isSelected: isSelected,
                              onTap: () {
                                metaCtrl.equipWeapon(weaponType);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ),

                // Bottom buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Back
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AutoBattlePalette.ink, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: AutoBattlePalette.ink,
                                    offset: Offset(4, 4)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'BACK',
                                style: TextStyle(
                                  color: AutoBattlePalette.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Start Run
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            // Set the equipped weapon as character type
                            // and start the run
                            runCtrl.characterType.value =
                                metaCtrl.equippedWeapon.value;
                            Get.off(() => const AutoBattleGamePage());
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AutoBattlePalette.primary,
                              border: Border.all(
                                  color: AutoBattlePalette.ink, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: AutoBattlePalette.ink,
                                    offset: Offset(4, 4)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'ENTER DUNGEON ➔',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaponDisplayInfo {
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final String emoji;

  const _WeaponDisplayInfo({
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

class _EquipWeaponCard extends StatelessWidget {
  final String weaponType;
  final _WeaponDisplayInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  const _EquipWeaponCard({
    required this.weaponType,
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 155,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? info.color.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? info.color : AutoBattlePalette.ink,
            width: isSelected ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? info.color.withValues(alpha: 0.4)
                  : AutoBattlePalette.ink,
              offset: Offset(isSelected ? 6 : 4, isSelected ? 6 : 4),
            ),
          ],
        ),
        transform:
            isSelected ? Matrix4.translationValues(0, -3, 0) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? info.color : info.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AutoBattlePalette.ink, width: 2.5),
              ),
              child: Center(
                child: Icon(
                  info.icon,
                  color: isSelected ? Colors.white : info.color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AutoBattlePalette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AutoBattlePalette.inkSubtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: info.color,
                  border: Border.all(
                      color: AutoBattlePalette.ink, width: 2),
                ),
                child: const Text(
                  'EQUIPPED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SketchBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;
    for (var y = 28.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
