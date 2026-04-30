import 'package:circle_war/controllers/game_progress_controller.dart';
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller permanently so it stays across screens (Game, Upgrade, etc.)
    if (!Get.isRegistered<GameProgressController>()) {
      Get.put(GameProgressController(), permanent: true);
    }

    return Scaffold(
      backgroundColor: AutoBattlePalette.background,
      body: Stack(
        children: [
          // Background "Sketch" Lines
          Positioned.fill(
            child: CustomPaint(
              painter: _SketchLinesPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Title
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AutoBattlePalette.ink, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: AutoBattlePalette.ink,
                        offset: Offset(6, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    'CHOOSE YOUR HERO',
                    style: TextStyle(
                      color: AutoBattlePalette.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Character Cards
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCharacterCard(
                            id: 'gunner',
                            name: 'GUNNER',
                            description: 'Rotating Shot\nLow ATK',
                            color: AutoBattlePalette.primary,
                            icon: Icons.my_location,
                          ),
                          const SizedBox(width: 24),
                          _buildCharacterCard(
                            id: 'blade',
                            name: 'BLADE',
                            description: 'Contact Blade\nHigh HP',
                            color: AutoBattlePalette.secondary,
                            icon: Icons.change_history,
                          ),
                          const SizedBox(width: 24),
                          _buildCharacterCard(
                            id: 'miner',
                            name: 'MINER',
                            description: 'Drop Mines\nHigh SPD',
                            color: AutoBattlePalette.gold,
                            icon: Icons.trip_origin,
                          ),
                          const SizedBox(width: 24),
                          _buildCharacterCard(
                            id: 'poison',
                            name: 'POISON',
                            description: 'Rear Spray\nShort Cloud',
                            color: AutoBattlePalette.mint,
                            icon: Icons.bubble_chart,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Back Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AutoBattlePalette.surfaceLight,
                        border:
                            Border.all(color: AutoBattlePalette.ink, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AutoBattlePalette.ink,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'BACK TO MENU',
                        style: TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard({
    required String id,
    required String name,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        // Start run and navigate to game
        final controller = Get.find<GameProgressController>();
        controller.startNewRun(id);
        Get.off(() => const AutoBattleGamePage());
      },
      child: Container(
        width: 220,
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AutoBattlePalette.ink, width: 4),
          boxShadow: const [
            BoxShadow(
              color: AutoBattlePalette.ink,
              offset: Offset(8, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Image/Color Box
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  border: const Border(
                    bottom: BorderSide(color: AutoBattlePalette.ink, width: 4),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 64,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                          color: AutoBattlePalette.ink, offset: Offset(3, 3)),
                    ],
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AutoBattlePalette.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AutoBattlePalette.inkSubtle,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutoBattlePalette.ink.withValues(alpha: 0.05)
      ..strokeWidth = 2;

    final random = math.Random(123);
    for (var i = 0; i < 30; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (random.nextDouble() - 0.5) * 50),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
