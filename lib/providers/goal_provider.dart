import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/goal_rate_entry.dart';
import '../models/daily_record.dart';
import '../services/goal_service.dart';

// ✅ 백엔드 연결 전 UI 테스트용 샘플 데이터
final _mockGoals = [
  Goal(
    id: 1,
    title: '매일 30분 운동하기',
    description: '건강한 몸을 위해 꾸준히 운동하자',
    category: '건강',
    targetDate: DateTime.now().add(const Duration(days: 60)),
    achievementRate: 0.65,
  ),
  Goal(
    id: 2,
    title: '플러터 앱 완성하기',
    description: '해커톤 전까지 Dream Achiever 앱 완성',
    category: '공부',
    targetDate: DateTime.now().add(const Duration(days: 14)),
    achievementRate: 0.40,
  ),
  Goal(
    id: 3,
    title: '독서 월 2권',
    description: '꾸준한 독서 습관 만들기',
    category: '취미',
    targetDate: DateTime.now().add(const Duration(days: 30)),
    achievementRate: 0.50,
  ),
  Goal(
    id: 4,
    title: '토익 800점 달성',
    description: '취업 준비를 위한 영어 공부',
    category: '커리어',
    targetDate: DateTime.now().add(const Duration(days: 90)),
    achievementRate: 0.30,
  ),
  Goal(
    id: 5,
    title: '금연 성공 🎉',
    description: '건강을 위해 담배 끊기',
    category: '건강',
    targetDate: DateTime.now().subtract(const Duration(days: 10)),
    achievementRate: 1.0,
    status: GoalStatus.completed,
  ),
];

class GoalProvider extends ChangeNotifier {
  final GoalService _service = GoalService();

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 목표별 달성률 히스토리: goalId → [GoalRateEntry, ...]
  final Map<int, List<GoalRateEntry>> _rateHistory = {};

