import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/services/ai/data_labeling_service.dart';

void main() {
  group('DataLabelingService Tests', () {
    late DataLabelingService labelingService;

    setUp(() {
      labelingService = DataLabelingService();
    });

    test('should initialize service', () async {
      await labelingService.initialize();
      
      final tasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
      );
      
      expect(tasks, isNotEmpty);
      expect(tasks.first.isActive, isTrue);
    });

    test('should filter tasks by user level', () async {
      await labelingService.initialize();
      
      // Get tasks for a new user (level 1)
      final beginnerTasks = await labelingService.getAvailableTasks(
        userId: 'new_user',
      );
      
      for (final task in beginnerTasks) {
        expect(task.requiredLevel, lessThanOrEqualTo(1));
      }
    });

    test('should filter tasks by difficulty', () async {
      await labelingService.initialize();
      
      final easyTasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
        difficulty: TaskDifficulty.easy,
      );
      
      for (final task in easyTasks) {
        expect(task.difficulty, equals(TaskDifficulty.easy));
      }
    });

    test('should filter tasks by category', () async {
      await labelingService.initialize();
      
      final imageTasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
        category: TaskCategory.imageClassification,
      );
      
      for (final task in imageTasks) {
        expect(task.category, equals(TaskCategory.imageClassification));
      }
    });

    test('should create labeling session', () async {
      await labelingService.initialize();
      
      final tasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
      );
      
      final session = await labelingService.startTask(
        userId: 'test_user',
        taskId: tasks.first.id,
      );
      
      expect(session.userId, equals('test_user'));
      expect(session.taskId, equals(tasks.first.id));
      expect(session.items, isNotEmpty);
      expect(session.currentIndex, equals(0));
    });

    test('should validate label data quality', () async {
      await labelingService.initialize();
      
      final tasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
      );
      
      final session = await labelingService.startTask(
        userId: 'test_user',
        taskId: tasks.first.id,
      );
      
      // Test high quality submission
      final goodResult = await labelingService.submitLabeling(
        sessionId: session.id,
        itemId: session.items.first.id,
        labelData: {
          'label': 'cat',
          'confidence': 'high',
          'notes': 'Clear image of a cat',
        },
        timeSpentSeconds: 15, // Reasonable time
      );
      
      expect(goodResult.success, isTrue);
      expect(goodResult.qualityScore, greaterThan(0.7));
      expect(goodResult.points, greaterThan(0));
      
      // Test low quality submission
      final badResult = await labelingService.submitLabeling(
        sessionId: session.id,
        itemId: session.items[1].id,
        labelData: {
          'label': '', // Empty label
        },
        timeSpentSeconds: 1, // Too fast
      );
      
      expect(badResult.success, isFalse);
      expect(badResult.error, isNotNull);
    });

    test('should track user statistics', () async {
      await labelingService.initialize();
      
      final stats = labelingService.getUserStats('new_user');
      expect(stats.totalSubmissions, equals(0));
      expect(stats.totalPoints, equals(0));
      expect(stats.averageQuality, equals(0));
      expect(stats.level, equals(1));
      expect(stats.nextLevelProgress, equals(0));
    });

    test('should generate leaderboard', () async {
      await labelingService.initialize();
      
      final leaderboard = labelingService.getLeaderboard(
        period: LeaderboardPeriod.daily,
        limit: 5,
      );
      
      expect(leaderboard, hasLength(lessThanOrEqualTo(5)));
      
      // Check if sorted by points (descending)
      if (leaderboard.length > 1) {
        for (int i = 0; i < leaderboard.length - 1; i++) {
          expect(
            leaderboard[i].points,
            greaterThanOrEqualTo(leaderboard[i + 1].points),
          );
        }
      }
    });

    test('should provide task examples', () async {
      await labelingService.initialize();
      
      final tasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
      );
      
      for (final task in tasks) {
        final examples = labelingService.getTaskExamples(task.id);
        // Some tasks should have examples
        if (examples.isNotEmpty) {
          expect(examples.first.input, isNotEmpty);
          expect(examples.first.expectedOutput, isNotEmpty);
        }
      }
    });

    test('should handle session expiry', () async {
      await labelingService.initialize();
      
      final tasks = await labelingService.getAvailableTasks(
        userId: 'test_user',
      );
      
      final session = await labelingService.startTask(
        userId: 'test_user',
        taskId: tasks.first.id,
      );
      
      // Check if session has proper expiry time
      expect(session.expiresAt.isAfter(DateTime.now()), isTrue);
      expect(
        session.expiresAt.isBefore(DateTime.now().add(const Duration(hours: 1))),
        isTrue,
      );
    });
  });
}