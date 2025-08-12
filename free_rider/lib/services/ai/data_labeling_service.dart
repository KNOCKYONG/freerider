import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// AI 데이터 라벨링 서비스
/// 사용자가 AI 학습 데이터를 생성하고 포인트를 획득
class DataLabelingService {
  static final DataLabelingService _instance = DataLabelingService._internal();
  factory DataLabelingService() => _instance;
  DataLabelingService._internal();

  // 작업 큐
  final List<LabelingTask> _availableTasks = [];
  final Map<String, List<LabelingSubmission>> _userSubmissions = {};
  final Map<String, UserLabelingStats> _userStats = {};
  
  // 품질 관리
  final Map<String, double> _userQualityScores = {};
  final List<QualityCheckResult> _qualityHistory = [];

  /// 서비스 초기화
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _loadSampleTasks();
    debugPrint('Data labeling service initialized');
  }

  /// 사용 가능한 작업 가져오기
  Future<List<LabelingTask>> getAvailableTasks({
    required String userId,
    TaskDifficulty? difficulty,
    TaskCategory? category,
  }) async {
    // 사용자 레벨에 따른 필터링
    final userLevel = _getUserLevel(userId);
    
    var tasks = _availableTasks.where((task) {
      // 완료하지 않은 작업만
      final submissions = _userSubmissions[userId] ?? [];
      if (submissions.any((s) => s.taskId == task.id)) {
        return false;
      }
      
      // 레벨 체크
      if (task.requiredLevel > userLevel) {
        return false;
      }
      
      // 난이도 필터
      if (difficulty != null && task.difficulty != difficulty) {
        return false;
      }
      
      // 카테고리 필터
      if (category != null && task.category != category) {
        return false;
      }
      
      // 마감 체크
      if (DateTime.now().isAfter(task.deadline)) {
        return false;
      }
      
      return task.isActive && task.remainingCount > 0;
    }).toList();
    
    // 포인트 높은 순으로 정렬
    tasks.sort((a, b) => b.pointsPerItem.compareTo(a.pointsPerItem));
    
    return tasks;
  }

  /// 작업 시작
  Future<LabelingSession> startTask({
    required String userId,
    required String taskId,
  }) async {
    final task = _availableTasks.firstWhere((t) => t.id == taskId);
    
    // 작업 아이템 로드
    final items = await _loadTaskItems(taskId);
    
    // 세션 생성
    final session = LabelingSession(
      id: 'LS_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      taskId: taskId,
      items: items,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
    
    return session;
  }

  /// 라벨링 제출
  Future<LabelingSubmitResult> submitLabeling({
    required String sessionId,
    required String itemId,
    required Map<String, dynamic> labelData,
    required int timeSpentSeconds,
  }) async {
    try {
      // 품질 체크
      final qualityScore = await _checkQuality(itemId, labelData, timeSpentSeconds);
      
      if (qualityScore < 0.7) {
        return LabelingSubmitResult(
          success: false,
          error: '품질 기준 미달. 더 신중하게 작업해주세요.',
          qualityScore: qualityScore,
        );
      }
      
      // 제출 기록
      final submission = LabelingSubmission(
        id: 'SUB_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        itemId: itemId,
        labelData: labelData,
        qualityScore: qualityScore,
        timeSpent: timeSpentSeconds,
        submittedAt: DateTime.now(),
      );
      
      // 포인트 계산
      final basePoints = _getTaskPoints(sessionId);
      final qualityBonus = (basePoints * qualityScore * 0.5).toInt();
      final totalPoints = basePoints + qualityBonus;
      
      return LabelingSubmitResult(
        success: true,
        points: totalPoints,
        qualityScore: qualityScore,
        qualityBonus: qualityBonus,
      );
    } catch (e) {
      return LabelingSubmitResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 사용자 통계
  UserLabelingStats getUserStats(String userId) {
    return _userStats[userId] ?? UserLabelingStats(
      userId: userId,
      totalSubmissions: 0,
      totalPoints: 0,
      averageQuality: 0,
      level: 1,
      nextLevelProgress: 0,
    );
  }

  /// 리더보드
  List<LeaderboardEntry> getLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.daily,
    int limit = 10,
  }) {
    final entries = _userStats.values.map((stats) {
      return LeaderboardEntry(
        userId: stats.userId,
        username: 'User${stats.userId.substring(0, 4)}',
        points: _getPointsForPeriod(stats.userId, period),
        submissions: _getSubmissionsForPeriod(stats.userId, period),
        averageQuality: stats.averageQuality,
      );
    }).toList();
    
    entries.sort((a, b) => b.points.compareTo(a.points));
    
    return entries.take(limit).toList();
  }

  /// 작업별 예시 가져오기
  List<LabelingExample> getTaskExamples(String taskId) {
    // 각 작업별 예시 반환
    switch (taskId) {
      case 'task_001':
        return [
          LabelingExample(
            input: 'https://example.com/cat1.jpg',
            expectedOutput: {'label': 'cat', 'confidence': 'high'},
            explanation: '이미지에 고양이가 명확하게 보입니다',
          ),
        ];
      case 'task_002':
        return [
          LabelingExample(
            input: '오늘 날씨가 정말 좋네요!',
            expectedOutput: {'sentiment': 'positive', 'intensity': 0.8},
            explanation: '긍정적인 감정이 강하게 표현됨',
          ),
        ];
      default:
        return [];
    }
  }

  // Private methods

  int _getUserLevel(String userId) {
    final stats = _userStats[userId];
    if (stats == null) return 1;
    
    // 제출 수에 따른 레벨 계산
    if (stats.totalSubmissions >= 1000) return 5;
    if (stats.totalSubmissions >= 500) return 4;
    if (stats.totalSubmissions >= 200) return 3;
    if (stats.totalSubmissions >= 50) return 2;
    return 1;
  }

  Future<List<LabelingItem>> _loadTaskItems(String taskId) async {
    // Mock 데이터 로드
    await Future.delayed(const Duration(milliseconds: 500));
    
    switch (taskId) {
      case 'task_001': // 이미지 분류
        return List.generate(10, (i) => LabelingItem(
          id: 'item_img_$i',
          type: ItemType.image,
          content: 'https://example.com/image_$i.jpg',
          metadata: {'width': 1024, 'height': 768},
        ));
        
      case 'task_002': // 텍스트 감정 분석
        return [
          LabelingItem(
            id: 'item_text_1',
            type: ItemType.text,
            content: '오늘 회사에서 승진했어요! 너무 기쁩니다.',
            metadata: {},
          ),
          LabelingItem(
            id: 'item_text_2',
            type: ItemType.text,
            content: '비가 와서 약속이 취소됐네요.',
            metadata: {},
          ),
        ];
        
      case 'task_003': // 음성 전사
        return List.generate(5, (i) => LabelingItem(
          id: 'item_audio_$i',
          type: ItemType.audio,
          content: 'https://example.com/audio_$i.mp3',
          metadata: {'duration': 15},
        ));
        
      default:
        return [];
    }
  }

  Future<double> _checkQuality(
    String itemId,
    Map<String, dynamic> labelData,
    int timeSpentSeconds,
  ) async {
    // 품질 평가 로직
    // 1. 시간 체크 (너무 빠르거나 느리면 감점)
    double timeScore = 1.0;
    if (timeSpentSeconds < 3) {
      timeScore = 0.5; // 너무 빠름
    } else if (timeSpentSeconds > 300) {
      timeScore = 0.8; // 너무 느림
    }
    
    // 2. 완성도 체크
    double completenessScore = labelData.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .length / labelData.length;
    
    // 3. 일관성 체크 (이전 제출과 비교)
    double consistencyScore = 0.9; // Mock
    
    // 종합 점수
    return (timeScore * 0.3 + completenessScore * 0.4 + consistencyScore * 0.3)
        .clamp(0.0, 1.0);
  }

  int _getTaskPoints(String sessionId) {
    // Mock: 실제로는 세션에서 작업 정보 조회
    return 50;
  }

  int _getPointsForPeriod(String userId, LeaderboardPeriod period) {
    final submissions = _userSubmissions[userId] ?? [];
    final now = DateTime.now();
    
    final filtered = submissions.where((s) {
      switch (period) {
        case LeaderboardPeriod.daily:
          return s.submittedAt.day == now.day;
        case LeaderboardPeriod.weekly:
          return s.submittedAt.isAfter(now.subtract(const Duration(days: 7)));
        case LeaderboardPeriod.monthly:
          return s.submittedAt.month == now.month;
        case LeaderboardPeriod.allTime:
          return true;
      }
    });
    
    return filtered.fold(0, (sum, s) => sum + 50); // Mock points
  }

  int _getSubmissionsForPeriod(String userId, LeaderboardPeriod period) {
    final submissions = _userSubmissions[userId] ?? [];
    final now = DateTime.now();
    
    return submissions.where((s) {
      switch (period) {
        case LeaderboardPeriod.daily:
          return s.submittedAt.day == now.day;
        case LeaderboardPeriod.weekly:
          return s.submittedAt.isAfter(now.subtract(const Duration(days: 7)));
        case LeaderboardPeriod.monthly:
          return s.submittedAt.month == now.month;
        case LeaderboardPeriod.allTime:
          return true;
      }
    }).length;
  }

  void _loadSampleTasks() {
    _availableTasks.addAll([
      LabelingTask(
        id: 'task_001',
        title: '이미지 분류 - 동물',
        description: '이미지 속 동물을 식별하고 라벨링',
        category: TaskCategory.imageClassification,
        difficulty: TaskDifficulty.easy,
        pointsPerItem: 30,
        estimatedTimePerItem: 10,
        totalItems: 1000,
        remainingCount: 850,
        requiredLevel: 1,
        deadline: DateTime.now().add(const Duration(days: 7)),
        instructions: [
          '이미지를 자세히 관찰하세요',
          '주요 동물을 선택하세요',
          '확신도를 표시하세요',
        ],
      ),
      LabelingTask(
        id: 'task_002',
        title: '텍스트 감정 분석',
        description: '텍스트의 감정을 긍정/부정/중립으로 분류',
        category: TaskCategory.textClassification,
        difficulty: TaskDifficulty.medium,
        pointsPerItem: 50,
        estimatedTimePerItem: 15,
        totalItems: 500,
        remainingCount: 320,
        requiredLevel: 2,
        deadline: DateTime.now().add(const Duration(days: 5)),
        instructions: [
          '텍스트를 꼼꼼히 읽으세요',
          '전체적인 감정을 파악하세요',
          '세부 감정도 표시해주세요',
        ],
      ),
      LabelingTask(
        id: 'task_003',
        title: '음성 전사 - 한국어',
        description: '한국어 음성을 텍스트로 전사',
        category: TaskCategory.audioTranscription,
        difficulty: TaskDifficulty.hard,
        pointsPerItem: 100,
        estimatedTimePerItem: 60,
        totalItems: 200,
        remainingCount: 150,
        requiredLevel: 3,
        deadline: DateTime.now().add(const Duration(days: 3)),
        instructions: [
          '음성을 주의깊게 들으세요',
          '정확한 맞춤법으로 전사하세요',
          '불명확한 부분은 표시하세요',
        ],
      ),
      LabelingTask(
        id: 'task_004',
        title: '객체 탐지 - 도로 표지판',
        description: '도로 이미지에서 표지판 위치 표시',
        category: TaskCategory.objectDetection,
        difficulty: TaskDifficulty.medium,
        pointsPerItem: 80,
        estimatedTimePerItem: 30,
        totalItems: 300,
        remainingCount: 200,
        requiredLevel: 2,
        deadline: DateTime.now().add(const Duration(days: 10)),
        instructions: [
          '모든 표지판을 찾으세요',
          '바운딩 박스를 정확히 그리세요',
          '표지판 종류를 분류하세요',
        ],
      ),
      LabelingTask(
        id: 'task_005',
        title: '상품 리뷰 요약',
        description: '긴 상품 리뷰를 3줄로 요약',
        category: TaskCategory.textSummarization,
        difficulty: TaskDifficulty.hard,
        pointsPerItem: 150,
        estimatedTimePerItem: 90,
        totalItems: 100,
        remainingCount: 80,
        requiredLevel: 4,
        deadline: DateTime.now().add(const Duration(days: 14)),
        instructions: [
          '핵심 내용을 파악하세요',
          '장단점을 균형있게 포함하세요',
          '3줄 이내로 요약하세요',
        ],
      ),
    ]);
  }
}

