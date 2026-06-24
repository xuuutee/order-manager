import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 检查当前登录状态
  Future<void> checkAuth() async {
    final session = _client.auth.currentSession;
    _isLoggedIn = session != null;
    notifyListeners();
  }

  /// 使用共享账号登录
  Future<bool> login() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signInWithPassword(
        email: AppConfig.sharedEmail,
        password: AppConfig.sharedPassword,
      );
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '登录失败，请检查网络';
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
