import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/survey_model.dart';

// Survey State Provider
final surveyStateProvider = StateNotifierProvider<SurveyNotifier, SurveyState>((ref) {
  return SurveyNotifier();
});

// Individual Survey Provider
final surveyProvider = Provider.family<Survey?, String>((ref, surveyId) {
  final state = ref.watch(surveyStateProvider);
  return state.availableSurveys.firstWhere(
    (survey) => survey.id == surveyId,
    orElse: () => state.mockSurveys.firstWhere(
      (survey) => survey.id == surveyId,
    ),
  );
});

// Available Surveys Provider
final availableSurveysProvider = Provider<List<Survey>>((ref) {
  final state = ref.watch(surveyStateProvider);
  return state.availableSurveys.where((survey) {
    // 완료되지 않은 설문만 표시
    return !state.completedSurveyIds.contains(survey.id);
  }).toList();
});

class SurveyState {
  final List<Survey> availableSurveys;
  final List<Survey> mockSurveys;
  final Set<String> completedSurveyIds;
  final List<SurveyResponse> responses;
  final int todayPoints;
  final bool isLoading;

  SurveyState({
    this.availableSurveys = const [],
    this.mockSurveys = const [],
    Set<String>? completedSurveyIds,
    this.responses = const [],
    this.todayPoints = 0,
    this.isLoading = false,
  }) : completedSurveyIds = completedSurveyIds ?? {};

