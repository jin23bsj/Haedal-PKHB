import 'package:dio/dio.dart';
import '../models/daily_record.dart';
import 'api_service.dart';

class RecordService {
  final _dio = ApiService.dio;

  Future<List<DailyRecord>> getRecords({int limit = 30}) async {
    final res = await _dio.get('/records', queryParameters: {'limit': limit});
    final List data = res.data is List ? res.data : res.data['data'];
    return data.map((e) => DailyRecord.fromJson(e)).toList();
  }

  Future<DailyRecord?> getRecordByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    try {
      final res = await _dio.get('/records/by-date/$dateStr');
      return DailyRecord.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<DailyRecord> createRecord(DailyRecord record) async {
    try {
      final res = await _dio.post('/records', data: record.toJson());
      return DailyRecord.fromJson(res.data);
    } on DioException catch (e) {
      // 오늘 기록이 이미 있으면 → 기존 기록 찾아서 PATCH로 수정
      if (e.response?.statusCode == 400) {
        final existing = await getRecordByDate(record.date);
        if (existing?.id != null) {
          return await updateRecord(existing!.id!, record);
        }
      }
      rethrow;
    }
  }

  // 백엔드는 PATCH 사용
  Future<DailyRecord> updateRecord(int id, DailyRecord record) async {
    final res = await _dio.patch('/records/$id', data: record.toJson());
    return DailyRecord.fromJson(res.data);
  }

  Future<void> deleteRecord(int id) async {
    await _dio.delete('/records/$id');
  }

  // 성장 요약 (streak 등)
  Future<Map<String, dynamic>> getGrowthSummary() async {
    final res = await _dio.get('/analysis/growth');
    return Map<String, dynamic>.from(res.data);
  }

  // 기간 비교 분석
  Future<Map<String, dynamic>> getComparison({int periodDays = 7}) async {
    final res = await _dio.get('/analysis/comparison',
        queryParameters: {'period_days': periodDays});
    return Map<String, dynamic>.from(res.data);
  }
}