  // 로컬 저장된 달성률: goalId → achievementRate
  final Map<int, double> _localRates = {};

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 특정 목표의 히스토리 (최신순)
  List<GoalRateEntry> getHistory(int goalId) {
    return List.from(_rateHistory[goalId] ?? [])
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // SharedPreferences에서 로컬 달성률 불러오기
  Future<void> _loadLocalRates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('goal_rates');
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map.forEach((k, v) {
        _localRates[int.parse(k)] = (v as num).toDouble();
      });
    }
  }

  // SharedPreferences에서 히스토리 불러오기
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('goal_rate_history');
    if (raw == null) return;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      map.forEach((goalIdStr, entries) {
        final goalId = int.tryParse(goalIdStr);
        if (goalId == null) return;
        final list = (entries as List).map((e) {
          final m = e as Map<String, dynamic>;
          return GoalRateEntry(
            date: DateTime.parse(m['date']),
            prevRate: (m['prevRate'] as num).toDouble(),
            newRate: (m['newRate'] as num).toDouble(),
            memo: m['memo'] ?? '',
          );
        }).toList();
        _rateHistory[goalId] = list;
      });
    } catch (_) {}
  }

  // SharedPreferences에 히스토리 저장
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _rateHistory.forEach((goalId, entries) {
      map[goalId.toString()] = entries.map((e) => {
        'date': e.date.toIso8601String(),
        'prevRate': e.prevRate,
        'newRate': e.newRate,
        'memo': e.memo,
      }).toList();
    });
    await prefs.setString('goal_rate_history', json.encode(map));
  }

  // SharedPreferences에 로컬 달성률 저장
  Future<void> _saveLocalRates() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, double>{};
    _localRates.forEach((k, v) => map[k.toString()] = v);
    await prefs.setString('goal_rates', json.encode(map));
  }

  // 일일 기록 데이터로 히스토리 복원 (앱 시작 시 호출)
  void rebuildHistoryFromRecords(List<DailyRecord> records) {
    // goalRates가 있는 기록만 처리, 날짜 오름차순
    final sorted = records
        .where((r) => r.goalRates.isNotEmpty)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 기존 SharedPreferences 히스토리가 있으면 스킵 (이미 있는 데이터 우선)
    if (_rateHistory.isNotEmpty) return;

    final Map<int, double> prevRates = {};

    for (final record in sorted) {
      record.goalRates.forEach((goalId, newRate) {
        final prevRate = prevRates[goalId] ?? 0.0;
        final memo = record.goalProgressMemos[goalId] ?? '';
        final entry = GoalRateEntry(
          date: record.date,
          prevRate: prevRate,
          newRate: newRate,
          memo: memo,
        );
        if (entry.shouldShow) {
          final list = _rateHistory.putIfAbsent(goalId, () => []);
          final sameDay = list.indexWhere((e) =>
              e.date.year == record.date.year &&
              e.date.month == record.date.month &&
              e.date.day == record.date.day);
          if (sameDay != -1) {
            list[sameDay] = entry;
          } else {
            list.add(entry);
          }
        }
        prevRates[goalId] = newRate;
      });
    }

    if (_rateHistory.isNotEmpty) {
      notifyListeners();
      _saveHistory();
    }
  }

  // 백엔드에서 받은 목표에 로컬 달성률 합치기
  List<Goal> _mergeRates(List<Goal> goals) {
    return goals.map((g) {
      if (g.id != null && _localRates.containsKey(g.id)) {
        return g.copyWith(achievementRate: _localRates[g.id!]!);
      }
      return g;
    }).toList();
  }

  // 기록 탭에서 저장할 때 호출 — 메모나 달성률 변화가 있을 때만 저장
  void addRateEntry({
    required int goalId,
    required double prevRate,
    required double newRate,
    required String memo,
    DateTime? date,
  }) {
    final entryDate = date ?? DateTime.now();
    final entry = GoalRateEntry(
      date: entryDate,
      prevRate: prevRate,
      newRate: newRate,
      memo: memo,
    );
    if (!entry.shouldShow) return;

    final list = _rateHistory.putIfAbsent(goalId, () => []);

    // 같은 날짜 항목이 있으면 덮어쓰기 (수정 모드 대응)
    final sameDay = list.indexWhere((e) =>
        e.date.year == entryDate.year &&
        e.date.month == entryDate.month &&
        e.date.day == entryDate.day);
    if (sameDay != -1) {
      list[sameDay] = entry; // 기존 항목 갱신
    } else {
      list.add(entry); // 새 날짜면 추가
    }

    // 가장 최신 날짜 entry의 newRate로 goal 달성률 업데이트
    final history = _rateHistory[goalId]!;
    final latestEntry = history.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx != -1 && _goals[idx].achievementRate != latestEntry.newRate) {
      _goals[idx] = _goals[idx].copyWith(achievementRate: latestEntry.newRate);
      _localRates[goalId] = latestEntry.newRate;
      _saveLocalRates();
    }

    _saveHistory(); // 히스토리 로컬 저장

    notifyListeners();
  }

  // 진행 중인 목표만
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();

  // 완료된 목표만
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();

  // 평균 달성률
  double get averageAchievement {
    if (_goals.isEmpty) return 0;
    final sum = _goals.fold(0.0, (acc, g) => acc + g.achievementRate);
    return sum / _goals.length;
  }

  Future<void> fetchGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _loadLocalRates();
    await _loadHistory();

    try {
      final fetched = await _service.getGoals();
      _goals = _mergeRates(fetched);
    } catch (e) {
      _goals = _mergeRates(_mockGoals);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoal(Goal goal) async {
    try {
      final newGoal = await _service.createGoal(goal);
      _goals.insert(0, newGoal);
      notifyListeners();
      return true;
    } catch (e) {
      final localGoal = goal.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      _goals.insert(0, localGoal);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateGoal(int id, Goal goal) async {
    // 달성률은 로컬에 저장
    _localRates[id] = goal.achievementRate;
    await _saveLocalRates();

    try {
      final updated = await _service.updateGoal(id, goal);
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        // 백엔드 응답에 달성률 다시 적용
        _goals[index] = updated.copyWith(achievementRate: goal.achievementRate);
        notifyListeners();
      }
      return true;
    } catch (e) {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        _goals[index] = goal.copyWith(id: id);
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> deleteGoal(int id) async {
    _localRates.remove(id);
    await _saveLocalRates();

    try {
      await _service.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