// Models

class LabelingTask {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final int pointsPerItem;
  final int estimatedTimePerItem; // seconds
  final int totalItems;
  final int remainingCount;
  final int requiredLevel;
  final DateTime deadline;
  final List<String> instructions;
  final bool isActive;

  LabelingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.pointsPerItem,
    required this.estimatedTimePerItem,
    required this.totalItems,
    required this.remainingCount,
    required this.requiredLevel,
    required this.deadline,
    required this.instructions,
    this.isActive = true,
  });
}

enum TaskCategory {
  imageClassification,
  objectDetection,
  textClassification,
  textSummarization,
  audioTranscription,
  videoAnnotation,
  dataCategorization,
}

enum TaskDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class LabelingSession {
  final String id;
  final String userId;
  final String taskId;
  final List<LabelingItem> items;
  final DateTime startedAt;
  final DateTime expiresAt;
  int currentIndex;

  LabelingSession({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.items,
    required this.startedAt,
    required this.expiresAt,
    this.currentIndex = 0,
  });
}

class LabelingItem {
  final String id;
  final ItemType type;
  final String content; // URL or text
  final Map<String, dynamic> metadata;

  LabelingItem({
    required this.id,
    required this.type,
    required this.content,
    required this.metadata,
  });
}

enum ItemType {
  image,
  text,
  audio,
  video,
}

