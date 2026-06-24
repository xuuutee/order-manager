import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/dns_resolver.dart';

/// 网络连通性检测器
/// App 启动时预检 Supabase 连通性，弱网/不可用时展示提示
class ConnectivityChecker extends StatefulWidget {
  final Widget child;

  const ConnectivityChecker({super.key, required this.child});

  @override
  State<ConnectivityChecker> createState() => _ConnectivityCheckerState();
}

class _ConnectivityCheckerState extends State<ConnectivityChecker> {
  ConnectivityStatus _status = ConnectivityStatus.checking;
  Timer? _retryTimer;

  // Supabase 项目域名（从 AppConfig 拆出，避免循环引用）
  static const _hostname = 'uqaggeaiqcmsxkikyfvl.supabase.co';

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _status = ConnectivityStatus.checking);

    try {
      final reachable = await DnsResolver.isReachable(_hostname)
          .timeout(const Duration(seconds: 8));
      setState(() =>
          reachable ? ConnectivityStatus.online : ConnectivityStatus.slow);
    } catch (_) {
      setState(() => _status = ConnectivityStatus.offline);
      // 每 30 秒自动重试
      _retryTimer = Timer(const Duration(seconds: 30), _check);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 连通性状态横幅
        if (_status != ConnectivityStatus.online) _buildBanner(theme),
        // 主体内容
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner(ThemeData theme) {
    final (icon, text, bgColor) = switch (_status) {
      ConnectivityStatus.checking => (
          Icons.wifi_find,
          '正在检测网络连通性...',
          theme.colorScheme.tertiaryContainer,
        ),
      ConnectivityStatus.slow => (
          Icons.wifi_2_bar,
          '网络延迟较高，数据加载可能较慢',
          theme.colorScheme.tertiaryContainer,
        ),
      ConnectivityStatus.offline => (
          Icons.wifi_off,
          '无法连接服务器，请检查网络后下拉刷新',
          theme.colorScheme.errorContainer,
        ),
      _ => (Icons.wifi, '', Colors.transparent),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 8),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (_status == ConnectivityStatus.offline)
            TextButton(
              onPressed: _check,
              child: const Text('重试', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

enum ConnectivityStatus { checking, online, slow, offline }
