import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant.dart';

import '../controllers/game_controller.dart';

import 'board.dart';
import 'draggable_block.dart';
import 'score_bar.dart';
import '../controllers/score_controller.dart';
import '../controllers/theme_controller.dart';

import '../widgets/dialogs/tutorial_dialog.dart';

class GameScreen extends StatefulWidget {
  final bool shouldRestore;
  const GameScreen({super.key, this.shouldRestore = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _gridKey = GlobalKey();
  late final GameController controller;

  @override
  void initState() {
    super.initState();
    // Put controllers if not already there
    Get.put(ThemeController());
    Get.put(ScoreController());
    controller = Get.put(GameController());

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (!widget.shouldRestore) {
      controller.resetGame();
      return;
    }

    final restored = await controller.loadGameState();
    if (restored) return;

    controller.resetGame();
    if (!mounted) return;
    Get.snackbar(
      '저장 데이터 복원 실패',
      '손상되었거나 만료된 데이터여서 새 게임으로 시작했어요.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(themeController),
        body: Stack(
          children: [
            SafeArea(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (orientation == Orientation.portrait) {
                        return _buildPortraitLayout(
                            context, themeController, constraints);
                      } else {
                        return _buildLandscapeLayout(
                            context, themeController, constraints);
                      }
                    },
                  );
                },
              ),
            ),
            if (controller.showTutorial.value)
              Container(
                color: charcoalBlack.withValues(alpha: 0.8),
                child: TutorialDialog(onClose: controller.completeTutorial),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ThemeController themeController,
    BoxConstraints constraints,
  ) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;

    double gridSize = screenHeight * 0.8;
    // Ensure grid doesn't take too much width either
    if (gridSize > screenWidth * 0.6) {
      gridSize = screenWidth * 0.6;
    }

    double cellSize = gridSize / gridColumns;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left side: Board and Score
        SizedBox(
          width: gridSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: gridSize, child: const ScoreBar()),
                const SizedBox(height: 10),
                _buildBoard(gridSize, cellSize),
              ],
            ),
          ),
        ),
        // Right side: Controls / Blocks
        Container(
          width: cellSize * 4,
          height: screenHeight * 0.8,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 3; i++)
                DraggableBlock(
                  index: i,
                  cellSize: cellSize,
                  gridKey: _gridKey,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context,
      ThemeController themeController, BoxConstraints constraints) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;

    // Adjust grid size calculation logic
    double gridSize = screenWidth * 0.85;

    // On wider screens (tablets), restrict max width
    if (screenWidth > 600) {
      gridSize = screenWidth * 0.6; // 60% of screen width (Reduced from 70%)
      if (gridSize > 600) {
        gridSize = 600; // Cap at 600px (Reduced from 750px)
      }
    }

    // Ensure it fits vertically too with some buffer for other UI elements
    double maxGridHeight = screenHeight * 0.6;
    if (gridSize > maxGridHeight) {
      gridSize = maxGridHeight;
    }

    double cellSize = gridSize / gridColumns;

    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: gridSize,
            child: const ScoreBar(),
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildBoard(gridSize, cellSize),
          SizedBox(height: screenHeight * 0.03),
          // Tetromino area
          Container(
            height: cellSize * 3.5, // Reduced slightly to fit tighter
            width: gridSize,
            alignment: Alignment.center,
            // Use FittedBox to handle potential rounding errors causing overflow
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: gridSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < 3; i++)
                      DraggableBlock(
                        index: i,
                        cellSize: cellSize,
                        gridKey: _gridKey,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeController themeController) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          // Mini logo blocks matching home screen
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: regionColors[4],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: charcoalBlack, width: 1.5),
                    ),
                  ),
                ),
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: regionColors[1],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: charcoalBlack, width: 1.5),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: regionColors[0],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: charcoalBlack, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'circle-war',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        _buildAppBarButton(
          icon: Icons.home_rounded,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 8),
        _buildAppBarButton(
          icon: Icons.refresh_rounded,
          onPressed: () => controller.restartGame(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: charcoalBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: charcoalBlack,
        ),
      ),
    );
  }

  Widget _buildBoard(double gridSize, double cellSize) {
    return SizedBox(
      key: _gridKey,
      height: gridSize,
      width: gridSize,
      child: Stack(
        children: [
          Board(
            gridSize: gridSize,
            cellSize: cellSize,
          ),
          _ParticleOverlay(
            controller: controller,
            cellSize: cellSize,
          ),
          Obx(() {
            return Stack(
              children: controller.floatingScores.map((fs) {
                return _FloatingScoreWidget(
                  key: ValueKey(fs.id),
                  floatingScore: fs,
                  cellSize: cellSize,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _FloatingScoreWidget extends StatefulWidget {
  final FloatingScore floatingScore;
  final double cellSize;

  const _FloatingScoreWidget({
    super.key,
    required this.floatingScore,
    required this.cellSize,
  });

  @override
  State<_FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<_FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_animationController);

    _positionAnimation = Tween<Offset>(
      begin: Offset(
        (widget.floatingScore.position.dx + 0.5) * widget.cellSize,
        (widget.floatingScore.position.dy + 0.5) * widget.cellSize,
      ),
      end: Offset(
        (widget.floatingScore.position.dx + 0.5) * widget.cellSize,
        (widget.floatingScore.position.dy) * widget.cellSize - 40,
      ),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Clamp position to keep text within board bounds
        double left = _positionAnimation.value.dx - 50;
        double top = _positionAnimation.value.dy;

        // Assuming board is square and size is widget.cellSize * gridColumns
        // We can use a reasonable margin to prevent clipping
        double boardSize =
            widget.cellSize * 10; // 10 is gridColumns from constant.dart
        if (left < 0) left = 5;
        if (left > boardSize - 100) left = boardSize - 105;
        if (top < 0) top = 5;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 100,
              alignment: Alignment.center,
              child: Text(
                widget.floatingScore.message,
                style: TextStyle(
                  fontSize: widget.floatingScore.isLarge ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: widget.floatingScore.color,
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(2, 2),
                      blurRadius: 2,
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticleOverlay extends StatefulWidget {
  final GameController controller;
  final double cellSize;

  const _ParticleOverlay({required this.controller, required this.cellSize});

  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<_Particle> _particles = [];
  late Worker _worker;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _worker = ever(widget.controller.lastClearedCells, (List<int> cells) {
      if (cells.isNotEmpty) {
        _spawnParticles(cells);
      }
    });

    _animationController.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update(_animationController.value);
        }
      });
    });
  }

  void _spawnParticles(List<int> cells) {
    _particles.clear();
    final random = DateTime.now().millisecondsSinceEpoch;
    int i = 0;
    for (int cellIndex in cells) {
      int row = cellIndex ~/ gridColumns;
      int col = cellIndex % gridColumns;

      // Color from region if possible
      Color color = Colors.blue;
      if (widget.controller.regionGrid.isNotEmpty) {
        int region = widget.controller.regionGrid[row][col];
        color = regionColors[region % regionColors.length];
      }

      for (int count = 0; count < 2; count++) {
        _particles.add(_Particle(
          origin: Offset(
            (col + 0.5) * widget.cellSize,
            (row + 0.5) * widget.cellSize,
          ),
          color: color,
          seed: random + (i++),
        ));
      }
    }
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _worker.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles, _animationController.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  final Offset origin;
  final Color color;
  final int seed;
  late Offset position;
  late double velocityX;
  late double velocityY;
  late double size;

  _Particle({required this.origin, required this.color, required this.seed}) {
    final r = (seed * 12345) % 1000 / 1000.0;
    final r2 = (seed * 6789) % 1000 / 1000.0;
    final speed = 50.0 + r2 * 150.0;
    velocityX = speed * (r > 0.5 ? 1 : -1) * (r % 0.5);
    velocityY = speed * (r2 > 0.5 ? 1 : -1) * (r2 % 0.5);
    position = origin;
    size = 4.0 + (seed % 6);
  }

  void update(double t) {
    position = origin + Offset(velocityX * t, velocityY * t + 100 * t * t);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    for (var p in particles) {
      _paint.color = p.color.withValues(alpha: 1.0 - progress);
      canvas.drawCircle(p.position, p.size * (1.0 - progress), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
