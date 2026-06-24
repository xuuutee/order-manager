/// Supabase 配置
///
/// 如果使用自定义反代域名，修改 [supabaseUrl] 指向你的 Worker/反代地址。
/// 建议将密钥迁入 .env 文件或 CI 环境变量，而非硬编码于此。
class AppConfig {
  /// Supabase API 地址
  ///
  /// 大陆优化：可替换为 Cloudflare Worker 反代域名，绕过 DNS 污染。
  /// 示例：`https://supabase-proxy.your-domain.com`
  static const supabaseUrl = 'https://uqaggeaiqcmsxkikyfvl.supabase.co';

  /// Supabase Anon Key（publishable key，可公开）
  static const supabaseAnonKey =
      'sb_publishable_aMpoSSWQEvtlxxsv55UFWQ_bRUR7a8V';

  /// 共享账号（MVP 阶段硬编码，用于自动登录）
  /// 请在 Supabase Authentication → Users → Add User 创建对应账号
  static const sharedEmail = 'wangkedaixie@studio.com';
  static const sharedPassword = '88888888';

  /// 连接超时（秒）
  static const connectTimeoutSeconds = 15;

  /// 最大重试次数
  static const maxRetries = 3;
}
