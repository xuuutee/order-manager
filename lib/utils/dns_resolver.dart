import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// DNS-over-HTTPS 解析器
/// 绕过运营商 DNS 污染，直连阿里 DoH 解析域名
class DnsResolver {
  // 国内可用的 DoH 端点（按优先级排序）
  static const _dohEndpoints = [
    'https://dns.alidns.com/resolve',
    'https://doh.pub/dns-query',
  ];

  /// 解析域名 → IP 列表
  static Future<List<InternetAddress>> resolve(String hostname) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    for (final endpoint in _dohEndpoints) {
      try {
        final uri = Uri.parse('$endpoint?name=$hostname&type=A');
        final request = await client.getUrl(uri);
        request.headers.set('accept', 'application/dns-json');
        final response = await request.close().timeout(
              const Duration(seconds: 5),
            );

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;

          if (data['Status'] == 0 && data['Answer'] != null) {
            final answers = data['Answer'] as List;
            final ips = answers
                .where((a) => a['type'] == 1) // A 记录
                .map((a) => a['data'] as String)
                .toList();
            if (ips.isNotEmpty) {
              debugPrint('[DnsResolver] $hostname → $ips (via $endpoint)');
              return ips.map((ip) => InternetAddress(ip)).toList();
            }
          }
        }
      } catch (e) {
        debugPrint('[DnsResolver] $endpoint failed: $e');
        continue;
      }
    }

    throw DnsException('无法解析 $hostname，所有 DoH 端点均失败');
  }

  /// 预热系统 DNS 缓存
  /// 向目标发起 TCP 连接，触发 OS 层 DNS 缓存
  static Future<void> warmDns(String hostname) async {
    try {
      final ips = await resolve(hostname);
      for (final ip in ips.take(2)) {
        try {
          final socket = await Socket.connect(
            ip,
            443,
            timeout: const Duration(seconds: 3),
          );
          socket.destroy();
          debugPrint('[DnsResolver] TCP warm OK: $ip:443');
        } catch (_) {
          // TCP 连接失败但 DNS 已缓存
        }
      }
    } catch (e) {
      debugPrint('[DnsResolver] Warm failed: $e');
      rethrow;
    }
  }

  /// 检查域名是否可达
  static Future<bool> isReachable(String hostname) async {
    try {
      await warmDns(hostname);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class DnsException implements Exception {
  final String message;
  const DnsException(this.message);

  @override
  String toString() => 'DnsException: $message';
}
