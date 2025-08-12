import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../models/ad_model.dart';

// Ad State Provider
final adStateProvider = StateNotifierProvider<AdNotifier, AdState>((ref) {
  return AdNotifier();
});

// Available Ads Provider
final availableAdsProvider = Provider<List<AdModel>>((ref) {
  final state = ref.watch(adStateProvider);
  
  // Mock ads data
  final allAds = [
    AdModel(
      id: 'ad_001',
      title: '차량 보험 할인',
      advertiser: 'KB손해보험',
      description: 'KB다이렉트 자동차보험 최대 30% 할인',
      duration: 30,
      points: AppConstants.pointsPerAd,
      type: AdType.video,
      color: AppColors.subwayBlue,
    ),
    AdModel(
      id: 'ad_002',
      title: '신규 카페 오픈',
      advertiser: '스타벅스',
      description: '강남역 신규 매장 오픈 이벤트',
      duration: 30,
      points: AppConstants.pointsPerAd,
      type: AdType.video,
      color: AppColors.primaryGreen,
    ),
    AdModel(
      id: 'ad_003',
      title: '온라인 쇼핑 할인',
      advertiser: '쿠팡',
      description: '와우 회원 전용 특가 할인',
      duration: 30,
      points: AppConstants.pointsPerAd,
      type: AdType.video,
      color: AppColors.rewardOrange,
    ),
    AdModel(
      id: 'ad_004',
      title: '통신사 요금제',
      advertiser: 'SK텔레콤',
      description: '5G 요금제 첫 달 무료',
      duration: 30,
      points: AppConstants.pointsPerAd,
      type: AdType.video,
      color: AppColors.movementColor,
    ),
    AdModel(
      id: 'ad_005',
      title: '금융 상품',
      advertiser: '카카오뱅크',
      description: '체크카드 출시 기념 이벤트',
      duration: 30,
      points: AppConstants.pointsPerAd,
      type: AdType.video,
      color: AppColors.visualColor,
    ),
  ];
  
  // Filter out already watched ads
  return allAds.where((ad) => !state.watchedAdIds.contains(ad.id)).toList();
});

class AdState {
  final int todayPoints;
  final int watchedCount;
  final Set<String> watchedAdIds;
  final List<AdWatchRecord> watchHistory;
  final DateTime lastWatchedAt;

  AdState({
    this.todayPoints = 0,
    this.watchedCount = 0,
    Set<String>? watchedAdIds,
    List<AdWatchRecord>? watchHistory,
    DateTime? lastWatchedAt,
  }) : watchedAdIds = watchedAdIds ?? {},
       watchHistory = watchHistory ?? [],
       lastWatchedAt = lastWatchedAt ?? DateTime.now();

  AdState copyWith({
    int? todayPoints,
    int? watchedCount,
    Set<String>? watchedAdIds,
    List<AdWatchRecord>? watchHistory,
    DateTime? lastWatchedAt,
  }) {
    return AdState(
      todayPoints: todayPoints ?? this.todayPoints,
      watchedCount: watchedCount ?? this.watchedCount,
      watchedAdIds: watchedAdIds ?? this.watchedAdIds,
      watchHistory: watchHistory ?? this.watchHistory,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }

  bool get canWatchMoreAds => watchedCount < AppConstants.adDailyLimit;
}

class AdNotifier extends StateNotifier<AdState> {
  AdNotifier() : super(AdState());

  void completeAd(String adId) {
    if (state.watchedAdIds.contains(adId)) return;
    if (!state.canWatchMoreAds) return;
    
    final record = AdWatchRecord(
      adId: adId,
      watchedAt: DateTime.now(),
      pointsEarned: AppConstants.pointsPerAd,
      completed: true,
    );
    
    state = state.copyWith(
      todayPoints: state.todayPoints + AppConstants.pointsPerAd,
      watchedCount: state.watchedCount + 1,
      watchedAdIds: {...state.watchedAdIds, adId},
      watchHistory: [...state.watchHistory, record],
      lastWatchedAt: DateTime.now(),
    );
  }

  void skipAd(String adId) {
    final record = AdWatchRecord(
      adId: adId,
      watchedAt: DateTime.now(),
      pointsEarned: 0,
      completed: false,
    );
    
    state = state.copyWith(
      watchHistory: [...state.watchHistory, record],
      lastWatchedAt: DateTime.now(),
    );
  }

  void resetDaily() {
    state = AdState();
  }

  int getRemainingAds() {
    return AppConstants.adDailyLimit - state.watchedCount;
  }

  bool hasWatchedAd(String adId) {
    return state.watchedAdIds.contains(adId);
  }
}