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
      debugPrint('🔐 Login attempt: ${AppConfig.sharedEmail}');
      debugPrint('🔗 URL: ${AppConfig.supabaseUrl}');
      debugPrint('🔑 Key prefix: ${AppConfig.supabaseAnonKey.substring(0, 16)}...');

      await _client.auth.signInWithPassword(
        email: AppConfig.sharedEmail,
        password: AppConfig.sharedPassword,
      );
      _isLoggedIn = true;
      _isLoading = false;
      debugPrint('✅ Login success');
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message} (code: ${e.statusCode})');
      _error = '${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      _error = '登录失败（${e.toString().substring(0, e.toString().length.clamp(0, 60))}）';
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
