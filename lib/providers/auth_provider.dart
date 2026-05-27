import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 앱 시작 시 저장된 토큰 확인
  Future<void> checkSavedToken() async {
    final token = await _service.getSavedToken();
    if (token != null) {
      ApiService.setToken(token);
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String nickname,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.register(email: email, nickname: nickname, password: password);
      _isLoggedIn = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('이미') ? '이미 가입된 이메일이에요' : '회원가입에 실패했어요';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.login(email: email, password: password);
      _isLoggedIn = true;
      return true;
    } catch (e) {
      _errorMessage = '이메일 또는 비밀번호를 확인해주세요';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _isLoggedIn = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
