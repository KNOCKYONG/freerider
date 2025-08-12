import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/presentation/screens/qr/qr_scanner_screen.dart';
import 'package:free_rider/data/providers/qr_provider.dart';

void main() {
  group('QRScannerScreen Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('QR Scanner 화면이 올바르게 렌더링되어야 함', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QRScannerScreen(),
          ),
        ),
      );

      // 기본 UI 요소 확인
      expect(find.text('QR 코드 스캔'), findsOneWidget);
      expect(find.text('QR 코드를 스캔하세요'), findsOneWidget);
      expect(find.text('제휴 매장에서 포인트를 획듍하세요'), findsOneWidget);
    });

    testWidgets('일일 스캔 횟수가 표시되어야 함', (WidgetTester tester) async {
      // Given - 이미 2번 스캔한 상태
      final notifier = container.read(qrStateProvider.notifier);
      await notifier.processQRCode('STORE_GS25_001');
      await notifier.processQRCode('STORE_CU_002');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QRScannerScreen(),
          ),
        ),
      );

      // Then
      expect(find.text('오늘 스캔: 2/3'), findsOneWidget);
    });

    testWidgets('일일 제한 초과 시 경고 메시지가 표시되어야 함', (WidgetTester tester) async {
      // Given - 3번 모두 스캔한 상태
      final notifier = container.read(qrStateProvider.notifier);
      await notifier.processQRCode('STORE_GS25_001');
      await notifier.processQRCode('STORE_CU_002');
      await notifier.processQRCode('STORE_SEVEN_003');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QRScannerScreen(),
          ),
        ),
      );

      // Then
      expect(
        find.text('오늘의 QR 스캔 횟수를 모두 사용했습니다'),
        findsOneWidget,
      );
      expect(find.text('오늘 스캔: 3/3'), findsOneWidget);
    });

    testWidgets('토치 버튼이 존재해야 함', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QRScannerScreen(),
          ),
        ),
      );

      // 플래시 아이콘 확인
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });
  });
}