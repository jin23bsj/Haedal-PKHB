import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final _dio = ApiService.dio;
  static const _tokenKey = 'access_token';

  // 회원가입
  Future<String> register({
    required String email,
    required String nickname,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'nickname': nickname,
      'password': password,
    });
    final token = res.data['access_token'];
    await _saveToken(token);
    return token;
  }

  // 로그인
  Future<String> login({
    required String email,
    required String password,
  }) async {
    // OAuth2 form 형식으로 전송
    final res = await _dio.post(
      '/auth/login',
      data: 'username=$email&password=$password',
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    final token = res.data['access_token'];
    await _saveToken(token);
    return token;
  }

  // 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiService.clearToken();
  }

  // 저장된 토큰 불러오기
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiService.setToken(token);
  }
}
