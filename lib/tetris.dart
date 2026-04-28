// tetris_block.dart
import 'package:flutter/material.dart';

class TetrisBlock extends StatelessWidget {
  final double cellSize;
  final List<Offset> shape;
  final Color color;

  const TetrisBlock({
    super.key,
    required this.shape,
    required this.color,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    double blockWidth = 3 * cellSize;
    double blockHeight = 3 * cellSize;

    return SizedBox(
      width: blockWidth,
      height: blockHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: shape.map((offset) {
          return Positioned(
            left: offset.dx * cellSize,
            top: offset.dy * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}
