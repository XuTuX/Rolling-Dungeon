import 'dart:math';

import '../constant.dart';
import 'package:circle_war/services/auth_service.dart';
import 'package:circle_war/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreController extends GetxController {
  var score = 0.obs;
  var highscore = 0.obs;
  var isSyncing = false.obs;
  var hasNewHighScoreThisGame = false.obs;

  // Separate scores
  var blockScore = 0.obs;
  var regionScore = 0.obs;

  var combo = 0.obs;
  var lastIncrement = 0.obs;
  var showIncrement = false.obs;

  /// Current logged-in user ID (null = guest)
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();

    // Check initial auth state
    final authService = Get.find<AuthService>();
    final currentUser = authService.user.value;
    if (currentUser != null) {
      _currentUserId = currentUser.id;
    }

    _loadHighScore();

    // Watch auth state changes immediately (removed debounce for better UX)
    ever(authService.user, (user) {
      if (user != null) {
        _onUserLogin(user.id);
      } else {
        _onUserLogout();
      }
    });
  }

  // --- Score Key Management ---

  /// Returns the SharedPreferences key for the current user's high score
  String get _scoreKey {
    if (_currentUserId != null) {
      return 'high_score_$_currentUserId';
    }
    return 'high_score_guest';
  }

  // --- Auth State Handlers ---

  Future<void> _onUserLogin(String userId) async {
    isSyncing.value = true;
    hasNewHighScoreThisGame.value = false;
    _currentUserId = userId;

    final prefs = await SharedPreferences.getInstance();

    // Load this user's existing local score (from previous sessions)
    final userLocalScore = prefs.getInt('high_score_$userId') ?? 0;

    // --- Legacy Migration (v1.0 'high_score' → user-specific key) ---
    final legacyScore = prefs.getInt('high_score') ?? 0;

    // Check if guest score should be merged (one-time per user)
    final guestMerged = prefs.getBool('guest_merged_$userId') ?? false;
    final guestScore = prefs.getInt('high_score_guest') ?? 0;

    int bestLocalScore = max(userLocalScore, legacyScore);

    if (!guestMerged && guestScore > 0) {
      // First login on this device: take the higher of guest vs user local vs legacy
      bestLocalScore = max(bestLocalScore, guestScore);
      debugPrint(
          '🔵 [ScoreController] Merging guest score ($guestScore) with user score ($userLocalScore) / legacy ($legacyScore) → $bestLocalScore');

      // Mark merge complete & clear guest score
      await prefs.setBool('guest_merged_$userId', true);
      await prefs.setInt('high_score_guest', 0);
    }

    // Clear legacy key after migration to avoid re-processing
    if (legacyScore > 0) {
      await prefs.remove('high_score');
      debugPrint(
          '🔵 [ScoreController] Legacy score ($legacyScore) migrated and cleared.');
    }

    // Save user-specific local score
    highscore.value = bestLocalScore;
    await prefs.setInt('high_score_$userId', bestLocalScore);

    // Sync with server
    await _syncWithOnlineScore(bestLocalScore);
    isSyncing.value = false;
  }

  /// Called when a user logs out.
  /// Switches back to guest score storage (starts fresh).
  Future<void> _onUserLogout() async {
    isSyncing.value = true;
    hasNewHighScoreThisGame.value = false;
    _currentUserId = null;

    final prefs = await SharedPreferences.getInstance();
    final guestScore = prefs.getInt('high_score_guest') ?? 0;
    highscore.value = guestScore;

    debugPrint(
        '🔵 [ScoreController] Switched to guest mode. Guest score: $guestScore');
    isSyncing.value = false;
  }

  // --- Server Sync ---

  /// Syncs local score with the server.
  /// Takes the higher of local vs server and updates both sides.
  Future<void> _syncWithOnlineScore(int localScore) async {
    try {
      debugPrint('🔵 [ScoreController] Starting score sync...');

      final dbService = Get.find<DatabaseService>();
      final onlineBest = await dbService.getMyBestScore(gameId);

      if (onlineBest != null && onlineBest > localScore) {
        // Server score is higher → update local
        highscore.value = onlineBest;
        await _saveHighScore(onlineBest);
        debugPrint(
            '🟢 [ScoreController] Synced: server ($onlineBest) > local ($localScore). Updated local.');
      } else if (localScore > (onlineBest ?? 0)) {
        // Local score is higher → upload to server
        await dbService.saveScore(gameId, localScore);
        await _saveHighScore(localScore);
        debugPrint(
            '🟢 [ScoreController] Synced: local ($localScore) > server (${onlineBest ?? 0}). Uploaded.');
      } else {
        debugPrint('🟢 [ScoreController] Scores already in sync ($localScore)');
      }
    } catch (e) {
      debugPrint('🔴 [ScoreController] Online score sync failed: $e');
    }
  }

  // --- Scoring Logic ---

  void addClearScore(int clearedCells, int multiplier) {
    if (clearedCells > 0) {
      int basePoints = clearedCells * 10;
      int points = basePoints * multiplier;

      regionScore.value += points;
      score.value += points;

      lastIncrement.value = points;
      showIncrement.value = true;
      Future.delayed(const Duration(seconds: 1), () {
        showIncrement.value = false;
      });
    }
    checkHighScore();
  }

  void incrementBlockScore(int points) {
    blockScore.value += points;
    score.value += points;

    lastIncrement.value = points;
    showIncrement.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      showIncrement.value = false;
    });
    checkHighScore();
  }

  void resetScore() {
    score.value = 0;
    blockScore.value = 0;
    regionScore.value = 0;
    combo.value = 0;
    hasNewHighScoreThisGame.value = false;
  }

  void checkHighScore() async {
    if (score.value > highscore.value) {
      highscore.value = score.value;
      hasNewHighScoreThisGame.value = true;
      await _saveHighScore(highscore.value);
    }
  }

  /// Uploads the current high score to Supabase.
  /// Called at game over and when opening the ranking tab.
  Future<void> uploadHighScoreToServer() async {
    if (_currentUserId == null) return; // Guest — skip
    try {
      final dbService = Get.find<DatabaseService>();
      await dbService.saveScore(gameId, highscore.value);
      debugPrint(
          '🟢 [ScoreController] High score uploaded: ${highscore.value}');
    } catch (e) {
      debugPrint('🔴 [ScoreController] High score upload failed: $e');
    }
  }

  /// Syncs local high score with server when opening ranking tab.
  /// Takes the higher of local vs server and updates both sides.
  Future<void> syncScoreForRanking() async {
    if (_currentUserId == null) return;
    await _syncWithOnlineScore(highscore.value);
  }

  // --- Persistence ---

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    int storedScore = prefs.getInt(_scoreKey) ?? 0;

    // --- Legacy Migration (v1.0 'high_score' -> v2.0 'high_score_guest') ---
    // If we are in guest mode, check if there's an old version score that is higher
    if (_currentUserId == null) {
      final legacyScore = prefs.getInt('high_score') ?? 0;
      if (legacyScore > storedScore) {
        debugPrint(
            '🔵 [ScoreController] Legacy score ($legacyScore) > guest score ($storedScore). Migrating...');
        storedScore = legacyScore;
        await prefs.setInt('high_score_guest', storedScore);
      }
      // Clear legacy key after migration
      if (legacyScore > 0) {
        await prefs.remove('high_score');
      }
    }

    highscore.value = storedScore;
    hasNewHighScoreThisGame.value = false;
  }
}
