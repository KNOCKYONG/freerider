import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/data/providers/survey_provider.dart';
import 'package:free_rider/data/models/survey_model.dart';

void main() {
  group('SurveyProvider Tests', () {
    late ProviderContainer container;
    late SurveyNotifier surveyNotifier;

    setUp(() {
      container = ProviderContainer();
      surveyNotifier = container.read(surveyStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Mock 설문 데이터가 초기화되어야 함', () {
      final state = container.read(surveyStateProvider);
      
      expect(state.mockSurveys, isNotEmpty);
      expect(state.mockSurveys.length, 3);
      expect(state.availableSurveys.length, 3);
    });

    test('각 설문의 기본 정보가 올바르게 설정되어야 함', () {
      final survey = container.read(surveyStateProvider).mockSurveys[0];
      
      expect(survey.id, 'survey_001');
      expect(survey.title, '대중교통 이용 습관 설문');
      expect(survey.points, 30);
      expect(survey.category, '교통');
      expect(survey.estimatedTime, 3);
      expect(survey.questions.length, 3);
    });

    test('설문 제출이 성공해야 함', () async {
      // Given
      const surveyId = 'survey_001';
      final answers = {0: 0, 1: 1, 2: [0, 2]}; // 답변 예시
      
      // When
      final result = await surveyNotifier.submitSurvey(surveyId, answers);
      final state = container.read(surveyStateProvider);
      
      // Then
      expect(result, true);
      expect(state.completedSurveyIds.contains(surveyId), true);
      expect(state.responses.length, 1);
      expect(state.todayPoints, 30);
    });

    test('완료한 설문은 다시 제출할 수 없어야 함', () async {
      // Given
      const surveyId = 'survey_002';
      final answers = {0: 0, 1: 2, 2: 1};
      await surveyNotifier.submitSurvey(surveyId, answers);
      
      // When
      final result = await surveyNotifier.submitSurvey(surveyId, answers);
      
      // Then
      expect(result, false);
    });

    test('사용 가능한 설문 목록에서 완료된 설문이 제외되어야 함', () async {
      // Given
      const surveyId = 'survey_003';
      final initialCount = container.read(availableSurveysProvider).length;
      
      // When
      await surveyNotifier.submitSurvey(surveyId, {0: 1, 1: [0, 1, 3]});
      final availableSurveys = container.read(availableSurveysProvider);
      
      // Then
      expect(availableSurveys.length, initialCount - 1);
      expect(
        availableSurveys.any((s) => s.id == surveyId),
        false,
      );
    });

    test('설문 응답이 올바르게 저장되어야 함', () async {
      // Given
      const surveyId = 'survey_001';
      final answers = {0: 2, 1: 0, 2: [1, 3]};
      
      // When
      await surveyNotifier.submitSurvey(surveyId, answers);
      final response = container.read(surveyStateProvider).responses[0];
      
      // Then
      expect(response.surveyId, surveyId);
      expect(response.answers['0'], 2);
      expect(response.answers['1'], 0);
      expect(response.answers['2'], [1, 3]);
      expect(response.pointsEarned, 30);
    });

    test('오늘 완료한 설문만 반환해야 함', () async {
      // Given
      await surveyNotifier.submitSurvey('survey_001', {0: 0, 1: 1, 2: [0]});
      await surveyNotifier.submitSurvey('survey_002', {0: 1, 1: 2, 2: 0});
      
      // When
      final todayResponses = surveyNotifier.getTodayResponses();
      
      // Then
      expect(todayResponses.length, 2);
      expect(todayResponses[0].surveyId, 'survey_001');
      expect(todayResponses[1].surveyId, 'survey_002');
    });

    test('설문 질문 타입이 올바르게 설정되어야 함', () {
      final survey = container.read(surveyStateProvider).mockSurveys[0];
      
      expect(survey.questions[0].type, QuestionType.single);
      expect(survey.questions[2].type, QuestionType.multiple);
    });

    test('resetDaily는 일일 포인트를 초기화해야 함', () async {
      // Given
      await surveyNotifier.submitSurvey('survey_001', {0: 0, 1: 1, 2: [0]});
      expect(container.read(surveyStateProvider).todayPoints, 30);
      
      // When
      surveyNotifier.resetDaily();
      final state = container.read(surveyStateProvider);
      
      // Then
      expect(state.todayPoints, 0);
      expect(state.completedSurveyIds, isNotEmpty); // 완료 기록은 유지
    });

    test('각 설문 카테고리가 다르게 설정되어야 함', () {
      final surveys = container.read(surveyStateProvider).mockSurveys;
      
      expect(surveys[0].category, '교통');
      expect(surveys[1].category, '쇼핑');
      expect(surveys[2].category, '건강');
    });
  });
}