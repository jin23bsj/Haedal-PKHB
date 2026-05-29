class GoalStatus {
  static const String active = 'active';
  static const String completed = 'completed';
  static const String abandoned = 'abandoned';
}

class Goal {
  final int? id;
  final String title;
  final String? description;
  final String? category;
  final DateTime? targetDate;
  final String status;
  final double achievementRate; // 0.0~1.0, 백엔드 achievement_rate와 연동
  final DateTime createdAt;

  Goal({
    this.id,
    required this.title,
    this.description,
    this.category,
    this.targetDate,
    this.status = GoalStatus.active,
    this.achievementRate = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status == GoalStatus.completed;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : null,
      status: json['status'] ?? GoalStatus.active,
      achievementRate: (json['achievement_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 백엔드로 보낼 때 (achievementRate 제외)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T').first,
    };
  }

  // 수정용 PATCH
  Map<String, dynamic> toPatchJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T').first,
      'status': status,
      'achievement_rate': achievementRate,
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    DateTime? targetDate,
    String? status,
    double? achievementRate,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      achievementRate: achievementRate ?? this.achievementRate,
      createdAt: createdAt,
    );
  }
}
