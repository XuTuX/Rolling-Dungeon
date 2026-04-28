import 'dart:math' as math;
import 'package:circle_war/game/auto_battle/auto_battle_palette.dart';
import 'package:circle_war/game/auto_battle/ui/auto_battle_game_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final logoFontSize =
                    (width * 0.085).clamp(34.0, 64.0).toDouble();
                final logoPaddingX =
                    (width * 0.055).clamp(22.0, 40.0).toDouble();
                final logoPaddingY =
                    (height * 0.045).clamp(10.0, 20.0).toDouble();
                final buttonWidth =
                    (width * 0.46).clamp(230.0, 320.0).toDouble();
                final buttonHeight =
                    (height * 0.18).clamp(60.0, 90.0).toDouble();
                final contentGap = (height * 0.11).clamp(24.0, 60.0).toDouble();

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with thick ink outline, scaled for short landscape phones.
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: logoPaddingX,
                                vertical: logoPaddingY,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: AutoBattlePalette.ink, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AutoBattlePalette.ink,
                                    offset: Offset(8, 8),
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'AUTO BATTLE',
                                  style: TextStyle(
                                    color: AutoBattlePalette.ink,
                                    fontSize: logoFontSize,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: contentGap),

                            // Action Button
                            GestureDetector(
                              onTap: () =>
                                  Get.to(() => const AutoBattleGamePage()),
                              child: Container(
                                width: buttonWidth,
                                height: buttonHeight,
                                decoration: BoxDecoration(
                                  color: AutoBattlePalette.primary,
                                  border: Border.all(
                                      color: AutoBattlePalette.ink, width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AutoBattlePalette.ink,
                                      offset: Offset(6, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'ENTER ARENA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: (buttonHeight * 0.31)
                                          .clamp(20.0, 28.0)
                                          .toDouble(),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                                height: (height * 0.06)
                                    .clamp(18.0, 32.0)
                                    .toDouble()),

                            const Text(
                              'VERSION 3.0 // SKETCH MODE',
                              style: TextStyle(
                                color: AutoBattlePalette.inkSubtle,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

    // Draw some random horizontal "scribbles"
    final random = math.Random(42);
    for (var i = 0; i < 20; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (random.nextDouble() - 0.5) * 40),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
