import 'auth_config.dart';

/// Supabase 配置 & 应用版本
class AppConfig {
  static const supabaseUrl = 'https://uqaggeaiqcmsxkikyfvl.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_aMpoSSWQEvtlxxsv55UFWQ_bRUR7a8V';

  /// 当前 App 版本号（整数，用于比对更新）
  static const versionCode = 4;
  /// 当前 App 版本名（展示用）
  static const versionName = '1.0.4';

  /// 共享登录账号
  static const sharedEmail = AuthConfig.email;
  static const sharedPassword = AuthConfig.password;
}
