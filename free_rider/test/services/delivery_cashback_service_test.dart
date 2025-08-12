import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/services/commerce/delivery_cashback_service.dart';

void main() {
  group('DeliveryCashbackService Tests', () {
    late DeliveryCashbackService cashbackService;

    setUp(() {
      cashbackService = DeliveryCashbackService();
    });

    test('should initialize service', () async {
      await cashbackService.initialize();
      
      final restaurants = cashbackService.getPartnerRestaurants();
      expect(restaurants, isNotEmpty);
      
      final campaigns = cashbackService.getActiveCampaigns();
      expect(campaigns, isNotEmpty);
    });

    test('should start order tracking', () async {
      await cashbackService.initialize();
      
      final result = await cashbackService.startOrderTracking(
        userId: 'test_user',
        partnerId: 'baemin',
        restaurantId: 'rest_001',
        orderAmount: 20000.0,
      );
      
      expect(result.success, isTrue);
      expect(result.trackingId, isNotNull);
      expect(result.deepLink, isNotNull);
      expect(result.estimatedCashback, greaterThan(0));
    });

    test('should validate order requirements', () async {
      await cashbackService.initialize();
      
      // Test minimum order amount
      final result = await cashbackService.startOrderTracking(
        userId: 'test_user',
        partnerId: 'baemin',
        restaurantId: 'rest_001',
        orderAmount: 5000.0, // Below minimum
      );
      
      expect(result.success, isFalse);
      expect(result.error, contains('최소 주문금액'));
    });

    test('should calculate cashback correctly', () async {
      await cashbackService.initialize();
      
      final cashback = cashbackService.calculateExpectedCashback(
        partnerId: 'baemin',
        restaurantId: 'rest_001',
        orderAmount: 20000.0,
      );
      
      // 5% of 20000 = 1000P, but capped at 2000P max
      expect(cashback, equals(1000));
    });

    test('should filter restaurants by partner', () async {
      await cashbackService.initialize();
      
      final allRestaurants = cashbackService.getPartnerRestaurants();
      final baeminRestaurants = cashbackService.getPartnerRestaurants(
        partnerId: 'baemin',
      );
      
      expect(baeminRestaurants.length, lessThanOrEqualTo(allRestaurants.length));
      
      for (final restaurant in baeminRestaurants) {
        expect(restaurant.partnerIds, contains('baemin'));
      }
    });

    test('should track user cashback history', () async {
      await cashbackService.initialize();
      
      // Start an order
      final trackingResult = await cashbackService.startOrderTracking(
        userId: 'test_user',
        partnerId: 'baemin',
        restaurantId: 'rest_001',
        orderAmount: 20000.0,
      );
      
      // Confirm the order
      await cashbackService.confirmOrder(
        trackingId: trackingResult.trackingId!,
        orderData: {
          'orderId': 'order_123',
          'amount': 20000.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      final history = cashbackService.getCashbackHistory('test_user');
      expect(history, hasLength(1));
      expect(history.first.status, equals(CashbackStatus.confirmed));
    });

    test('should calculate user stats', () async {
      await cashbackService.initialize();
      
      final stats = cashbackService.getUserStats('test_user');
      expect(stats.totalOrders, equals(0));
      expect(stats.totalEarned, equals(0));
      expect(stats.pendingAmount, equals(0));
      expect(stats.monthlyOrders, equals(0));
      expect(stats.monthlyEarned, equals(0));
      expect(stats.averageCashback, equals(0));
    });

    test('should apply campaign bonuses', () async {
      await cashbackService.initialize();
      
      // Test with a restaurant that has campaign bonuses
      final cashbackWithoutCampaign = cashbackService.calculateExpectedCashback(
        partnerId: 'baemin',
        restaurantId: 'rest_999', // Non-existent restaurant
        orderAmount: 20000.0,
      );
      
      final cashbackWithCampaign = cashbackService.calculateExpectedCashback(
        partnerId: 'baemin',
        restaurantId: 'rest_001', // Restaurant with campaign
        orderAmount: 20000.0,
      );
      
      // Should be equal or higher due to potential campaigns
      expect(cashbackWithCampaign, greaterThanOrEqualTo(cashbackWithoutCampaign));
    });
  });
}