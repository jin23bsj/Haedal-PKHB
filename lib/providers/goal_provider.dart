import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/goal_rate_entry.dart';
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

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 특정 목표의 히스토리 (최신순)
  List<GoalRateEntry> getHistory(int goalId) {
    return (_rateHistory[goalId] ?? [])
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // 기록 탭에서 저장할 때 호출 — 메모나 달성률 변화가 있을 때만 저장
  void addRateEntry({
    required int goalId,
    required double prevRate,
    required double newRate,
    required String memo,
  }) {
    final entry = GoalRateEntry(
      date: DateTime.now(),
      prevRate: prevRate,
      newRate: newRate,
      memo: memo,
    );
    if (!entry.shouldShow) return; // 변화 없고 메모도 없으면 저장 안 함
    _rateHistory.putIfAbsent(goalId, () => []).add(entry);
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

    try {
      _goals = await _service.getGoals();
    } catch (e) {
      // 백엔드 연결 안 됐을 때 → 샘플 데이터로 대체
      _goals = _mockGoals;
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
      // 백엔드 없을 때도 로컬에서 추가
      final localGoal = goal.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      _goals.insert(0, localGoal);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateGoal(int id, Goal goal) async {
    try {
      final updated = await _service.updateGoal(id, goal);
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        _goals[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      // 백엔드 없을 때도 로컬에서 수정
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        _goals[index] = goal.copyWith(id: id);
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await _service.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      // 백엔드 없을 때도 로컬에서 삭제
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
