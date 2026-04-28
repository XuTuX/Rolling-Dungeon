import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdService extends GetxService {
  RewardedAd? _rewardedAd;
  bool _isLoadingRewardedAd = false;
  final RxBool isRewardedAdReady = false.obs;

  // Real Ad Unit IDs
  final String _androidRewardedId =
      'ca-app-pub-6309678653363025/3410787692';
  final String _iosRewardedId = 'ca-app-pub-6309678653363025/8196210518';

  // Test Ad Unit IDs
  final String _testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  final String _testIosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  String? get _rewardedAdUnitId {
    if (kReleaseMode) {
      final adUnitId =
          Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
      return adUnitId.isEmpty ? null : adUnitId;
    }

    return Platform.isAndroid ? _testAndroidRewardedId : _testIosRewardedId;
  }

  bool get hasRewardedAdConfigured => _rewardedAdUnitId != null;

  @override
  void onInit() {
    super.onInit();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    final rewardedAdUnitId = _rewardedAdUnitId;
    if (rewardedAdUnitId == null || _isLoadingRewardedAd || _rewardedAd != null) {
      return;
    }

    _isLoadingRewardedAd = true;
    isRewardedAdReady.value = false;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd loaded.');
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
          isRewardedAdReady.value = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isLoadingRewardedAd = false;
          isRewardedAdReady.value = false;
        },
      ),
    );
  }

  bool showRewardedAd({
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdDismissed,
    VoidCallback? onAdUnavailable,
  }) {
    if (_rewardedAd == null) {
      debugPrint('Warning: RewardedAd not ready, skipping.');
      onAdUnavailable?.call();
      loadRewardedAd();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed full screen content.');
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        onAdDismissed();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show full screen content: $error');
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        onAdDismissed();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        onUserEarnedReward();
      },
    );

    return true;
  }
}
