import '../models/goal.dart';
import 'api_service.dart';

class GoalService {
  final _dio = ApiService.dio;

  Future<List<Goal>> getGoals({String? status}) async {
    final res = await _dio.get('/goals',
        queryParameters: status != null ? {'status': status} : null);
    final List data = res.data is List ? res.data : res.data['data'];
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  Future<Goal> createGoal(Goal goal) async {
    final res = await _dio.post('/goals', data: goal.toJson());
    return Goal.fromJson(res.data);
  }

  // 백엔드는 PATCH 사용
  Future<Goal> updateGoal(int id, Goal goal) async {
    final res = await _dio.patch('/goals/$id', data: goal.toPatchJson());
    return Goal.fromJson(res.data);
  }

  Future<void> deleteGoal(int id) async {
    await _dio.delete('/goals/$id');
  }

  // 목표 진행 시계열 (분석 차트용)
  Future<Map<String, dynamic>> getGoalProgress(int goalId) async {
    final res = await _dio.get('/analysis/goals/$goalId/progress');
    return Map<String, dynamic>.from(res.data);
  }
}
