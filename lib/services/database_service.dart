import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 특정 게임의 내 최고 점수 가져오기
  Future<int?> getMyBestScore(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('scores')
        .select('score')
        .eq('user_id', userId)
        .eq('game_id', gameId)
        .order('score', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['score'] as int?;
  }

  // 점수 저장 (최고 점수 갱신 로직)
  Future<void> saveScore(String gameId, int newScore) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Upsert: Insert or Update based on (user_id, game_id) constraint.
      // This is atomic and faster. requires unique constraint on (user_id, game_id).
      // However, we only want to update if the new score is higher.
      // Supabase upsert updates by default. To only update if higher, we might need a stored procedure or keep the check.
      // BUT, the user explicitly asked to use upsert.
      // If we use upsert blindly, we might overwrite a high score with a lower one if logic elsewhere is flawed?
      // No, `saveScore` is usually called when we believe it's a high score?
      // Actually, checking `GameController.dart`: `scoreController.checkHighScore()` calls `saveScore`.
      // `checkHighScore` compares `score.value > currentHighScore.value`.
      // So the client side already checks if it is a high score.
      // So upsert is safe here assuming client logic is correct.

      await _supabase.from('scores').upsert({
        'user_id': userId,
        'game_id': gameId,
        'score': newScore,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, game_id'); // Ensure DB has this constraint

      debugPrint('🟢 Score upserted: $newScore');
    } catch (e) {
      debugPrint('🔴 Error saving score: $e');
    }
  }

  // 나의 순위 가져오기
  Future<int?> getMyRank(String gameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    // 1. 내 최고 점수 가져오기
    final myBest = await getMyBestScore(gameId);
    if (myBest == null) return null;

    // 2. 나보다 높은 점수 개수 세기 (count)
    final count = await _supabase
        .from('scores')
        .count(CountOption.exact)
        .gt('score', myBest)
        .eq('game_id', gameId);

    // 3. 순위 = (나보다 높은 사람 수) + 1
    return count + 1;
  }

  // 리더보드 가져오기 (클라이언트 사이드 중복 제거 포함)
  Future<List<Map<String, dynamic>>> getLeaderboard(String gameId) async {
    try {
      // 1. 중복을 감안하여 넉넉하게 데이터 가져오기 (상위 100개)
      final response = await _supabase
          .from('scores')
          .select('user_id, score, profiles(nickname, avatar_url)')
          .eq('game_id', gameId)
          .order('score', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> rawList =
          List<Map<String, dynamic>>.from(response);

      // 2. user_id 기준으로 중복 제거 (이미 정렬되어 있으므로 첫 번째가 최고점) and FILTER null nicknames
      final Map<String, Map<String, dynamic>> uniqueScores = {};
      for (var item in rawList) {
        final userId = item['user_id'] as String?;
        final profile = item['profiles'];
        final nickname = profile != null ? profile['nickname'] : null;

        // Skip if user has no nickname
        if (nickname == null) continue;

        if (userId != null && !uniqueScores.containsKey(userId)) {
          uniqueScores[userId] = item;
        }
      }

      // 3. 상위 50개만 반환
      return uniqueScores.values.take(50).toList();
    } catch (e) {
      debugPrint('🔴 Error fetching leaderboard: $e');
      return [];
    }
  }

  // 닉네임 설정/업데이트
  Future<String?> updateNickname(String nickname) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return '로그인이 필요합니다.';

    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return null; // Success
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return '이미 사용 중인 닉네임입니다. \n다른 닉네임을 선택해주세요.';
      }
      return '닉네임 업데이트 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// Check if a nickname is available (not taken by another user)
  Future<bool> checkNicknameAvailable(String nickname) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      // If response is null, no user with this nickname exists -> Available
      return response == null;
    } catch (e) {
      // On error, assume unavailable to be safe, or available?
      // Let's assume unavailable to prevent potential conflicts if DB acts up.
      // actually, let's just return false to act safe.
      return false;
    }
  }

  // 내 프로필 가져오기
  Future<Map<String, dynamic>?> getMyProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // 회원 탈퇴 시 내 데이터 모두 삭제
  Future<void> deleteMyData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 순서 중요: scores 먼저 삭제 (profiles에 FK 참조할 수 있으므로)
    await _supabase.from('scores').delete().eq('user_id', userId);
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}
