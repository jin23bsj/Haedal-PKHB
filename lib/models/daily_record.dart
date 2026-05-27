class DailyRecord {
  final int? id;
  final DateTime date;         // Flutter 내부 필드명 유지
  final String emotion;        // 이모지 그대로 유지 (😊 등)
  final int emotionScore;      // 1~5 (Flutter 내부), 백엔드 전송 시 x2 → 1~10
  final List<String> actions;  // Flutter 내부 필드명 유지 (백엔드: behaviors)
  final String memo;           // Flutter 내부 필드명 유지 (백엔드: note)
  final List<int> relatedGoalIds;
  final double? achievementScore; // 0~100 (백엔드 achievement_score)
  final DateTime createdAt;

  DailyRecord({
    this.id,
    required this.date,
    required this.emotion,
    required this.emotionScore,
    required this.actions,
    this.memo = '',
    this.relatedGoalIds = const [],
    this.achievementScore,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 백엔드 응답 JSON → Flutter 모델
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    // emotion_tags 배열 → 이모지로 변환
    final tags = List<String>.from(json['emotion_tags'] ?? []);
    final emoji = _tagsToEmoji(tags);

    // mood_score(1~10) → emotionScore(1~5)
    final moodScore = (json['mood_score'] ?? 6) as int;
    final emotionScore = (moodScore / 2).round().clamp(1, 5);

    return DailyRecord(
      id: json['id'],
      date: json['record_date'] != null
          ? DateTime.parse(json['record_date'])
          : DateTime.now(),
      emotion: emoji,
      emotionScore: emotionScore,
      actions: List<String>.from(json['behaviors'] ?? []),
      memo: json['note'] ?? '',
      relatedGoalIds: List<int>.from(json['related_goal_ids'] ?? []),
      achievementScore: (json['achievement_score'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // Flutter 모델 → 백엔드 요청 JSON
  Map<String, dynamic> toJson() {
    return {
      'record_date': date.toIso8601String().split('T').first,
      'mood_score': (emotionScore * 2).clamp(1, 10), // 1~5 → 2~10
      'emotion_tags': [_emojiToTag(emotion)],         // 이모지 → 태그
      'behaviors': actions,
      'note': memo,
      'related_goal_ids': relatedGoalIds,
      if (achievementScore != null) 'achievement_score': achievementScore,
    };
  }

  // 이모지 → 백엔드 감정 태그
  static String _emojiToTag(String emoji) {
    const map = {
      '🤩': '최고',
      '😊': '행복',
      '😐': '보통',
      '😴': '피곤',
      '😢': '힘듦',
    };
    return map[emoji] ?? '보통';
  }

  // 백엔드 감정 태그 → 이모지
  static String _tagsToEmoji(List<String> tags) {
    if (tags.isEmpty) return '😐';
    const map = {
      '최고': '🤩',
      '행복': '😊',
      '보통': '😐',
      '피곤': '😴',
      '힘듦': '😢',
      '기쁨': '😊',
      '불안': '😴',
      '슬픔': '😢',
    };
    return map[tags.first] ?? '😐';
  }
}

// 감정 상수 (UI용)
class Emotions {
  static const List<Map<String, dynamic>> list = [
    {'label': '최고', 'emoji': '🤩', 'score': 5, 'color': 0xFFFFD93D},
    {'label': '행복', 'emoji': '😊', 'score': 4, 'color': 0xFFB5EAD7},
    {'label': '보통', 'emoji': '😐', 'score': 3, 'color': 0xFFFFD4C2},
    {'label': '피곤', 'emoji': '😴', 'score': 2, 'color': 0xFFC7CEEA},
    {'label': '힘듦', 'emoji': '😢', 'score': 1, 'color': 0xFFFFB7B2},
  ];
}
