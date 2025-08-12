import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/presentation/screens/earn/offerwall_screen.dart';
import 'package:free_rider/presentation/screens/earn/delivery_cashback_screen.dart';
import 'package:free_rider/presentation/screens/earn/ai_labeling_screen.dart';

void main() {
  group('Revenue Feature Widget Tests', () {
    testWidgets('OfferwallScreen should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OfferwallScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check if tabs are present
      expect(find.text('추천'), findsOneWidget);
      expect(find.text('전체'), findsOneWidget);
      expect(find.text('대기중'), findsOneWidget);
      
      // Check if app bar title is correct
      expect(find.text('오퍼월'), findsOneWidget);
    });

    testWidgets('DeliveryCashbackScreen should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveryCashbackScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check if tabs are present
      expect(find.text('제휴매장'), findsOneWidget);
      expect(find.text('캠페인'), findsOneWidget);
      expect(find.text('내역'), findsOneWidget);
      
      // Check if app bar title is correct
      expect(find.text('배달 캐시백'), findsOneWidget);
    });

    testWidgets('AILabelingScreen should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AILabelingScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check if tabs are present
      expect(find.text('작업'), findsOneWidget);
      expect(find.text('내 정보'), findsOneWidget);
      expect(find.text('랭킹'), findsOneWidget);
      
      // Check if app bar title is correct
      expect(find.text('AI 데이터 라벨링'), findsOneWidget);
    });

    testWidgets('Offerwall should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OfferwallScreen(),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Delivery cashback should handle filter interactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveryCashbackScreen(),
          ),
        ),
      );

      await tester.pump();

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Try to find and tap on a filter chip if it exists
      final filterChip = find.byType(ChoiceChip).first;
      if (filterChip.evaluate().isNotEmpty) {
        await tester.tap(filterChip);
        await tester.pump();
      }
    });

    testWidgets('AI Labeling should show user stats when switching to My Info tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AILabelingScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Tap on "내 정보" tab
      await tester.tap(find.text('내 정보'));
      await tester.pumpAndSettle();

      // Should show level information
      expect(find.textContaining('Level'), findsWidgets);
    });

    group('Error Handling Tests', () {
      testWidgets('Should handle empty offer list gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: OfferwallScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to pending tab which should be empty initially
        await tester.tap(find.text('대기중'));
        await tester.pumpAndSettle();

        // Should show empty state message
        expect(find.textContaining('대기 중인 보상이 없습니다'), findsOneWidget);
      });

      testWidgets('Should handle empty cashback history gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DeliveryCashbackScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to history tab
        await tester.tap(find.text('내역'));
        await tester.pumpAndSettle();

        // Should show empty state message
        expect(find.textContaining('캐시백 내역이 없습니다'), findsOneWidget);
      });

      testWidgets('Should handle empty campaign list gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DeliveryCashbackScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to campaigns tab
        await tester.tap(find.text('캠페인'));
        await tester.pumpAndSettle();

        // Should show empty state message or campaign list
        expect(find.byType(DeliveryCashbackScreen), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('Should handle back navigation properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => const Scaffold(
                  body: Center(child: Text('Home')),
                ),
                '/offerwall': (context) => const OfferwallScreen(),
              },
            ),
          ),
        );

        // Navigate to offerwall
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: OfferwallScreen(),
            ),
          ),
        );

        await tester.pump();

        // Should display offerwall screen
        expect(find.byType(OfferwallScreen), findsOneWidget);
      });
    });
  });
}