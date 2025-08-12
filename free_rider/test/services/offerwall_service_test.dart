import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/services/ads/offerwall_service.dart';

void main() {
  group('OfferwallService Tests', () {
    late OfferwallService offerwallService;

    setUp(() {
      offerwallService = OfferwallService();
    });

    test('should initialize service', () async {
      await offerwallService.initialize();
      
      final offers = await offerwallService.getAvailableOffers('test_user');
      expect(offers, isNotEmpty);
      expect(offers.first.isActive, isTrue);
    });

    test('should filter offers by user completion status', () async {
      await offerwallService.initialize();
      
      final allOffers = await offerwallService.getAvailableOffers('test_user');
      final initialCount = allOffers.length;
      
      // Start and complete an offer
      await offerwallService.startOffer('test_user', allOffers.first.id);
      await offerwallService.checkCompletion(
        'test_user',
        allOffers.first.id,
        {
          'userId': 'test_user',
          'offerId': allOffers.first.id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      final filteredOffers = await offerwallService.getAvailableOffers('test_user');
      expect(filteredOffers.length, equals(initialCount - 1));
    });

    test('should track pending rewards', () async {
      await offerwallService.initialize();
      
      final offers = await offerwallService.getAvailableOffers('test_user');
      await offerwallService.startOffer('test_user', offers.first.id);
      
      final pendingRewards = offerwallService.getPendingRewards('test_user');
      expect(pendingRewards, hasLength(1));
      expect(pendingRewards.first.offerId, equals(offers.first.id));
    });

    test('should calculate user statistics', () async {
      await offerwallService.initialize();
      
      final stats = offerwallService.getStatistics('test_user');
      expect(stats.completedCount, equals(0));
      expect(stats.totalEarnedPoints, equals(0));
      expect(stats.pendingCount, equals(0));
    });

    test('should validate callback data', () async {
      await offerwallService.initialize();
      
      final offers = await offerwallService.getAvailableOffers('test_user');
      final offerId = offers.first.id;
      
      // Valid callback
      final validResult = await offerwallService.checkCompletion(
        'test_user',
        offerId,
        {
          'userId': 'test_user',
          'offerId': offerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      expect(validResult.success, isTrue);
      expect(validResult.points, equals(offers.first.points));
      
      // Invalid callback (missing required fields)
      final invalidResult = await offerwallService.checkCompletion(
        'test_user',
        offerId,
        {'invalid': 'data'},
      );
      
      expect(invalidResult.success, isFalse);
      expect(invalidResult.error, isNotNull);
    });
  });
}