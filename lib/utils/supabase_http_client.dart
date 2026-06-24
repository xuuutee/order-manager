import 'supabase_http_client_native.dart'
    if (dart.library.html) 'supabase_http_client_web.dart';

/// DNS 感知 HTTP 客户端 — 平台自适应
///
/// - Android/iOS/Desktop: SupabaseHttpClientNative (SecureSocket IP直连+SNI)
/// - Web: SupabaseHttpClientWeb (标准客户端+DoH预热)
typedef SupabaseHttpClient = SupabaseHttpClientNative;
