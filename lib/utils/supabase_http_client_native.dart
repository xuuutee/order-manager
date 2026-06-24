import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dns_resolver.dart';

/// IP 直连 HTTP 客户端 — Android/iOS/Desktop
///
/// 用 SecureSocket + 自定义 SNI 绕过系统 DNS，
/// 解决大陆手机 DNS 污染问题。
class SupabaseHttpClientNative extends http.BaseClient {
  final String _supabaseHost;
  final http.Client _fallback;
  final List<InternetAddress> _ips = [];
  final _random = Random();

  SupabaseHttpClientNative(this._supabaseHost) : _fallback = http.Client();

  Future<void> warmup() async {
    try {
      final ips = await DnsResolver.resolve(_supabaseHost);
      _ips.clear();
      _ips.addAll(ips);
      debugPrint('[HttpClient] DoH resolved: ${ips.map((e) => e.address)}');
    } catch (e) {
      debugPrint('[HttpClient] DoH warmup failed: $e');
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final host = request.url.host;

    if (host == _supabaseHost && _ips.isNotEmpty) {
      try {
        return await _sendViaIp(request).timeout(
          const Duration(seconds: 15),
        );
      } catch (e) {
        debugPrint('[HttpClient] IP direct failed: $e');
      }
    }

    try {
      return await _fallback.send(request).timeout(
        const Duration(seconds: 15),
      );
    } on SocketException catch (e) {
      throw http.ClientException(
        '网络连接失败 ($_supabaseHost): ${e.message}\n'
        '手机端：设置 → 网络 → 私有DNS → 填入 dns.alidns.com',
      );
    }
  }

  Future<http.StreamedResponse> _sendViaIp(http.BaseRequest request) async {
    final ip = _ips[_random.nextInt(_ips.length)];

    // TCP 连接到 IP
    final rawSocket = await Socket.connect(
      ip.address,
      443,
      timeout: const Duration(seconds: 10),
    );

    // TLS 升级，SNI = 原始域名
    final socket = await SecureSocket.secure(
      rawSocket,
      host: _supabaseHost,
      onBadCertificate: (_) => true,
    );

    // HTTP/1.1 请求
    final path = request.url.hasQuery
        ? '${request.url.path}?${request.url.query}'
        : request.url.path;
    final buffer = StringBuffer();
    buffer.writeln('${request.method} $path HTTP/1.1');
    buffer.writeln('Host: $_supabaseHost');
    buffer.writeln('Connection: close');

    request.headers.forEach((name, values) {
      for (final v in values.split(',')) {
        buffer.writeln('$name: ${v.trim()}');
      }
    });

    List<int> bodyBytes = [];
    if (request is http.Request && request.body.isNotEmpty) {
      bodyBytes = utf8.encode(request.body);
      buffer.writeln('Content-Length: ${bodyBytes.length}');
    }

    buffer.writeln();
    socket.write(buffer.toString());
    if (bodyBytes.isNotEmpty) {
      socket.add(bodyBytes);
    }
    await socket.flush();

    final response = await _readResponse(socket);
    socket.destroy();
    return response;
  }

  Future<http.StreamedResponse> _readResponse(Socket socket) async {
    final completer = Completer<http.StreamedResponse>();
    final buffer = <int>[];
    int headerEnd = -1;

    socket.listen(
      (data) {
        buffer.addAll(data);
        if (headerEnd < 0) {
          for (int i = 0; i < buffer.length - 3; i++) {
            if (buffer[i] == 13 && buffer[i + 1] == 10 &&
                buffer[i + 2] == 13 && buffer[i + 3] == 10) {
              headerEnd = i;
              break;
            }
          }

          if (headerEnd >= 0) {
            final headerBytes = buffer.sublist(0, headerEnd);
            final headerStr = utf8.decode(headerBytes);
            final lines = headerStr.split('\r\n');

            String? statusLine;
            final headers = <String, String>{};
            int? contentLength;

            for (int i = 0; i < lines.length; i++) {
              if (i == 0) {
                statusLine = lines[i];
              } else {
                final colonIdx = lines[i].indexOf(':');
                if (colonIdx > 0) {
                  final key = lines[i].substring(0, colonIdx).trim().toLowerCase();
                  final value = lines[i].substring(colonIdx + 1).trim();
                  headers[key] = value;
                  if (key == 'content-length') {
                    contentLength = int.tryParse(value);
                  }
                }
              }
            }

            final parts = statusLine?.split(' ') ?? [];
            final statusCode = parts.length > 1
                ? int.tryParse(parts[1]) ?? 502
                : 502;
            final reasonPhrase = parts.length > 2
                ? parts.sublist(2).join(' ')
                : '';

            final bodyStart = headerEnd + 4;
            final body = buffer.sublist(bodyStart);

            final stream = Stream.fromIterable([body]);
            final response = http.StreamedResponse(
              stream,
              statusCode,
              contentLength: contentLength,
              reasonPhrase: reasonPhrase,
              request: null,
              headers: headers,
              isRedirect: statusCode >= 300 && statusCode < 400,
              persistentConnection: false,
            );

            if (!completer.isCompleted) {
              completer.complete(response);
            }
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('连接已关闭，未收到响应'),
          );
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  void close() {
    _fallback.close();
  }
}
