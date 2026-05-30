import 'package:flutter/foundation.dart';
import '../models/daily_record.dart';
import '../services/record_service.dart';

// ✅ 백엔드 연결 전 UI 테스트용 샘플 데이터
List<DailyRecord> _buildMockRecords() {
  final now = DateTime.now();
  final emotions = [
    {'emoji': '😊', 'score': 4},
    {'emoji': '😐', 'score': 3},
    {'emoji': '🤩', 'score': 5},
    {'emoji': '😴', 'score': 2},
    {'emoji': '😊', 'score': 4},
    {'emoji': '😊', 'score': 4},
    {'emoji': '😐', 'score': 3},
    {'emoji': '🤩', 'score': 5},
    {'emoji': '😢', 'score': 1},
    {'emoji': '😊', 'score': 4},
    {'emoji': '😴', 'score': 2},
    {'emoji': '😊', 'score': 4},
    {'emoji': '🤩', 'score': 5},
    {'emoji': '😐', 'score': 3},
  ];
  final actionPool = [
    ['운동', '독서'],
    ['공부', '산책'],
    ['운동', '자기개발', '독서'],
    ['휴식'],
    ['공부', '친구 만남'],
    ['운동', '요리'],
    ['독서', '산책'],
    ['공부', '운동', '명상'],
    ['휴식', '독서'],
    ['운동', '자기개발'],
    ['요리', '산책'],
    ['공부', '명상'],
    ['운동', '독서', '요리'],
    ['자기개발', '산책'],
  ];

  return List.generate(emotions.length, (i) {
    return DailyRecord(
      id: i + 1,
      date: now.subtract(Duration(days: i)),
      emotion: emotions[i]['emoji'] as String,
      emotionScore: emotions[i]['score'] as int,
      actions: actionPool[i],
      memo: i == 0 ? '오늘도 열심히 했다!' : '',
    );
  });
}

final _mockSummary = {
  'streak': 7,
  'totalDays': 14,
  'topAction': '운동',
  'topActions': ['운동', '공부', '독서'],
};

final _mockComparison = {
  'pastAvgScore': 3.1,
  'currentAvgScore': 3.8,
  'insight': '최근 한 달 감정 점수가 이전보다 0.7 올랐어요! 꾸준한 운동이 큰 도움이 된 것 같아요 💪',
};

class RecordProvider extends ChangeNotifier {
  final RecordService _service = RecordService();

  List<DailyRecord> _records = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _comparison = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<DailyRecord> get records => _records;
  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get comparison => _comparison;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 오늘 기록 여부
  bool get hasTodayRecord {
    final today = DateTime.now();
    return _records.any((r) =>
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day);
  }

  // 오늘 기록 객체
  DailyRecord? get todayRecord {
    final today = DateTime.now();
    try {
      return _records.firstWhere((r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day);
    } catch (_) {
      return null;
    }
  }

  // 총 기록일 수
  int get totalRecordDays => _records.length;

  // 연속 기록일 (오늘 또는 어제부터 역순으로 연속된 날 수)
  int get streakDays {
    if (_records.isEmpty) return 0;

    // 날짜만 추출해서 최신순 정렬 (중복 제거)
    final dates = _records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 오늘 또는 어제 기록이 없으면 streak 0
    if (dates.first != today && dates.first != yesterday) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // 최근 7일 기록
  List<DailyRecord> get recentRecords {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _records.where((r) => r.date.isAfter(weekAgo)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> fetchRecords({Function(List<dynamic>)? onLoaded}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _service.getRecords();
    } catch (e) {
      _records = _buildMockRecords();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // 기록 로드 후 콜백 (GoalProvider 히스토리 복원에 사용)
    onLoaded?.call(_records);
  }

  Future<void> fetchSummary() async {
    try {
      _summary = await _service.getGrowthSummary();
      notifyListeners();
    } catch (e) {
      // 백엔드 없을 때 샘플 요약
      _summary = _mockSummary;
      notifyListeners();
    }
  }

  Future<bool> createRecord(DailyRecord record) async {
    try {
      final newRecord = await _service.createRecord(record);
      _records.insert(0, newRecord);
      notifyListeners();
      return true;
    } catch (e) {
      // 백엔드 없을 때도 로컬에서 추가
      final localRecord = DailyRecord(
        id: DateTime.now().millisecondsSinceEpoch,
        date: record.date,
        emotion: record.emotion,
        emotionScore: record.emotionScore,
        actions: record.actions,
        memo: record.memo,
      );
      _records.insert(0, localRecord);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateRecord(int id, DailyRecord record) async {
    try {
      final updated = await _service.updateRecord(id, record);
      final index = _records.indexWhere((r) => r.id == id);
      if (index != -1) {
        _records[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(int id) async {
    try {
      await _service.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchComparison({int periodDays = 7}) async {
    try {
      _comparison = await _service.getComparison(periodDays: periodDays);
      notifyListeners();
    } catch (e) {
      // 백엔드 없을 때 샘플 비교 데이터
      _comparison = _mockComparison;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
