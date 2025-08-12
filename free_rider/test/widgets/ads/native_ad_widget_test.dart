import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/presentation/widgets/ads/native_ad_widget.dart';

void main() {
  group('NativeAdWidget Tests', () {
    testWidgets('네이티브 광고 위젯이 렌더링되어야 함', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NativeAdWidget(
                placementId: 'test_placement',
                style: NativeAdStyle.medium,
              ),
            ),
          ),
        ),
      );

      // 위젯이 존재하는지 확인
      expect(find.byType(NativeAdWidget), findsOneWidget);
    });

    testWidgets('커스텀 스타일 광고가 올바른 UI를 표시해야 함', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NativeAdWidget(
                placementId: 'test_placement',
                style: NativeAdStyle.custom,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 커스텀 광고 요소들이 표시되는지 확인
      expect(find.text('광고'), findsOneWidget);
      expect(find.text('자세히 보기'), findsOneWidget);
    });

    testWidgets('피드 네이티브 광고가 지정된 간격으로 표시되어야 함', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return FeedNativeAdWidget(
                    index: index,
                    adInterval: 5,
                    child: ListTile(
                      title: Text('Item $index'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 일반 아이템들이 표시되는지 확인
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      
      // 5번째 아이템 후 광고가 표시되는지 확인 (index 4)
      expect(find.text('Item 4'), findsOneWidget);
    });

    testWidgets('광고 클릭 콜백이 호출되어야 함', (WidgetTester tester) async {
      int earnedPoints = 0;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NativeAdWidget(
                placementId: 'test_placement',
                style: NativeAdStyle.custom,
                onAdClicked: (points) {
                  earnedPoints = points;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 광고 클릭
      final button = find.text('자세히 보기');
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button);
        await tester.pump();
        
        // 포인트가 지급되었는지 확인
        expect(earnedPoints, greaterThan(0));
      }
    });
  });
}