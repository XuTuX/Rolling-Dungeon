import 'dart:async';
import 'dart:math';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant.dart';
import '../random.dart';
import '../screens/game_over.dart';
import 'score_controller.dart';
import '../services/settings_service.dart';
import '../services/ad_service.dart';

class FloatingScore {
  final Offset position;
  final String message;
  final String id;
  final Color color;
  final bool isLarge;

  FloatingScore({
    required this.position,
    required this.message,
    required this.id,
    this.color = charcoalBlack,
    this.isLarge = false,
  });
}

enum ContinueResult {
  success,
  alreadyUsed,
  noValidRegion,
  adNotCompleted,
  adUnavailable,
}

class GameController extends GetxController {
  late ScoreController scoreController;
  late SettingsService settingsService;
  final Random _random = Random();

  var droppedBlockPositions = <int>[].obs;
  // regionGrid does not change after init/reset, but we might want to observe it if we restart.
  var regionGrid = <List<int>>[].obs;
  var filledGrid = <List<int>>[].obs;

  var activeShapes = <List<Offset>?>[].obs;
  var activeColors = <Color?>[].obs;

  var isGameOver = false.obs;
  var hoverCells = <int>[].obs;
  var hoverColor = Rx<Color?>(null);

  var floatingScores = <FloatingScore>[].obs;

  // Visual FX triggers
  var lastClearedCells = <int>[].obs;
  var lastPlacedCells = <int>[].obs;

  // Combo & Tutorial
  var currentCombo = 1.obs;
  var showTutorial = true.obs;
  var hasSavedGame = false.obs;
  var hasUsedContinueThisGame = false.obs;
  final String _tutorialKey = 'tutorial_seen';
  final String _saveKey = 'game_state';

  @override
  void onInit() {
    super.onInit();
    // Assuming ScoreController is already put in dependency injection system, or we put it here.
    // In Home Screen it was Get.put(ScoreController()).
    // We can find it here.
    try {
      scoreController = Get.find<ScoreController>();
    } catch (e) {
      scoreController = Get.put(ScoreController());
    }
    settingsService = Get.find<SettingsService>();

    _checkTutorial();
    checkHasSavedGame();
  }

