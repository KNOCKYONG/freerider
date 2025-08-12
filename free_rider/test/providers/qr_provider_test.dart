import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/data/providers/qr_provider.dart';

void main() {
  group('QRProvider Tests', () {
    late ProviderContainer container;
    late QRNotifier qrNotifier;

    setUp(() {
      container = ProviderContainer();
      qrNotifier = container.read(qrStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태가 올바르게 설정되어야 함', () {
      final state = container.read(qrStateProvider);
      
      expect(state.todayScans, 0);
      expect(state.todayPoints, 0);
      expect(state.scanHistory, isEmpty);
      expect(state.scannedCodes, isEmpty);
      expect(state.canScanMore, true);
    });

    test('유효한 QR 코드 스캔 시 포인트를 획득해야 함', () async {
      // Given
      const validCode = 'STORE_GS25_001';
      
      // When
      final result = await qrNotifier.processQRCode(validCode);
      final state = container.read(qrStateProvider);
      
      // Then
      expect(result.success, true);
      expect(result.points, 30);
      expect(result.storeName, 'GS25 강남역점');
      expect(state.todayScans, 1);
      expect(state.todayPoints, 30);
      expect(state.scannedCodes.contains(validCode), true);
    });

    test('중복 QR 코드 스캔 시 실패해야 함', () async {
      // Given
      const code = 'STORE_CU_002';
      await qrNotifier.processQRCode(code);
      
      // When
      final result = await qrNotifier.processQRCode(code);
      
      // Then
      expect(result.success, false);
      expect(result.message, '이미 스캔한 QR 코드입니다');
    });

    test('일일 제한 초과 시 스캔이 실패해야 함', () async {
      // Given - 3번 스캔
      await qrNotifier.processQRCode('STORE_GS25_001');
      await qrNotifier.processQRCode('STORE_CU_002');
      await qrNotifier.processQRCode('STORE_SEVEN_003');
      
      // When - 4번째 시도
      final result = await qrNotifier.processQRCode('STORE_EMART24_004');
      
      // Then
      expect(result.success, false);
      expect(result.message, '오늘의 QR 스캔 횟수를 모두 사용했습니다');
    });

    test('유효하지 않은 QR 코드는 거부되어야 함', () async {
      // Given
      const invalidCode = 'INVALID_CODE_123';
      
      // When
      final result = await qrNotifier.processQRCode(invalidCode);
      
      // Then
      expect(result.success, false);
      expect(result.message, '유효하지 않은 QR 코드입니다');
    });

    test('제휴되지 않은 매장 코드는 거부되어야 함', () async {
      // Given
      const nonPartnerCode = 'STORE_UNKNOWN_999';
      
      // When
      final result = await qrNotifier.processQRCode(nonPartnerCode);
      
      // Then
      expect(result.success, false);
      expect(result.message, '제휴되지 않은 매장입니다');
    });

    test('카페 QR 코드는 더 많은 포인트를 제공해야 함', () async {
      // Given
      const cafeCode = 'CAFE_STARBUCKS_001';
      
      // When
      final result = await qrNotifier.processQRCode(cafeCode);
      
      // Then
      expect(result.success, true);
      expect(result.points, 40); // 카페는 40포인트
      expect(result.storeName, '스타벅스 강남R점');
    });

    test('resetDaily는 일일 카운터를 초기화해야 함', () async {
      // Given
      await qrNotifier.processQRCode('STORE_GS25_001');
      expect(container.read(qrStateProvider).todayScans, 1);
      
      // When
      qrNotifier.resetDaily();
      final state = container.read(qrStateProvider);
      
      // Then
      expect(state.todayScans, 0);
      expect(state.todayPoints, 0);
      expect(state.scannedCodes, isNotEmpty); // 스캔 기록은 유지
    });

    test('getTodayHistory는 오늘 스캔한 기록만 반환해야 함', () async {
      // Given
      await qrNotifier.processQRCode('STORE_GS25_001');
      await qrNotifier.processQRCode('STORE_CU_002');
      
      // When
      final todayHistory = qrNotifier.getTodayHistory();
      
      // Then
      expect(todayHistory.length, 2);
      expect(todayHistory[0].storeName, 'GS25 강남역점');
      expect(todayHistory[1].storeName, 'CU 서울역점');
    });
  });
}