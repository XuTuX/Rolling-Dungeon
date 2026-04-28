import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circle_war/config/app_config.dart';
import 'package:circle_war/controllers/game_controller.dart';
import 'package:circle_war/services/database_service.dart';
import 'package:circle_war/utils/random_nickname_generator.dart';

class AuthService extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var user = Rxn<User>();
  var isLoading = false.obs;
  var loginSuccess = false.obs;
  var userNickname = RxnString();
  var isProfileLoaded = false.obs;
  var hasProfileLoadError = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _supabase.auth.currentUser;
    isProfileLoaded.value = user.value == null;
    hasProfileLoadError.value = false;

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      user.value = data.session?.user;

      // Handle token refresh events
      if (data.event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔵 [AuthService] Token refreshed successfully');
      }

      // If user logs in/out, update nickname accordingly
      if (user.value != null) {
        fetchUserProfile();
      } else {
        userNickname.value = null;
        hasProfileLoadError.value = false;
        isProfileLoaded.value = true;
      }
    });

    // Try to recover / refresh session on startup
    _tryRecoverSession();
  }

  /// Fetch the current user's profile including nickname
  Future<void> fetchUserProfile() async {
    isProfileLoaded.value = false;
    hasProfileLoadError.value = false;
    try {
      // Ensure we have a user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        isProfileLoaded.value = true;
        return;
      }

      final dbService = Get.find<DatabaseService>();

      // Try to fetch profile
      var profile = await dbService.getMyProfile();

      // If profile is not found, it might be a new user and the trigger is still running.
      // Wait a bit and try one more time.
      if (profile == null) {
        debugPrint('🟡 [AuthService] Profile not found, retrying in 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));
        profile = await dbService.getMyProfile();
      }

      if (profile != null) {
        if (profile['nickname'] != null) {
          userNickname.value = profile['nickname'];
          debugPrint(
              '🟢 [AuthService] Nickname fetched: ${userNickname.value}');
        } else {
          // Nickname is null -> Generate and Save automatically
          debugPrint(
              '🟡 [AuthService] Nickname is null, generating new one...');
          await _generateAndSaveRandomNickname();
        }
      } else {
        debugPrint('🟡 [AuthService] Profile still null after retry');
        userNickname.value = null;
      }

      // Mark as loaded only if we successfully checked/processed the profile
      hasProfileLoadError.value = false;
      isProfileLoaded.value = true;
      debugPrint(
          '🔵 [AuthService] Profile load/check finished. Nickname: ${userNickname.value}');
    } catch (e) {
      debugPrint('🔴 [AuthService] Failed to fetch profile: $e');
      hasProfileLoadError.value = true;
      isProfileLoaded.value = true;
    }
  }

  /// Generate a random nickname and save it to DB
  Future<void> _generateAndSaveRandomNickname() async {
    try {
      final dbService = Get.find<DatabaseService>();
      String candidate = '';
      bool available = false;
      int attempts = 0;

      // Try up to 5 times to find a unique nickname
      while (attempts < 5 && !available) {
        candidate = RandomNicknameGenerator.generate();
        available = await dbService.checkNicknameAvailable(candidate);
        attempts++;
      }

      if (available) {
        final error = await updateNickname(candidate);
        if (error == null) {
          debugPrint('🟢 [AuthService] Auto-assigned nickname: $candidate');
        } else {
          debugPrint('🔴 [AuthService] Failed to save auto nickname: $error');
        }
      } else {
        debugPrint(
            '🔴 [AuthService] Failed to generate unique nickname after retries');
      }
    } catch (e) {
      debugPrint('🔴 [AuthService] Error in auto nickname generation: $e');
    }
  }

  /// Update nickname both locally and in DB
  Future<String?> updateNickname(String newNickname) async {
    try {
      final dbService = Get.find<DatabaseService>();
      final error = await dbService.updateNickname(newNickname);
      if (error == null) {
        userNickname.value = newNickname;
      }
      return error;
    } catch (e) {
      return '업데이트 중 오류가 발생했습니다.';
    }
  }

  /// Attempt to recover the session on app launch.
  /// If the token is expired, Supabase SDK will attempt an automatic refresh.
  /// If that fails, sign the user out gracefully.
  Future<void> _tryRecoverSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      // Check if session is expired
      if (session.isExpired) {
        debugPrint('🟡 [AuthService] Session expired, attempting refresh...');
        try {
          await _supabase.auth.refreshSession();
          debugPrint('🟢 [AuthService] Session refreshed successfully');
        } catch (e) {
          debugPrint(
              '🔴 [AuthService] Session refresh failed, signing out: $e');
          await _supabase.auth.signOut();
          user.value = null;
        }
      } else {
        debugPrint('🟢 [AuthService] Valid session found on startup');
      }

      // Fetch profile after session recovery
      if (user.value != null) {
        fetchUserProfile();
      }
    } catch (e) {
      debugPrint('🔴 [AuthService] Session recovery error: $e');
    }
  }

  /// Returns null on success, or an error message string on failure.
  /// Returns 'cancelled' if user cancelled the operation.
  Future<String?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      debugPrint('🔵 [AuthService] Google Sign In process started');

      final webClientId = AppConfig.googleWebClientId;
      final iosClientId = AppConfig.googleIosClientId;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? iosClientId : null,
        serverClientId: webClientId,
      );

      debugPrint('🔵 [AuthService] Requesting Google Sign In...');
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('🟡 [AuthService] User cancelled Google Sign In');
        return 'cancelled';
      }

      debugPrint('🔵 [AuthService] Getting authentication tokens...');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      debugPrint('🔵 [AuthService] Signing in to Supabase...');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('🟢 [AuthService] Google Sign In Success!');
      _triggerLoginSuccess();

      // Fetch profile immediately after login
      await fetchUserProfile();

      return null; // success
    } catch (e) {
      debugPrint('🔴 [AuthService] Google Sign In Failed: $e');
      return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
    } finally {
      isLoading.value = false;
      debugPrint(
          '🔵 [AuthService] Login process finished. isLoading set to false.');
    }
  }

  /// Returns null on success, or an error message string on failure.
  /// Returns 'cancelled' if user cancelled the operation.
  Future<String?> signInWithApple() async {
    try {
      isLoading.value = true;
      debugPrint('🔵 [AuthService] Apple Sign In process started');

      // native Apple Sign In
      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      debugPrint('🔵 [AuthService] Requesting Apple ID Credential...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'Could not find ID Token from Apple.';
      }

      debugPrint('🔵 [AuthService] Signing in to Supabase...');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      debugPrint('🟢 [AuthService] Apple Sign In Success!');
      _triggerLoginSuccess();

      // Fetch profile immediately after login
      await fetchUserProfile();

      return null; // success
    } catch (e) {
      debugPrint('🔴 [AuthService] Apple Sign In Failed: $e');
      return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
    } finally {
      isLoading.value = false;
      debugPrint(
          '🔵 [AuthService] Login process finished. isLoading set to false.');
    }
  }

  /// Trigger a brief success animation state
  void _triggerLoginSuccess() {
    loginSuccess.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      loginSuccess.value = false;
    });
  }

  Future<void> signOut() async {
    // Clear saved game state so user starts fresh after logout
    try {
      final gameController = Get.find<GameController>();
      await gameController.clearSavedGame();
    } catch (_) {}

    await _supabase.auth.signOut();
    userNickname.value = null; // Clear nickname
  }

  /// Delete the user's account permanently.
  /// Deletes all user data from the database, then signs out.
  /// Returns null on success, or error message on failure.
  Future<String?> deleteAccount() async {
    try {
      isLoading.value = true;
      debugPrint('🔵 [AuthService] Account deletion started');
      final deletingUserId = _supabase.auth.currentUser?.id;

      // 1. Delete user data from DB while still authenticated (RLS requires auth)
      try {
        final dbService = Get.find<DatabaseService>();
        await dbService.deleteMyData();
        debugPrint('🟢 [AuthService] User data deleted from DB');
      } catch (e) {
        debugPrint('🔴 [AuthService] DB data deletion failed: $e');
        // Continue with sign out even if DB deletion fails
      }

      // 1.5 Clear saved game state
      try {
        final gameController = Get.find<GameController>();
        await gameController.clearSavedGame();
      } catch (_) {}

      // 1.6 Clear local score keys for this user
      if (deletingUserId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('high_score_$deletingUserId');
          await prefs.remove('guest_merged_$deletingUserId');
        } catch (_) {}
      }

      // 2. Sign out from Google / Apple
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}

      // 3. Sign out the Supabase session
      await _supabase.auth.signOut();
      user.value = null;
      userNickname.value = null;

      debugPrint('🟢 [AuthService] Account deletion completed');
      return null;
    } catch (e) {
      debugPrint('🔴 [AuthService] Account deletion failed: $e');
      return '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
    } finally {
      isLoading.value = false;
    }
  }
}
