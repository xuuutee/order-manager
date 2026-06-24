import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dns_resolver.dart';

/// Web 版 HTTP 客户端 — 纯 DNS 回退（无 dart:io）
///
/// Web 运行在 PC 上通常已有 hosts 文件修复，仅做预热 + 错误提示。
class SupabaseHttpClientWeb extends http.BaseClient {
  final String _supabaseHost;
  final http.Client _inner;

  SupabaseHttpClientWeb(this._supabaseHost) : _inner = http.Client();

  Future<void> warmup() async {
    try {
      await DnsResolver.warmDns(_supabaseHost);
      debugPrint('[HttpClient:Web] DNS warmup OK');
    } catch (e) {
      debugPrint('[HttpClient:Web] DNS warmup failed: $e');
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request).timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      throw http.ClientException(
        '网络连接失败 ($_supabaseHost)\n'
        '请右键管理员运行 setup_hosts.bat',
      );
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