  Future<void> checkHasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    hasSavedGame.value = prefs.containsKey(_saveKey);
  }

  Future<void> saveGameState() async {
    if (isGameOver.value) return;

    final prefs = await SharedPreferences.getInstance();

    // Serialize active shapes
    final List<dynamic> shapesJson = activeShapes.map((shape) {
      return shape
          ?.map((offset) => {'dx': offset.dx, 'dy': offset.dy})
          .toList();
    }).toList();

    // Serialize active colors
    final List<dynamic> colorsJson = activeColors.map((color) {
      return color?.toARGB32();
    }).toList();

    final Map<String, dynamic> state = {
      'score': scoreController.score.value,
      'blockScore': scoreController.blockScore.value,
      'regionScore': scoreController.regionScore.value,
      'droppedBlockPositions': droppedBlockPositions.toList(),
      'regionGrid': regionGrid.toList(),
      'filledGrid': filledGrid.toList(),
      'activeShapes': shapesJson,
      'activeColors': colorsJson,
      'currentCombo': currentCombo.value,
      'hasUsedContinueThisGame': hasUsedContinueThisGame.value,
    };

    await prefs.setString(_saveKey, jsonEncode(state));
    hasSavedGame.value = true;
  }

  Future<bool> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statusJson = prefs.getString(_saveKey);
    if (statusJson == null) return false;

    try {
      final Map<String, dynamic> state = jsonDecode(statusJson);

      scoreController.score.value = state['score'];
      scoreController.blockScore.value = state['blockScore'];
      scoreController.regionScore.value = state['regionScore'];

      droppedBlockPositions
          .assignAll(List<int>.from(state['droppedBlockPositions']));
      regionGrid.assignAll(List<List<dynamic>>.from(state['regionGrid'])
          .map((row) => List<int>.from(row))
          .toList());
      filledGrid.assignAll(List<List<dynamic>>.from(state['filledGrid'])
          .map((row) => List<int>.from(row))
          .toList());

      // Deserialize active shapes
      final List<dynamic> shapesJson = state['activeShapes'];
      activeShapes.assignAll(shapesJson.map((shapeJson) {
        if (shapeJson == null) return null;
        return List<dynamic>.from(shapeJson).map((item) {
          return Offset(item['dx'].toDouble(), item['dy'].toDouble());
        }).toList();
      }).toList());

      // Deserialize active colors
      final List<dynamic> colorsJson = state['activeColors'];
      activeColors.assignAll(colorsJson.map((colorVal) {
        if (colorVal == null) return null;
        return Color(colorVal);
      }).toList());

      currentCombo.value = state['currentCombo'];
      hasUsedContinueThisGame.value = state['hasUsedContinueThisGame'] ?? false;
      isGameOver.value = false;
      hasSavedGame.value = true;
      return true;
    } catch (e) {
      debugPrint("Error loading game state: $e");
      return false;
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    hasSavedGame.value = false;
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    showTutorial.value = !(prefs.getBool(_tutorialKey) ?? false);
  }

  void completeTutorial() async {
    showTutorial.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
    _checkTrackingPermission();
  }

  void openTutorial() {
    showTutorial.value = true;
  }

  void resetGame() {
    scoreController.resetScore();
    droppedBlockPositions.clear();
    activeShapes.clear();
    activeColors.clear();
    isGameOver.value = false;
    hoverCells.clear();
    hoverColor.value = null;
    floatingScores.clear();
    lastPlacedCells.clear();
    lastClearedCells.clear();
    currentCombo.value = 1;
    hasUsedContinueThisGame.value = false;

    clearSavedGame();

    // Generate regions
    regionGrid.value = generateRegions(gridColumns, numTeams, gridColumns + 4);
    // Initialize filledGrid with -1
    filledGrid.value =
        List.generate(gridRows, (_) => List.filled(gridColumns, -1));

    generateNewBlocks();
  }

  void generateNewBlocks() {
    final List<List<Offset>> placeableShapes = _getPlaceableRotatedShapes();

    List<List<Offset>?> newShapes = List.generate(3, (_) {
      return _generateRandomRotatedShape();
    });

    if (placeableShapes.isNotEmpty && !_hasAnyPlaceableShape(newShapes)) {
      newShapes[_random.nextInt(newShapes.length)] =
          placeableShapes[_random.nextInt(placeableShapes.length)];
    }

    List<Color?> newColors = List.generate(
        3, (_) => blockColors[_random.nextInt(blockColors.length)]);

    activeShapes.assignAll(newShapes);
    activeColors.assignAll(newColors);
  }

  List<Offset> rotateBlock(List<Offset> shape, int rotationCount) {
    List<Offset> rotatedShape = List.from(shape);

    for (int i = 0; i < rotationCount; i++) {
      rotatedShape = rotatedShape.map((offset) {
        double translatedX = offset.dx - 1;
        double translatedY = offset.dy - 1;

        // 90 degree rotation
        double rotatedX = -translatedY;
        double rotatedY = translatedX;

        return Offset(rotatedX + 1, rotatedY + 1);
      }).toList();
    }
    return rotatedShape;
  }

  List<Offset> _generateRandomRotatedShape() {
    final List<Offset> baseShape =
        blockShapes[_random.nextInt(blockShapes.length)];
    final int rotationCount = _random.nextInt(rotationUnit);
    return rotateBlock(baseShape, rotationCount);
  }

  List<List<Offset>> _getPlaceableRotatedShapes() {
    final List<List<Offset>> placeableShapes = [];

    for (final shape in blockShapes) {
      for (int rotation = 0; rotation < rotationUnit; rotation++) {
        final rotatedShape = rotateBlock(shape, rotation);
        if (_canPlaceShapeAnywhere(rotatedShape)) {
          placeableShapes.add(rotatedShape);
        }
      }
    }

    return placeableShapes;
  }

  // Helper to validate placement positions matching placeBlock logic
  bool _canPlaceBlockAtCenter(
      List<Offset> blockShape, int centerRow, int centerCol,
      {Set<int> ignoredCells = const {}}) {
    for (var offset in blockShape) {
      int row = (centerRow - 1) + offset.dy.toInt();
      int col = (centerCol - 1) + offset.dx.toInt();

      if (row < 0 || row >= gridRows || col < 0 || col >= gridColumns) {
        return false;
      }

      final cellIndex = row * gridColumns + col;
      if (ignoredCells.contains(cellIndex)) {
        continue;
      }

      if (filledGrid[row][col] != -1) {
        return false;
      }
    }
    return true;
  }

  bool _canPlaceShapeAnywhere(List<Offset> blockShape,
      {Set<int> ignoredCells = const {}}) {
    const int padding = 4;

    for (int r = -padding; r < gridRows + padding; r++) {
      for (int c = -padding; c < gridColumns + padding; c++) {
        if (_canPlaceBlockAtCenter(blockShape, r, c,
            ignoredCells: ignoredCells)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasAnyPlaceableShape(Iterable<List<Offset>?> shapes,
      {Set<int> ignoredCells = const {}}) {
    for (final shape in shapes) {
      if (shape == null || shape.isEmpty) continue;

      if (_canPlaceShapeAnywhere(shape, ignoredCells: ignoredCells)) {
        return true;
      }
    }

    return false;
  }

  bool _canPlaceAnyActiveBlock({Set<int> ignoredCells = const {}}) {
    // Continue only needs one playable block, not every active block.
    return _hasAnyPlaceableShape(activeShapes, ignoredCells: ignoredCells);
  }

  void updateHover(
      int centerRow, int centerCol, List<Offset> shape, Color color) {
    List<int> newHoverCells = [];
    bool isWithinBounds = true;
    bool canPlace = true;

    for (Offset offset in shape) {
      int row = (centerRow - 1) + offset.dy.toInt();
      int col = (centerCol - 1) + offset.dx.toInt();
      int cellIndex = row * gridColumns + col;

      if (row < 0 || row >= gridRows || col < 0 || col >= gridColumns) {
        isWithinBounds = false;
        break;
      }

      if (droppedBlockPositions.contains(cellIndex)) {
        canPlace = false;
        break;
      }
      newHoverCells.add(cellIndex);
    }

    if (isWithinBounds && canPlace) {
      // Check if hover cells changed to trigger update and haptic
      // We convert to string for simple comparison, but checking list content equality is better
      // However, for performance and simplicity in this context:
      bool changed = false;
      if (hoverCells.length != newHoverCells.length) {
        changed = true;
      } else {
        for (int i = 0; i < newHoverCells.length; i++) {
          if (hoverCells[i] != newHoverCells[i]) {
            changed = true;
            break;
          }
        }
      }

      if (changed) {
        hoverCells.assignAll(newHoverCells);
        hoverColor.value = color.withValues(alpha: 0.5);
      }
    } else {
      clearHover();
    }
  }

  void clearHover() {
    if (hoverCells.isNotEmpty) {
      hoverCells.clear();
      hoverColor.value = null;
    }
  }

  void placeBlock(int centerRow, int centerCol, int blockIndex) {
    clearHover();

    if (blockIndex < 0 || blockIndex >= activeShapes.length) return;
    List<Offset>? shape = activeShapes[blockIndex];
    if (shape == null) return;

    // Validate placement
    bool isWithinBounds = true;
    bool canPlace = true;

    List<Offset> positionsToFill = [];

    for (Offset offset in shape) {
      int row = (centerRow - 1) + offset.dy.toInt();
      int col = (centerCol - 1) + offset.dx.toInt();
      int cellIndex = row * gridColumns + col;

      if (row < 0 || row >= gridRows || col < 0 || col >= gridColumns) {
        isWithinBounds = false;
        break;
      }

      if (filledGrid[row][col] != -1) {
        // Check filled grid directly
        canPlace = false;
        break;
      }
      // Or check droppedBlockPositions
      if (droppedBlockPositions.contains(cellIndex)) {
        canPlace = false;
        break;
      }

      positionsToFill.add(Offset(col.toDouble(), row.toDouble()));
    }

    if (isWithinBounds && canPlace) {
      if (settingsService.isHapticsOn.value) HapticFeedback.selectionClick();

      // Update Grid
      for (var pos in positionsToFill) {
        int col = pos.dx.toInt();
        int row = pos.dy.toInt();
        int cellIndex = row * gridColumns + col;

        droppedBlockPositions.add(cellIndex);
        filledGrid[row][col] =
            activeColors[blockIndex]!.toARGB32(); // Store color value
      }
      filledGrid.refresh(); // Notify observers

      lastPlacedCells.assignAll(positionsToFill
          .map((p) => p.dy.toInt() * gridColumns + p.dx.toInt())
          .toList());

      // Clear after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        lastPlacedCells.clear();
      });

      // Calculate score and show floating feedback
      int placementPoints = shape.length;
      scoreController.incrementBlockScore(placementPoints);

      // Calculate center for floating score
      double avgRow = 0;
      double avgCol = 0;
      for (var pos in positionsToFill) {
        avgRow += pos.dy;
        avgCol += pos.dx;
      }
      avgRow /= positionsToFill.length;
      avgCol /= positionsToFill.length;

      _addFloatingScore(Offset(avgCol, avgRow), "+$placementPoints");

      _checkAndClearRegions(positionsToFill, Offset(avgCol, avgRow));

      activeShapes[blockIndex] = null;
      activeColors[blockIndex] = null;
      activeShapes.refresh(); // Update UI

      if (activeShapes.every((s) => s == null)) {
        generateNewBlocks();
      }

      saveGameState();

      if (!_canPlaceAnyActiveBlock()) {
        // Add a small delay for UX so user sees the board state/new blocks
        Future.delayed(const Duration(milliseconds: 500), () {
          // Check again in case state changed (unlikely but safe)
          if (!_canPlaceAnyActiveBlock() && !isGameOver.value) {
            gameOver();
          }
        });
      }
    }
  }

  void _addFloatingScore(Offset gridPos, String message,
      {Color color = charcoalBlack,
      bool isLarge = false,
      Duration delay = Duration.zero}) {
    Future.delayed(delay, () {
      final String id = DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString();
      floatingScores.add(FloatingScore(
        position: gridPos,
        message: message,
        id: id,
        color: color,
        isLarge: isLarge,
      ));

      // Remove after animation
      Future.delayed(const Duration(milliseconds: 1500), () {
        floatingScores.removeWhere((fs) => fs.id == id);
      });
    });
  }

  void _checkAndClearRegions(
      List<Offset> placedPositions, Offset lastPlacementPos) {
    // 1. Identify which regions were touched by the new block
    Set<int> touchedRegions = {};
    for (var pos in placedPositions) {
      touchedRegions.add(regionGrid[pos.dy.toInt()][pos.dx.toInt()]);
    }

    List<int> filledRegions = [];

    // 2. Only for touched regions, check if they are now fully filled
    // We still need to know the total size of each region.
    // Optimization: This could be pre-calculated, but scanning 81 cells once is fine.
    Map<int, int> filledCounts = {};
    Map<int, int> totalCounts = {};

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        int region = regionGrid[row][col];
        totalCounts[region] = (totalCounts[region] ?? 0) + 1;
        if (filledGrid[row][col] != -1) {
          filledCounts[region] = (filledCounts[region] ?? 0) + 1;
        }
      }
    }

    for (var region in touchedRegions) {
      if (filledCounts[region] == totalCounts[region]) {
        filledRegions.add(region);
      }
    }

    if (filledRegions.isNotEmpty) {
      int clearedCells = 0;
      List<int> cellsToRemove = [];

      // Only iterate the grid once to find all cells belonging to filled regions
      for (int row = 0; row < gridRows; row++) {
        for (int col = 0; col < gridColumns; col++) {
          int region = regionGrid[row][col];
          if (filledRegions.contains(region)) {
            filledGrid[row][col] = -1;
            int cellIndex = row * gridColumns + col;
            cellsToRemove.add(cellIndex);
            clearedCells++;
          }
        }
      }

      droppedBlockPositions
          .removeWhere((index) => cellsToRemove.contains(index));

      // Notify FX
      lastClearedCells.assignAll(cellsToRemove);
      filledGrid.refresh();

      // Clear after animation
      Future.delayed(const Duration(milliseconds: 800), () {
        lastClearedCells.clear();
      });

      int multiplier = filledRegions.length;
      int baseScorePerCell = 10;
      int totalPoints = (clearedCells * baseScorePerCell) * multiplier;

      // Simple feedback: Just show the total score with the multiplier info if applicable
      String message = "+$totalPoints";
      if (multiplier > 1) {
        int basePoints = clearedCells * baseScorePerCell;
        message = "+$basePoints x$multiplier";
      }

      _addFloatingScore(lastPlacementPos, message,
          color: Colors.green, delay: const Duration(milliseconds: 400));

      scoreController.addClearScore(clearedCells, multiplier);
      currentCombo.value = multiplier;
      if (settingsService.isHapticsOn.value) HapticFeedback.mediumImpact();
    } else {
      currentCombo.value = 1;
    }
  }

  Future<void> restartGame() async {
    await _checkTrackingPermission();
    resetGame();
  }

  Future<ContinueResult> continueAfterRewardAd() async {
    if (hasUsedContinueThisGame.value) {
      return ContinueResult.alreadyUsed;
    }

    final int? targetRegion = _findBestRegionToClearForContinue();
    if (targetRegion == null) {
      return ContinueResult.noValidRegion;
    }

    final adService = Get.find<AdService>();
    final completer = Completer<ContinueResult>();
    bool rewardEarned = false;

    final didShowAd = adService.showRewardedAd(
      onUserEarnedReward: () {
        rewardEarned = true;
      },
      onAdDismissed: () {
        if (rewardEarned) {
          _clearRegionForContinue(targetRegion);
          if (!completer.isCompleted) {
            completer.complete(ContinueResult.success);
          }
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(ContinueResult.adNotCompleted);
        }
      },
      onAdUnavailable: () {
        if (!completer.isCompleted) {
          completer.complete(ContinueResult.adUnavailable);
        }
      },
    );

    if (!didShowAd) {
      return ContinueResult.adUnavailable;
    }

    return completer.future;
  }

  int? _findBestRegionToClearForContinue() {
    final Map<int, int> totalCounts = {};
    final Map<int, List<int>> occupiedCellsByRegion = {};

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        final int region = regionGrid[row][col];
        totalCounts[region] = (totalCounts[region] ?? 0) + 1;

        if (filledGrid[row][col] == -1) continue;

        occupiedCellsByRegion.putIfAbsent(region, () => []);
        occupiedCellsByRegion[region]!.add(row * gridColumns + col);
      }
    }

    final List<int> candidates = occupiedCellsByRegion.keys.where((region) {
      return _canPlaceAnyActiveBlock(
        ignoredCells: occupiedCellsByRegion[region]!.toSet(),
      );
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final double fillRatioA =
          occupiedCellsByRegion[a]!.length / (totalCounts[a] ?? 1);
      final double fillRatioB =
          occupiedCellsByRegion[b]!.length / (totalCounts[b] ?? 1);

      final int ratioCompare = fillRatioB.compareTo(fillRatioA);
      if (ratioCompare != 0) return ratioCompare;

      final int occupiedCompare = occupiedCellsByRegion[b]!
          .length
          .compareTo(occupiedCellsByRegion[a]!.length);
      if (occupiedCompare != 0) return occupiedCompare;

      return a.compareTo(b);
    });

    return candidates.first;
  }

  void _clearRegionForContinue(int region) {
    final List<int> clearedCells = [];

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        if (regionGrid[row][col] != region || filledGrid[row][col] == -1) {
          continue;
        }

        final int cellIndex = row * gridColumns + col;
        filledGrid[row][col] = -1;
        clearedCells.add(cellIndex);
      }
    }

    if (clearedCells.isEmpty) {
      return;
    }

    droppedBlockPositions.removeWhere((index) => clearedCells.contains(index));
    lastClearedCells.assignAll(clearedCells);
    filledGrid.refresh();
    isGameOver.value = false;
    currentCombo.value = 1;
    hasUsedContinueThisGame.value = true;

    Future.delayed(const Duration(milliseconds: 800), () {
      lastClearedCells.clear();
    });

    saveGameState();
  }

  void gameOver() {
    isGameOver.value = true;
    scoreController.checkHighScore();
    scoreController.uploadHighScoreToServer(); // Upload once at game over
    clearSavedGame();
    if (settingsService.isHapticsOn.value) {
      HapticFeedback.vibrate(); // Noticeable feedback for game over
    }

    final adService = Get.find<AdService>();
    final bool canContinue = adService.hasRewardedAdConfigured &&
        !hasUsedContinueThisGame.value &&
        _findBestRegionToClearForContinue() != null;

    Get.dialog(
      GameOverDialog(
        onRestart: () {
          Get.back(); // Close dialog
          restartGame();
        },
        onContinue: canContinue ? continueAfterRewardAd : null,
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
    );
  }

  Future<void> _checkTrackingPermission() async {
    try {
      final TrackingStatus status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Wait for a moment to ensure user has context
        await Future.delayed(const Duration(milliseconds: 500));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('Error requesting tracking transparency: $e');
    }
  }
}