  SurveyState copyWith({
    List<Survey>? availableSurveys,
    List<Survey>? mockSurveys,
    Set<String>? completedSurveyIds,
    List<SurveyResponse>? responses,
    int? todayPoints,
    bool? isLoading,
  }) {
    return SurveyState(
      availableSurveys: availableSurveys ?? this.availableSurveys,
      mockSurveys: mockSurveys ?? this.mockSurveys,
      completedSurveyIds: completedSurveyIds ?? this.completedSurveyIds,
      responses: responses ?? this.responses,
      todayPoints: todayPoints ?? this.todayPoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SurveyNotifier extends StateNotifier<SurveyState> {
  SurveyNotifier() : super(SurveyState()) {
    _initializeMockSurveys();
  }

  void _initializeMockSurveys() {
    final mockSurveys = [
      Survey(
        id: 'survey_001',
        title: '대중교통 이용 습관 설문',
        description: '귀하의 대중교통 이용 패턴을 알려주세요',
        points: 30,
        category: '교통',
        estimatedTime: 3,
        questions: [
          SurveyQuestion(
            id: 'q1',
            text: '주로 이용하는 대중교통 수단은?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '지하철'),
              SurveyOption(id: 'o2', text: '버스'),
              SurveyOption(id: 'o3', text: '택시'),
              SurveyOption(id: 'o4', text: '자전거'),
            ],
          ),
          SurveyQuestion(
            id: 'q2',
            text: '하루 평균 대중교통 이용 횟수는?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '1-2회'),
              SurveyOption(id: 'o2', text: '3-4회'),
              SurveyOption(id: 'o3', text: '5-6회'),
              SurveyOption(id: 'o4', text: '7회 이상'),
            ],
          ),
          SurveyQuestion(
            id: 'q3',
            text: '대중교통 이용 시 불편한 점은? (복수 선택)',
            type: QuestionType.multiple,
            options: [
              SurveyOption(id: 'o1', text: '혼잡함'),
              SurveyOption(id: 'o2', text: '비용'),
              SurveyOption(id: 'o3', text: '시간'),
              SurveyOption(id: 'o4', text: '환승'),
              SurveyOption(id: 'o5', text: '청결'),
            ],
          ),
        ],
      ),
      Survey(
        id: 'survey_002',
        title: '쇼핑 선호도 조사',
        description: '온라인/오프라인 쇼핑 패턴에 대한 설문',
        points: 40,
        category: '쇼핑',
        estimatedTime: 5,
        questions: [
          SurveyQuestion(
            id: 'q1',
            text: '주로 어디서 쇼핑하시나요?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '온라인 쇼핑몰'),
              SurveyOption(id: 'o2', text: '오프라인 매장'),
              SurveyOption(id: 'o3', text: '둘 다 비슷하게'),
            ],
          ),
          SurveyQuestion(
            id: 'q2',
            text: '온라인 쇼핑 시 가장 중요하게 생각하는 것은?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '가격'),
              SurveyOption(id: 'o2', text: '배송 속도'),
              SurveyOption(id: 'o3', text: '상품 품질'),
              SurveyOption(id: 'o4', text: '리뷰'),
              SurveyOption(id: 'o5', text: '반품 정책'),
            ],
          ),
          SurveyQuestion(
            id: 'q3',
            text: '월 평균 온라인 쇼핑 금액은?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '10만원 미만'),
              SurveyOption(id: 'o2', text: '10-30만원'),
              SurveyOption(id: 'o3', text: '30-50만원'),
              SurveyOption(id: 'o4', text: '50만원 이상'),
            ],
          ),
        ],
      ),
      Survey(
        id: 'survey_003',
        title: '건강 관리 습관',
        description: '일상 건강 관리에 대한 질문',
        points: 25,
        category: '건강',
        estimatedTime: 2,
        questions: [
          SurveyQuestion(
            id: 'q1',
            text: '하루 평균 걷는 시간은?',
            type: QuestionType.single,
            options: [
              SurveyOption(id: 'o1', text: '30분 미만'),
              SurveyOption(id: 'o2', text: '30분-1시간'),
              SurveyOption(id: 'o3', text: '1-2시간'),
              SurveyOption(id: 'o4', text: '2시간 이상'),
            ],
          ),
          SurveyQuestion(
            id: 'q2',
            text: '주로 하는 운동은? (복수 선택)',
            type: QuestionType.multiple,
            options: [
              SurveyOption(id: 'o1', text: '걸어다니기'),
              SurveyOption(id: 'o2', text: '런닝'),
              SurveyOption(id: 'o3', text: '자전거'),
              SurveyOption(id: 'o4', text: '헬스장'),
              SurveyOption(id: 'o5', text: '요가'),
              SurveyOption(id: 'o6', text: '홈트레이닝'),
            ],
          ),
        ],
      ),
    ];

    state = state.copyWith(
      mockSurveys: mockSurveys,
      availableSurveys: mockSurveys,
    );
  }

  Future<bool> submitSurvey(String surveyId, Map<int, dynamic> answers) async {
    if (state.completedSurveyIds.contains(surveyId)) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // 설문 찾기
      final survey = state.availableSurveys.firstWhere(
        (s) => s.id == surveyId,
        orElse: () => state.mockSurveys.firstWhere(
          (s) => s.id == surveyId,
        ),
      );

      // 설문 응답 생성
      final response = SurveyResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        surveyId: surveyId,
        userId: 'user_001', // 실제로는 로그인된 사용자 ID
        answers: answers.map((k, v) => MapEntry(k.toString(), v)),
        completedAt: DateTime.now(),
        pointsEarned: survey.points,
      );

      // 상태 업데이트
      state = state.copyWith(
        completedSurveyIds: {...state.completedSurveyIds, surveyId},
        responses: [...state.responses, response],
        todayPoints: state.todayPoints + survey.points,
        isLoading: false,
      );

      // 시뮬레이션: 서버로 전송
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void loadMoreSurveys() async {
    // 실제로는 서버에서 추가 설문 로드
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false);
  }

  List<SurveyResponse> getTodayResponses() {
    final now = DateTime.now();
    return state.responses.where((response) {
      return response.completedAt.year == now.year &&
             response.completedAt.month == now.month &&
             response.completedAt.day == now.day;
    }).toList();
  }

  void resetDaily() {
    state = state.copyWith(
      todayPoints: 0,
      // 오늘 완료한 설문은 유지
    );
  }
}