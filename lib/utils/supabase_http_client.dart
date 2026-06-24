import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dns_resolver.dart';

/// DNS 感知 HTTP 客户端
///
/// 在系统 DNS 解析前用 DoH 预热，触发 OS 缓存。
/// 不直连 IP（TLS SNI 问题），仅做预热 + 监控。
class SupabaseHttpClient extends http.BaseClient {
  final String _supabaseHost;
  final http.Client _inner;
  bool _warmed = false;

  SupabaseHttpClient(this._supabaseHost) : _inner = http.Client();

  /// DoH 预解析 + TCP 连通测试
  Future<void> warmup() async {
    try {
      await DnsResolver.warmDns(_supabaseHost);
      _warmed = true;
      debugPrint('[SupabaseHttpClient] DNS warmup OK');
    } catch (e) {
      debugPrint('[SupabaseHttpClient] DNS warmup failed: $e');
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 如果未预热，尝试快速预热
    if (!_warmed && request.url.host == _supabaseHost) {
      warmup(); // fire-and-forget
    }

    try {
      return await _inner.send(request).timeout(
        const Duration(seconds: 15),
      );
    } on SocketException catch (e) {
      throw http.ClientException(
        '网络连接失败 ($_supabaseHost): ${e.message}\n'
        '请检查网络或运行 setup_hosts.bat',
      );
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
