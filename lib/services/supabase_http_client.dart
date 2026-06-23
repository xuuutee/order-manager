import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dns_resolver.dart';

/// 自定义 HTTP 客户端 — 对 `*.supabase.co` 域名使用自定义 DNS（DoH）解析，
/// 直连解析出的 IP 并通过 [RawSecureSocket.secure] 设置正确的 TLS SNI，
/// 绕开系统 DNS。
///
/// **工作流程**：
/// 1. 请求到达 → 检查 host 是否匹配 `*.supabase.co`
/// 2. 匹配 → 通过 [DnsResolver]（DoH）解析域名 → 获 IP 列表
/// 3. [RawSocket.connect(ip, 443)] + [RawSecureSocket.secure(socket, host: originalHost)]
/// 4. 发送原始 HTTP/1.1 请求 → 读取响应 → 返回 [http.StreamedResponse]
/// 5. 任何步骤失败 → 回退到 [_fallbackClient]（系统 DNS）
class SupabaseDnsHttpClient extends http.BaseClient {
  final DnsResolver _dnsResolver;
  final http.Client _fallback;

  SupabaseDnsHttpClient({
    required DnsResolver dnsResolver,
    http.Client? fallback,
  })  : _dnsResolver = dnsResolver,
        _fallback = fallback ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final host = request.url.host;

    if (!host.endsWith('.supabase.co')) {
      return _fallback.send(request);
    }

    debugPrint('🌐 Custom DNS route: $host');

