import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant.dart';
import '../controllers/game_controller.dart';
import '../border.dart';
import '../controllers/theme_controller.dart';

class Board extends StatelessWidget {
  final double gridSize;
  final double cellSize;

  const Board({
    super.key,
    required this.gridSize,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find<GameController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
          ),
          itemCount: gridColumns * gridRows,
          itemBuilder: (context, index) {
            // Obx is placed HERE, wrapping the individual item.
            // This ensures each cell rebuilds reactively when its data changes.
            return Obx(() {
              Color? cellColor;
              int row = index ~/ gridColumns;
              int col = index % gridColumns;

              // Check if initialized
              if (row >= controller.filledGrid.length ||
                  col >= controller.filledGrid[0].length) {
                return Container(
                  width: cellSize,
                  height: cellSize,
                  color: Colors.transparent,
                );
              }

              // Active blocks (dropped)
              if (controller.filledGrid[row][col] != -1) {
                int val = controller.filledGrid[row][col];
                if (val < 100) {
                  // Fallback for old save games
                  if (controller.regionGrid.isNotEmpty &&
                      row < controller.regionGrid.length &&
                      col < controller.regionGrid[row].length) {
                    int region = controller.regionGrid[row][col];
                    cellColor = themeController.regionColors[
                        region % themeController.regionColors.length];
                  } else {
                    cellColor = Colors.grey;
                  }
                } else {
                  cellColor = Color(val);
                }
              }
              // Hover (Ghost piece)
              else if (controller.hoverCells.contains(index)) {
                cellColor = controller.hoverColor.value;
              }
              // Empty cell (region background)
              else {
                cellColor = Colors.white;
              }

              bool isFilled = controller.filledGrid[row][col] != -1;
              bool isHover = controller.hoverCells.contains(index);

              bool isJustPlaced = controller.lastPlacedCells.contains(index);

              return AnimatedScale(
                scale: isJustPlaced ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: themeController.cellDecoration(
                    isFilled,
                    cellColor!,
                    isHover: isHover,
                  ),
                ),
              );
            });
          },
        ),
        Obx(() {
          if (controller.regionGrid.isEmpty) return const SizedBox.shrink();
          return CustomPaint(
            size: Size(gridSize, gridSize),
            painter:
                GridBorderPainter(controller.regionGrid, gridColumns, cellSize),
          );
        }),
      ],
    );
  }
}
