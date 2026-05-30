class DailyRecord {
  final int? id;
  final DateTime date;
  final String emotion;
  final int emotionScore;
  final List<String> actions;
  final String memo;
  final List<int> relatedGoalIds;
  final Map<int, String> goalProgressMemos;
  final double? achievementScore;
  final String futureMessage;
  final DateTime createdAt;

  DailyRecord({
    this.id,
    required this.date,
    required this.emotion,
    required this.emotionScore,
    required this.actions,
    this.memo = '',
    this.relatedGoalIds = const [],
    this.goalProgressMemos = const {},
    this.achievementScore,
    this.futureMessage = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final tags = List<String>.from(json['emotion_tags'] ?? []);
    final emoji = _tagsToEmoji(tags);
    final moodScore = (json['mood_score'] ?? 6) as int;
    final emotionScore = (moodScore / 2).round().clamp(1, 5);

    final parsedGoalMemos = <int, String>{};
    final rawGoalMemos = json['goal_progress_memos'];
    if (rawGoalMemos is Map) {
      rawGoalMemos.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id != null && value != null) {
          parsedGoalMemos[id] = value.toString();
        }
      });
    }

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
      goalProgressMemos: parsedGoalMemos,
      achievementScore: (json['achievement_score'] as num?)?.toDouble(),
      futureMessage: json['future_message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_date': date.toIso8601String().split('T').first,
      'mood_score': (emotionScore * 2).clamp(1, 10),
      'emotion_tags': [_emojiToTag(emotion)],
      'behaviors': actions,
      'note': memo,
      'related_goal_ids': relatedGoalIds,
      'goal_progress_memos': goalProgressMemos.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      if (achievementScore != null) 'achievement_score': achievementScore,
      'future_message': futureMessage,
    };
  }

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

class Emotions {
  static const List<Map<String, dynamic>> list = [
    {'label': '최고', 'emoji': '🤩', 'score': 5, 'color': 0xFFFFD93D},
    {'label': '행복', 'emoji': '😊', 'score': 4, 'color': 0xFFB5EAD7},
    {'label': '보통', 'emoji': '😐', 'score': 3, 'color': 0xFFFFD4C2},
    {'label': '피곤', 'emoji': '😴', 'score': 2, 'color': 0xFFC7CEEA},
    {'label': '힘듦', 'emoji': '😢', 'score': 1, 'color': 0xFFFFB7B2},
  ];
}
