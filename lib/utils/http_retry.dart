import 'dart:async';
import 'package:flutter/foundation.dart';

/// HTTP 请求重试工具
class HttpRetry {
  /// 执行带重试的异步操作
  ///
  /// [operation] 要执行的操作
  /// [maxRetries] 最大重试次数（默认 3）
  /// [onRetry] 每次重试前的回调
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration baseDelay = const Duration(milliseconds: 800),
    Future<void> Function(int attempt, Object error)? onRetry,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('请求超时'),
        );
      } catch (e) {
        if (attempt == maxRetries) rethrow;

        final delay = baseDelay * (1 << attempt); // 指数退避: 0.8s, 1.6s, 3.2s
        debugPrint(
          '[HttpRetry] Attempt ${attempt + 1} failed: $e. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );

        await onRetry?.call(attempt + 1, e);
        await Future.delayed(delay);
      }
    }

    // Unreachable — kept for type safety
    throw Exception('重试耗尽');
  }
}
