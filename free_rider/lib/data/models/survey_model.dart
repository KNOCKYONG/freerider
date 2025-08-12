enum QuestionType {
  single, // 단일 선택
  multiple, // 다중 선택
  text, // 텍스트 입력
  scale, // 척도 (1-5, 1-10 등)
}

class Survey {
  final String id;
  final String title;
  final String description;
  final int points;
  final List<SurveyQuestion> questions;
  final String category;
  final int estimatedTime; // 분
  final DateTime? expiresAt;
  final Map<String, dynamic>? targetCriteria;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.questions,
    required this.category,
    required this.estimatedTime,
    this.expiresAt,
    this.targetCriteria,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'questions': questions.map((q) => q.toJson()).toList(),
      'category': category,
      'estimatedTime': estimatedTime,
      'expiresAt': expiresAt?.toIso8601String(),
      'targetCriteria': targetCriteria,
    };
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      questions: (json['questions'] as List)
          .map((q) => SurveyQuestion.fromJson(q))
          .toList(),
      category: json['category'],
      estimatedTime: json['estimatedTime'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      targetCriteria: json['targetCriteria'],
    );
  }
}

class SurveyQuestion {
  final String id;
  final String text;
  final String? description;
  final QuestionType type;
  final List<SurveyOption> options;
  final bool isRequired;
  final Map<String, dynamic>? validation;

  SurveyQuestion({
    required this.id,
    required this.text,
    this.description,
    required this.type,
    required this.options,
    this.isRequired = true,
    this.validation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'description': description,
      'type': type.toString(),
      'options': options.map((o) => o.toJson()).toList(),
      'isRequired': isRequired,
      'validation': validation,
    };
  }

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'],
      text: json['text'],
      description: json['description'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => QuestionType.single,
      ),
      options: (json['options'] as List)
          .map((o) => SurveyOption.fromJson(o))
          .toList(),
      isRequired: json['isRequired'] ?? true,
      validation: json['validation'],
    );
  }
}

class SurveyOption {
  final String id;
  final String text;
  final dynamic value;
  final String? imageUrl;

  SurveyOption({
    required this.id,
    required this.text,
    this.value,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'value': value,
      'imageUrl': imageUrl,
    };
  }

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      id: json['id'],
      text: json['text'],
      value: json['value'],
      imageUrl: json['imageUrl'],
    );
  }
}

class SurveyResponse {
  final String id;
  final String surveyId;
  final String userId;
  final Map<String, dynamic> answers;
  final DateTime completedAt;
  final int pointsEarned;

  SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.userId,
    required this.answers,
    required this.completedAt,
    required this.pointsEarned,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surveyId': surveyId,
      'userId': userId,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'],
      surveyId: json['surveyId'],
      userId: json['userId'],
      answers: json['answers'],
      completedAt: DateTime.parse(json['completedAt']),
      pointsEarned: json['pointsEarned'],
    );
  }
}