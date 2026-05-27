import 'api_service.dart';

class ChatService {
  final _dio = ApiService.dio;

  // 백엔드 Gemini 챗봇으로 전송 (최근 7일 기록 자동 주입)
  Future<String> sendMessage(String message) async {
    final res = await _dio.post('/chat/message', data: {
      'message': message,
      'include_recent_context': true, // 백엔드가 최근 7일 기록 자동 주입
    });
    return res.data['reply'] ?? '응답을 받지 못했어요 😅';
  }
}
