import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// 一条 DNS 缓存记录
class _DnsCacheEntry {
  final List<String> ips;
  final DateTime expiresAt;

  _DnsCacheEntry({required this.ips, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// DoH（DNS over HTTPS）解析器。
///
/// 使用 Cloudflare (1.1.1.1) 和 Google (8.8.8.8) 的 DoH 端点做 A 记录查询，
/// 绕过系统 DNS。
///
/// **关键设计**：DoH 服务器 IP 硬编码，通过 [RawSocket] 直连 IP，
/// 再用 [RawSecureSocket.secure] 以正确的 DoH 域名做 TLS SNI，
/// 确保：1) 不依赖系统 DNS；2) TLS 证书校验通过。
///
/// 内置内存缓存，默认 TTL = [defaultTtl] 秒。
class DnsResolver {
  /// 默认缓存 TTL（秒）
  static const int defaultTtl = 300;

  /// 单次 DoH 请求超时
  static const Duration dohTimeout = Duration(seconds: 5);

  /// DoH 服务器 IP 列表 — 硬编码，不依赖系统 DNS
  static const List<String> _dohServerIps = [
    '1.1.1.1', // Cloudflare 主
    '1.0.0.1', // Cloudflare 备
    '8.8.8.8', // Google 主
    '8.8.4.4', // Google 备
  ];

  /// DoH 服务器域名（用于 TLS SNI 和 Host header）
  static const List<String> _dohHosts = [
    'cloudflare-dns.com',
    'cloudflare-dns.com',
    'dns.google',
    'dns.google',
  ];

  final Map<String, _DnsCacheEntry> _cache = {};

  // ---- 公开 API ----

  /// 解析 [hostname] 的 A 记录，返回 IPv4 地址列表。
  ///
  /// - 优先从缓存读取
  /// - 缓存未命中 → 逐台尝试 DoH 服务器
  /// - 全部失败 → 返回 `null`（调用方应回退到系统 DNS）
  Future<List<String>?> resolve(String hostname) async {
    // 1. 检查缓存
    final cached = _cache[hostname];
    if (cached != null && !cached.isExpired) {
      debugPrint('🧊 DNS cache hit: $hostname → ${cached.ips}');
      return cached.ips;
    }

    // 2. 逐台 DoH 服务器尝试
    for (int i = 0; i < _dohServerIps.length; i++) {
      try {
        final ips = await _dohQuery(
          dohIp: _dohServerIps[i],
          dohHost: _dohHosts[i],
          targetHost: hostname,
        );
        if (ips != null && ips.isNotEmpty) {
          _cache[hostname] = _DnsCacheEntry(
            ips: ips,
            expiresAt: DateTime.now().add(
              const Duration(seconds: defaultTtl),
            ),
          );
          debugPrint('✅ DoH resolved: $hostname → $ips '
              '(via ${_dohHosts[i]} / ${_dohServerIps[i]})');
          return ips;
        }
      } catch (e) {
        debugPrint('⚠️  DoH query failed (${_dohHosts[i]}): $e');
        // 继续尝试下一台
      }
    }

    debugPrint('❌ All DoH servers failed for $hostname');
    return null;
  }

  /// 预热解析：在 app 启动阶段提前解析关键域名，填充缓存。
  Future<void> warmup(Iterable<String> hostnames) async {
    await Future.wait(
      hostnames.map((h) => resolve(h).catchError((_) => null)),
    );
  }

  /// 清除指定域名缓存（传 `null` 清除全部），调试用。
  void clearCache([String? hostname]) {
    if (hostname != null) {
      _cache.remove(hostname);
    } else {
      _cache.clear();
    }
  }

  // ---- 内部实现 ----

  /// 向指定 DoH 服务器发起 A 记录查询。
  ///
  /// 通过 [RawSocket] 直连 [dohIp]，再用 [RawSecureSocket.secure] 设置 TLS SNI，
  /// 发送 HTTP/1.1 GET 请求，解析 JSON 响应提取 A 记录。
  Future<List<String>?> _dohQuery({
    required String dohIp,
    required String dohHost,
    required String targetHost,
  }) async {
    RawSecureSocket? secureSocket;
    try {
      // 1. 直连 DoH 服务器 IP，升级 TLS 并设置 SNI
      final rawSocket = await RawSocket.connect(dohIp, 443,
          timeout: dohTimeout);
      secureSocket = await RawSecureSocket.secure(rawSocket, host: dohHost);

      // 2. 构造并发送 DoH HTTP 请求
      final path = dohHost == 'dns.google'
          ? '/resolve?name=$targetHost&type=A'
          : '/dns-query?name=$targetHost&type=A';

      final request = 'GET $path HTTP/1.1\r\n'
          'Host: $dohHost\r\n'
          'Accept: application/dns-json\r\n'
          'Connection: close\r\n'
          '\r\n';

      secureSocket.write(utf8.encode(request));

      // 3. 读取完整响应
      final response = await _readRawHttpResponse(secureSocket);
      if (response.statusCode != 200) {
        debugPrint('⚠️  DoH returned ${response.statusCode}');
        return null;
      }

      // 4. 解析 JSON
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['Status'] != 0) {
        debugPrint('⚠️  DoH response status: ${json['Status']}');
        return null;
      }

      final answer = json['Answer'] as List<dynamic>?;
      if (answer == null || answer.isEmpty) {
        debugPrint('⚠️  DoH: no A record found for $targetHost');
        return null;
      }

      // 5. 提取 A 记录（type == 1）
      final ips = <String>[];
      for (final record in answer) {
        final r = record as Map<String, dynamic>;
        if (r['type'] == 1) {
          ips.add(r['data'] as String);
        }
      }
      return ips.isNotEmpty ? ips : null;
    } catch (e) {
      debugPrint('⚠️  DoH socket error: $e');
      return null;
    } finally {
      secureSocket?.close();
    }
  }
}

/// 简单的 HTTP 响应
class _RawHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  _RawHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

/// 从 [RawSecureSocket] 读取完整的 HTTP 响应。
///
/// 处理带 Content-Length 的响应；若无 Content-Length 则读到连接关闭。
Future<_RawHttpResponse> _readRawHttpResponse(RawSecureSocket socket) async {
  final allBytes = await _readAllRaw(socket);

  final headerEnd = _indexOfHeaderEnd(allBytes);
  if (headerEnd == -1) {
    throw const FormatException('No HTTP header end found');
  }

  final headerBytes = allBytes.sublist(0, headerEnd);
  final bodyBytes = allBytes.sublist(headerEnd + 4);

  // 解析 header
  final headerStr = utf8.decode(headerBytes);
  final lines = headerStr.split('\r\n');
  final statusParts = lines.first.split(' ');
  final statusCode = int.parse(statusParts[1]);

  final headers = <String, String>{};
  var contentLength = -1;
  for (int i = 1; i < lines.length; i++) {
    final ci = lines[i].indexOf(':');
    if (ci != -1) {
      final key = lines[i].substring(0, ci).trim().toLowerCase();
      final value = lines[i].substring(ci + 1).trim();
      headers[key] = value;
      if (key == 'content-length') {
        contentLength = int.tryParse(value) ?? -1;
      }
    }
  }

  String body;
  if (contentLength > 0) {
    body = utf8.decode(bodyBytes.sublist(0, contentLength));
  } else {
    body = utf8.decode(bodyBytes);
  }

  return _RawHttpResponse(
    statusCode: statusCode,
    headers: headers,
    body: body,
  );
}

/// 从 [RawSecureSocket] 读取所有字节直到连接关闭
Future<Uint8List> _readAllRaw(RawSecureSocket socket) async {
  final chunks = <Uint8List>[];
  var total = 0;

  await for (final event in socket) {
    if (event == RawSocketEvent.read) {
      final available = socket.available();
      if (available > 0) {
        final data = socket.read(available);
        if (data != null) {
          chunks.add(data);
          total += data.length;
        }
      }
    } else if (event == RawSocketEvent.closed) {
      break;
    }
  }

  final result = Uint8List(total);
  var offset = 0;
  for (final chunk in chunks) {
    result.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }
  return result;
}

int _indexOfHeaderEnd(Uint8List data) {
  for (var i = 0; i < data.length - 3; i++) {
    if (data[i] == 13 &&
        data[i + 1] == 10 &&
        data[i + 2] == 13 &&
        data[i + 3] == 10) {
      return i;
    }
  }
  return -1;
}
