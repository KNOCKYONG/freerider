import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/services/ads/rewarded_ad_service.dart';

void main() {
  group('RewardedAdService Tests', () {
    late RewardedAdService adService;

    setUp(() {
      adService = RewardedAdService();
    });

    test('서비스 싱글톤 인스턴스가 생성되어야 함', () {
      final service1 = RewardedAdService();
      final service2 = RewardedAdService();
      
      expect(identical(service1, service2), true);
    });

    test('일일 시청 한도가 올바르게 설정되어야 함', () {
      expect(RewardedAdService.dailyStandardLimit, 10);
      expect(RewardedAdService.dailyPremiumLimit, 5);
      expect(RewardedAdService.dailyInteractiveLimit, 3);
    });

    test('광고 포인트가 올바르게 설정되어야 함', () {
      expect(RewardedAdService.standardRewardPoints, 100);
      expect(RewardedAdService.premiumRewardPoints, 150);
      expect(RewardedAdService.interactiveRewardPoints, 200);
    });

    test('남은 광고 횟수가 정확히 계산되어야 함', () {
      final remaining = adService.getRemainingAds();
      
      expect(remaining['standard'], 10);
      expect(remaining['premium'], 5);
      expect(remaining['interactive'], 3);
    });

    test('오늘 획득한 포인트가 0으로 시작해야 함', () {
      final points = adService.getTodayEarnedPoints();
      expect(points, 0);
    });

    test('일일 한도 도달 여부가 false로 시작해야 함', () {
      expect(adService.hasReachedDailyLimit, false);
    });

    test('광고 로드 상태가 초기에 false여야 함', () {
      expect(adService.isStandardAdReady, false);
      expect(adService.isPremiumAdReady, false);
    });
  });
}