class LabelingSubmission {
  final String id;
  final String sessionId;
  final String itemId;
  final String? taskId;
  final String? userId;
  final Map<String, dynamic> labelData;
  final double qualityScore;
  final int timeSpent;
  final DateTime submittedAt;

  LabelingSubmission({
    required this.id,
    required this.sessionId,
    required this.itemId,
    this.taskId,
    this.userId,
    required this.labelData,
    required this.qualityScore,
    required this.timeSpent,
    required this.submittedAt,
  });
}

class LabelingSubmitResult {
  final bool success;
  final int? points;
  final double? qualityScore;
  final int? qualityBonus;
  final String? error;

  LabelingSubmitResult({
    required this.success,
    this.points,
    this.qualityScore,
    this.qualityBonus,
    this.error,
  });
}

class UserLabelingStats {
  final String userId;
  final int totalSubmissions;
  final int totalPoints;
  final double averageQuality;
  final int level;
  final double nextLevelProgress;

  UserLabelingStats({
    required this.userId,
    required this.totalSubmissions,
    required this.totalPoints,
    required this.averageQuality,
    required this.level,
    required this.nextLevelProgress,
  });
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final int points;
  final int submissions;
  final double averageQuality;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.points,
    required this.submissions,
    required this.averageQuality,
  });
}

enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

class LabelingExample {
  final String input;
  final Map<String, dynamic> expectedOutput;
  final String explanation;

  LabelingExample({
    required this.input,
    required this.expectedOutput,
    required this.explanation,
  });
}

class QualityCheckResult {
  final String submissionId;
  final double score;
  final List<String> issues;
  final DateTime checkedAt;

  QualityCheckResult({
    required this.submissionId,
    required this.score,
    required this.issues,
    required this.checkedAt,
  });
}