import 'package:circle_war/constant.dart';
import 'package:circle_war/theme/app_typography.dart';
import '../controllers/score_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ScoreController scoreController = Get.find<ScoreController>();

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: charcoalBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // VS text in the middle
              Positioned(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4081), // Vibrant Pink/Red
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: charcoalBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: charcoalBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'VS',
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Left Side: SCORE
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SCORE',
                          style: AppTypography.label.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                              scoreController.score.value.toString(),
                              style: AppTypography.scoreMedium.copyWith(
                                fontSize: 32,
                              ),
                            )),
                        Obx(() => scoreController.combo.value > 1
                            ? Text(
                                'COMBO x${scoreController.combo.value}',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orangeAccent,
                                ),
                              )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60), // Space for VS badge
                  // Right Side: BEST
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BEST',
                          style: AppTypography.label.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                              scoreController.highscore.value.toString(),
                              style: AppTypography.scoreMedium.copyWith(
                                fontSize: 32,
                                color: charcoalBlack.withValues(alpha: 0.6),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
