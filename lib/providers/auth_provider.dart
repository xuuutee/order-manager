import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userEmail => _client.auth.currentUser?.email;

  /// 检查当前登录会话
  Future<void> checkAuth() async {
    final session = _client.auth.currentSession;
    _isLoggedIn = session != null;
    debugPrint('🔐 Session check: ${_isLoggedIn ? "logged in" : "no session"}');
    notifyListeners();
  }

  /// 邮箱密码登录
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _isLoggedIn = true;
      _isLoading = false;
      debugPrint('✅ Login success');
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message} (code: ${e.statusCode})');
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      _error = '登录失败，请检查网络连接';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _client.auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }
}
