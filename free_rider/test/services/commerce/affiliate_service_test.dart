import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/services/commerce/affiliate_service.dart';

void main() {
  group('AffiliateService Tests', () {
    late AffiliateService affiliateService;

    setUp(() {
      affiliateService = AffiliateService();
    });

    test('서비스 싱글톤 인스턴스가 생성되어야 함', () {
      final service1 = AffiliateService();
      final service2 = AffiliateService();
      
      expect(identical(service1, service2), true);
    });

    test('상품 목록을 가져올 수 있어야 함', () async {
      final products = await affiliateService.getProducts(
        category: '전체',
        sortBy: 'popular',
      );
      
      expect(products, isNotEmpty);
      expect(products.length, lessThanOrEqualTo(20));
    });

    test('카테고리별 상품 조회가 작동해야 함', () async {
      final fashionProducts = await affiliateService.getProducts(
        category: '패션',
        sortBy: 'popular',
      );
      
      expect(fashionProducts, isNotEmpty);
      expect(fashionProducts.first.name.contains('패션'), true);
    });

    test('정렬 옵션이 작동해야 함', () async {
      final productsByPrice = await affiliateService.getProducts(
        category: '전체',
        sortBy: 'price_low',
      );
      
      if (productsByPrice.length > 1) {
        expect(
          productsByPrice[0].price <= productsByPrice[1].price,
          true,
        );
      }
    });

    test('캐시백 포인트가 올바르게 계산되어야 함', () async {
      final products = await affiliateService.getProducts(
        category: '전체',
        sortBy: 'cashback',
      );
      
      for (final product in products) {
        expect(product.cashbackPoints, greaterThan(0));
        expect(product.cashbackRate, greaterThan(0));
        
        // 캐시백 포인트가 가격과 비율에 맞게 계산되었는지
        final expectedPoints = (product.price * product.cashbackRate / 100).toInt();
        expect(product.cashbackPoints, expectedPoints);
      }
    });

    test('추적 URL이 생성되어야 함', () async {
      final url = await affiliateService.generateTrackingUrl(
        productId: 'test_product',
        affiliate: 'coupang',
        userId: 'test_user',
      );
      
      expect(url, isNotEmpty);
      expect(url.contains('test_product'), true);
      expect(url.contains('test_user'), true);
    });

    test('제휴사별로 다른 URL이 생성되어야 함', () async {
      final coupangUrl = await affiliateService.generateTrackingUrl(
        productId: 'product_1',
        affiliate: 'coupang',
        userId: 'user_1',
      );
      
      final elevenStUrl = await affiliateService.generateTrackingUrl(
        productId: 'product_1',
        affiliate: '11st',
        userId: 'user_1',
      );
      
      expect(coupangUrl, isNot(equals(elevenStUrl)));
      expect(coupangUrl.contains('coupang'), true);
      expect(elevenStUrl.contains('11st'), true);
    });
  });
}