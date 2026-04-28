import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant.dart';
import '../controllers/game_controller.dart';
import '../tetris.dart';

class DraggableBlock extends StatelessWidget {
  final int index;
  final double cellSize;
  final GlobalKey gridKey;

  const DraggableBlock({
    super.key,
    required this.index,
    required this.cellSize,
    required this.gridKey,
  });

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find<GameController>();

    return Obx(() {
      if (index >= controller.activeShapes.length ||
          index >= controller.activeColors.length ||
          controller.activeShapes[index] == null ||
          controller.activeColors[index] == null) {
        return const SizedBox(width: boxSize, height: boxSize);
      }

      List<Offset> selectedShape = controller.activeShapes[index]!;
      Color color = controller.activeColors[index]!;

      // Display logic (small version in dock)
      // Original code used 0.8 scale for dock display
      // And full scale for feedback

      return Draggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: TetrisBlock(
            shape: selectedShape,
            color: color.withValues(alpha: 0.7), // Slightly transparent on drag
            cellSize: cellSize,
          ),
        ),
        childWhenDragging: SizedBox(
          width: cellSize * 3,
          height: cellSize * 3,
        ),
        dragAnchorStrategy: (draggable, context, position) {
          // feedback widget (TetrisBlock) is 3 * cellSize wide/high
          // Pointer at bottom center of the 3x3 grid
          return Offset(1.5 * cellSize, 3.0 * cellSize);
        },
        onDragUpdate: (details) {
          _handleDragUpdate(context, details, controller, selectedShape, color);
        },
        onDragEnd: (details) {
          _handleDragEnd(context, details, controller, selectedShape, index);
        },
        child: Container(
          width: cellSize * 0.8 * 3,
          height: cellSize * 0.8 * 3,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: TetrisBlock(
            shape: selectedShape,
            color: color,
            cellSize: cellSize * 0.8,
          ),
        ),
      );
    });
  }

  void _handleDragUpdate(BuildContext context, DragUpdateDetails details,
      GameController controller, List<Offset> shape, Color color) {
    RenderBox? gridBox =
        gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    // Feedback is 3x3, anchor is at (1.5, 3.0) cells relative to top-left
    Offset anchor = Offset(1.5 * cellSize, 3.0 * cellSize);
    Offset dropPosition = details.globalPosition - anchor;
    Offset gridPosition = gridBox.localToGlobal(Offset.zero);

    // Center of the 3x3 grid
    double centerX = dropPosition.dx + (1.5 * cellSize);
    double centerY = dropPosition.dy + (1.5 * cellSize);

    double relativeX = centerX - gridPosition.dx;
    double relativeY = centerY - gridPosition.dy;

    int centerColumn = (relativeX / cellSize).floor();
    int centerRow = (relativeY / cellSize).floor();

    controller.updateHover(centerRow, centerColumn, shape, color);
  }

  void _handleDragEnd(BuildContext context, DraggableDetails details,
      GameController controller, List<Offset> shape, int index) {
    RenderBox? gridBox =
        gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    Offset dropPosition = details.offset;
    Offset gridPosition = gridBox.localToGlobal(Offset.zero);

    // Center of the 3x3 grid
    double centerX = dropPosition.dx + (1.5 * cellSize);
    double centerY = dropPosition.dy + (1.5 * cellSize);

    double relativeX = centerX - gridPosition.dx;
    double relativeY = centerY - gridPosition.dy;

    int centerColumn = (relativeX / cellSize).floor();
    int centerRow = (relativeY / cellSize).floor();

    controller.placeBlock(centerRow, centerColumn, index);
  }
}
