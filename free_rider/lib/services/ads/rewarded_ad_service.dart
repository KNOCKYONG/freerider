import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 리워드 비디오 광고 서비스
/// 고수익 광고를 통한 포인트 적립 시스템
class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // 광고 단가 (포인트)
  static const int standardRewardPoints = 100;  // 일반 리워드 광고
  static const int premiumRewardPoints = 150;   // 프리미엄 광고
  static const int interactiveRewardPoints = 200; // 인터랙티브 광고

  // 일일 시청 제한
  static const int dailyStandardLimit = 10;
  static const int dailyPremiumLimit = 5;
  static const int dailyInteractiveLimit = 3;

  // 광고 ID (실제 배포 시 AdMob 콘솔에서 발급받은 ID 사용)
  static const String _rewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917' // 테스트 광고 ID
      : 'ca-app-pub-XXXXXXXXXXXXX/XXXXXXXXXX'; // 실제 광고 ID

  // 광고 인스턴스
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  
  // 광고 로드 상태
  bool _isRewardedAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  
  // 시청 기록
  final Map<String, int> _dailyWatchCount = {
    'standard': 0,
    'premium': 0,
    'interactive': 0,
  };
  
  DateTime _lastResetDate = DateTime.now();
  
  // 콜백
  Function(int points)? _onUserEarnedReward;
  Function(String error)? _onAdFailedToLoad;
  Function()? _onAdDismissed;

  /// 광고 서비스 초기화
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _resetDailyCountIfNeeded();
    await loadRewardedAd();
  }

  /// 일일 시청 횟수 리셋
  void _resetDailyCountIfNeeded() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day) {
      _dailyWatchCount.forEach((key, value) {
        _dailyWatchCount[key] = 0;
      });
      _lastResetDate = now;
    }
  }

  /// 리워드 광고 로드
  Future<void> loadRewardedAd() async {
    _resetDailyCountIfNeeded();
    
    if (_isRewardedAdLoaded) return;
    
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _setupAdCallbacks(ad);
          debugPrint('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          debugPrint('Failed to load rewarded ad: ${error.message}');
          _onAdFailedToLoad?.call(error.message);
        },
      ),
    );
  }

  /// 프리미엄 리워드 광고 로드
  Future<void> loadPremiumRewardedAd() async {
    if (_isInterstitialAdLoaded) return;
    
    await RewardedInterstitialAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _setupInterstitialAdCallbacks(ad);
          debugPrint('Premium rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          debugPrint('Failed to load premium ad: ${error.message}');
          _onAdFailedToLoad?.call(error.message);
        },
      ),
    );
  }

  /// 광고 콜백 설정
  void _setupAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed');
        _onAdDismissed?.call();
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Failed to show rewarded ad: ${error.message}');
        ad.dispose();
        _isRewardedAdLoaded = false;
      },
    );
  }

  /// 인터스티셜 광고 콜백 설정
  void _setupInterstitialAdCallbacks(RewardedInterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Premium ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Premium ad dismissed');
        _onAdDismissed?.call();
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadPremiumRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Failed to show premium ad: ${error.message}');
        ad.dispose();
        _isInterstitialAdLoaded = false;
      },
    );
  }

  /// 표준 리워드 광고 표시
  Future<bool> showStandardRewardedAd({
    required Function(int points) onUserEarnedReward,
    Function(String error)? onError,
    Function()? onAdDismissed,
  }) async {
    _resetDailyCountIfNeeded();
    
    // 일일 한도 체크
    if (_dailyWatchCount['standard']! >= dailyStandardLimit) {
      onError?.call('일일 시청 한도를 초과했습니다');
      return false;
    }
    
    _onUserEarnedReward = onUserEarnedReward;
    _onAdFailedToLoad = onError;
    _onAdDismissed = onAdDismissed;
    
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      await loadRewardedAd();
      if (!_isRewardedAdLoaded) {
        onError?.call('광고를 불러올 수 없습니다');
        return false;
      }
    }
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _dailyWatchCount['standard'] = _dailyWatchCount['standard']! + 1;
        onUserEarnedReward(standardRewardPoints);
        debugPrint('User earned $standardRewardPoints points');
      },
    );
    
    return true;
  }

  /// 프리미엄 리워드 광고 표시
  Future<bool> showPremiumRewardedAd({
    required Function(int points) onUserEarnedReward,
    Function(String error)? onError,
    Function()? onAdDismissed,
  }) async {
    _resetDailyCountIfNeeded();
    
    // 일일 한도 체크
    if (_dailyWatchCount['premium']! >= dailyPremiumLimit) {
      onError?.call('프리미엄 광고 일일 한도를 초과했습니다');
      return false;
    }
    
    _onUserEarnedReward = onUserEarnedReward;
    _onAdFailedToLoad = onError;
    _onAdDismissed = onAdDismissed;
    
    if (!_isInterstitialAdLoaded || _rewardedInterstitialAd == null) {
      await loadPremiumRewardedAd();
      if (!_isInterstitialAdLoaded) {
        onError?.call('프리미엄 광고를 불러올 수 없습니다');
        return false;
      }
    }
    
    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        _dailyWatchCount['premium'] = _dailyWatchCount['premium']! + 1;
        onUserEarnedReward(premiumRewardPoints);
        debugPrint('User earned $premiumRewardPoints premium points');
      },
    );
    
    return true;
  }

  /// 남은 광고 시청 횟수 조회
  Map<String, int> getRemainingAds() {
    _resetDailyCountIfNeeded();
    return {
      'standard': dailyStandardLimit - _dailyWatchCount['standard']!,
      'premium': dailyPremiumLimit - _dailyWatchCount['premium']!,
      'interactive': dailyInteractiveLimit - _dailyWatchCount['interactive']!,
    };
  }

  /// 오늘 획득한 포인트
  int getTodayEarnedPoints() {
    return (_dailyWatchCount['standard']! * standardRewardPoints) +
           (_dailyWatchCount['premium']! * premiumRewardPoints) +
           (_dailyWatchCount['interactive']! * interactiveRewardPoints);
  }

  /// 광고 로드 상태 확인
  bool get isStandardAdReady => _isRewardedAdLoaded;
  bool get isPremiumAdReady => _isInterstitialAdLoaded;

  /// 일일 한도 도달 여부
  bool get hasReachedDailyLimit {
    _resetDailyCountIfNeeded();
    return _dailyWatchCount['standard']! >= dailyStandardLimit &&
           _dailyWatchCount['premium']! >= dailyPremiumLimit &&
           _dailyWatchCount['interactive']! >= dailyInteractiveLimit;
  }

  /// 리소스 정리
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
    _isRewardedAdLoaded = false;
    _isInterstitialAdLoaded = false;
  }
}

/// 광고 타입
enum AdType {
  standard,
  premium,
  interactive,
}

/// 광고 보상 정보
class AdReward {
  final AdType type;
  final int points;
  final DateTime earnedAt;
  final String? adId;

  AdReward({
    required this.type,
    required this.points,
    required this.earnedAt,
    this.adId,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'points': points,
    'earnedAt': earnedAt.toIso8601String(),
    'adId': adId,
  };
}