    try {
      final ips = await _dnsResolver.resolve(host);
      if (ips == null || ips.isEmpty) {
        debugPrint('⬅️  DoH failed → fallback to system DNS for $host');
        return _fallback.send(request);
      }

      for (final ip in ips) {
        try {
          return await _sendDirect(ip, host, request);
        } on SocketException catch (e) {
          debugPrint('⚠️  Direct connect to $ip failed: ${e.message}');
          continue;
        } on HandshakeException catch (e) {
          debugPrint('⚠️  TLS handshake failed with $ip: ${e.message}');
          continue;
        } on TimeoutException {
          debugPrint('⚠️  Connection to $ip timed out');
          continue;
        }
      }

      debugPrint('⬅️  All direct IPs failed → fallback to system DNS for $host');
      return _fallback.send(request);
    } catch (e) {
      debugPrint('⬅️  Exception in custom DNS flow: $e → fallback');
      return _fallback.send(request);
    }
  }

  @override
  void close() {
    _fallback.close();
    super.close();
  }

  // ---- 内部实现 ----

  /// 直连 [ip]（TLS SNI = [host]），发送完整 HTTP 请求。
  Future<http.StreamedResponse> _sendDirect(
    String ip,
    String host,
    http.BaseRequest request,
  ) async {
    // 1. TCP 连接
    final rawSocket = await RawSocket.connect(ip, 443,
        timeout: const Duration(seconds: 15));
    // 2. TLS 握手（指定 SNI = host）
    final secureSocket = await RawSecureSocket.secure(rawSocket, host: host);

    try {
      // 3. 发送 HTTP 请求
      await _writeRequest(secureSocket, host, request);

      // 4. 读取全部响应字节
      final allBytes = await _readAll(secureSocket);
      if (allBytes.isEmpty) {
        throw const SocketException('Empty response');
      }

      // 5. 解析响应头
      final headerEnd = _findHeaderEnd(allBytes);
      if (headerEnd == -1) {
        throw const FormatException('No HTTP header end in response');
      }

      final headerBytes = allBytes.sublist(0, headerEnd);
      final bodyBytes = allBytes.sublist(headerEnd + 4);

      final headerStr = utf8.decode(headerBytes);
      final lines = headerStr.split('\r\n');
      final statusParts = lines.first.split(' ');
      final statusCode = int.parse(statusParts[1]);
      final reasonPhrase = statusParts.length > 2
          ? statusParts.sublist(2).join(' ')
          : '';

      final headers = <String, String>{};
      var contentLength = -1;
      var isChunked = false;
      for (int i = 1; i < lines.length; i++) {
        final ci = lines[i].indexOf(':');
        if (ci != -1) {
          final key = lines[i].substring(0, ci).trim().toLowerCase();
          final value = lines[i].substring(ci + 1).trim();
          headers[key] = value;
          if (key == 'content-length') {
            contentLength = int.tryParse(value) ?? -1;
          } else if (key == 'transfer-encoding' && value.contains('chunked')) {
            isChunked = true;
          }
        }
      }

      // 6. 提取 body
      final body = _extractBody(bodyBytes,
          contentLength: contentLength, isChunked: isChunked);

      debugPrint('   ← $statusCode ($host via $ip, ${body.length} bytes)');

      secureSocket.close();
      return http.StreamedResponse(
        ByteStream.fromBytes(body),
        statusCode,
        contentLength: body.length,
        reasonPhrase: reasonPhrase,
        request: request,
        headers: headers,
      );
    } catch (e) {
      secureSocket.close();
      rethrow;
    }
  }

  /// 序列化 HTTP 请求并写入 socket
  Future<void> _writeRequest(
    RawSecureSocket socket,
    String host,
    http.BaseRequest request,
  ) async {
    var path = request.url.path;
    if (path.isEmpty) path = '/';
    if (request.url.hasQuery) path = '$path?${request.url.query}';

    final buf = StringBuffer();
    buf.writeln('${request.method} $path HTTP/1.1');
    buf.writeln('Host: $host');

    request.headers.forEach((name, value) {
      final lower = name.toLowerCase();
      if (lower == 'host' || lower == 'connection') return;
      buf.writeln('$name: $value');
    });

    buf.writeln('Connection: close');

    final bodyBytes = await request.finalize().toBytes();
    if (bodyBytes.isNotEmpty) {
      buf.writeln('Content-Length: ${bodyBytes.length}');
      buf.writeln();
      socket.write(utf8.encode(buf.toString()));
      socket.write(bodyBytes);
    } else {
      buf.writeln();
      socket.write(utf8.encode(buf.toString()));
    }

    // RawSecureSocket writes are immediate, no flush needed
  }

  /// 从 body 字节中提取实际内容（处理 Content-Length / chunked / raw）
  Uint8List _extractBody(
    Uint8List raw, {
    required int contentLength,
    required bool isChunked,
  }) {
    if (isChunked) {
      return _decodeChunked(raw);
    }
    if (contentLength > 0 && contentLength <= raw.length) {
      return Uint8List.sublistView(raw, 0, contentLength);
    }
    return raw;
  }

  /// 解码 chunked transfer encoding
  Uint8List _decodeChunked(Uint8List data) {
    final output = BytesBuilder(copy: false);
    var offset = 0;

    while (offset < data.length - 1) {
      final crlf = _findCrlf(data, offset);
      if (crlf == -1) break;
      final sizeHex = utf8.decode(data.sublist(offset, crlf));
      final size = int.tryParse(sizeHex, radix: 16);
      if (size == null || size < 0) break;

      offset = crlf + 2;
      if (size == 0) break; // 终止 chunk

      if (offset + size > data.length) break;
      output.add(Uint8List.sublistView(data, offset, offset + size));
      offset += size + 2; // chunk data + \r\n
    }
    return output.toBytes();
  }

  /// 从 [RawSecureSocket] 读取所有字节
  Future<Uint8List> _readAll(RawSecureSocket socket) async {
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

  // ---- 小工具 ----

  static int _findHeaderEnd(Uint8List data) {
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

  static int _findCrlf(Uint8List data, int start) {
    for (var i = start; i < data.length - 1; i++) {
      if (data[i] == 13 && data[i + 1] == 10) return i;
    }
    return -1;
  }
}

/// 来自 [http] package 的 ByteStream（别名）
typedef ByteStream = http.ByteStream;
