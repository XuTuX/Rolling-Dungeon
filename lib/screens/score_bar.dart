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
    double fontSize = 34;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildScoreBox('SCORE', scoreController.score, fontSize,
                increment: scoreController.lastIncrement,
                showIncrement: scoreController.showIncrement,
                combo: scoreController.combo),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildScoreBox('BEST', scoreController.highscore, fontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, RxInt value, double fontSize,
      {RxInt? increment, RxBool? showIncrement, RxInt? combo}) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.value.toString(),
                    style: AppTypography.scoreMedium,
                  ),
                ],
              )),
          if (combo != null)
            Obx(() => combo.value > 1
                ? Text(
                    'COMBO x${combo.value}',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : const SizedBox(height: 12)),
        ],
      ),
    );
  }
}
