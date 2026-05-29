import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Chrome → localhost, Android 에뮬레이터 → 10.0.2.2, 실제폰 → 팀원 PC IP
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // 데모 계정 (백엔드 켜지면 자동으로 이 계정으로 로그인)
  static const String _demoEmail = 'test@example.com';
  static const String _demoPassword = 'test1234';
  static const String _demoNickname = '테스트 사용자';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get dio => _dio;

  /// 앱 시작 시 main.dart에서 호출.
  /// 저장된 토큰 확인 → 없으면 데모 계정으로 자동 로그인
  static Future<void> initialize() async {
    _setupInterceptor();

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token');

    if (savedToken != null && savedToken.isNotEmpty) {
      _setToken(savedToken);
      try {
        await _dio.get('/auth/me');
        return; // 토큰 유효 → 그대로 사용
      } catch (_) {
        await prefs.remove('access_token');
        _dio.options.headers.remove('Authorization');
      }
    }

    // 토큰 없거나 만료 → 데모 계정으로 자동 로그인
    await _loginOrRegister();
  }

  static Future<void> _loginOrRegister() async {
    try {
      await _loginDemo();
    } catch (_) {
      try {
        await _registerDemo();
        await _loginDemo();
      } catch (_) {
        // 백엔드가 꺼져 있어도 앱은 실행됨 (mock 데이터로 동작)
      }
    }
  }

  static void _setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // auth_provider, auth_service에서 사용하는 공개 버전
  static void setToken(String token) => _setToken(token);

  static void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  static Future<void> _loginDemo() async {
    final res = await _dio.post(
      '/auth/login',
      data: 'username=$_demoEmail&password=$_demoPassword',
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final token = res.data['access_token'].toString();
    _setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> _registerDemo() async {
    await _dio.post('/auth/register', data: {
      'email': _demoEmail,
      'nickname': _demoNickname,
      'password': _demoPassword,
    });
  }

  static void _setupInterceptor() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        handler.next(e);
      },
    ));
  }

  static String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) return detail.map((i) => i.toString()).join('\n');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '서버 연결 시간이 초과됐어요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없어요. 백엔드가 켜져 있는지 확인해주세요.';
      default:
        return '오류가 발생했습니다.';
    }
  }
}
