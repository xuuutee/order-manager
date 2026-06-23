import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// 版本更新检查器 — 从 GitHub Releases API 自动获取最新版本
class UpdateChecker {
  static const _owner = 'xuuutee';
  static const _repo = 'order-manager';

  /// 检查更新，有新版则弹窗
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final latest = await _fetchLatestRelease();
      if (latest == null) return;

      final versionCode = _parseVersionCode(latest['tag']);
      if (versionCode <= AppConfig.versionCode) return;

      if (!context.mounted) return;

      await _showUpdateDialog(
        context,
        versionName: latest['name'] ?? latest['tag'],
        changelog: latest['body'] ?? '',
        apkUrl: _findApkUrl(latest['assets']),
      );
    } catch (_) {
      // 静默失败，不影响正常使用
    }
  }

  /// 从 GitHub API 获取最新 Release
  static Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$_owner/$_repo/releases/latest',
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'OrderManager',
    });

    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// 从 tag 名解析版本号，如 v1.0.3 → 3
  static int _parseVersionCode(String? tag) {
    if (tag == null) return 0;
    // 去掉 v 前缀，取最后一段数字
    final cleaned = tag.replaceFirst(RegExp(r'^v'), '');
    final parts = cleaned.split('.');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts.last) ?? 0;
  }

  /// 从 assets 中找 arm64 APK 下载链接
  static String _findApkUrl(List<dynamic>? assets) {
    if (assets == null || assets.isEmpty) return '';
    final list = assets as List;
    for (final a in list) {
      final name = (a['name'] ?? '') as String;
      // 优先 arm64
      if (name.contains('arm64')) {
        return (a['browser_download_url'] ?? '') as String;
      }
    }
    // fallback：第一个 APK
    return (list.first['browser_download_url'] ?? '') as String;
  }

  static Future<void> _showUpdateDialog(
    BuildContext context, {
    required String versionName,
    required String changelog,
    required String apkUrl,
  }) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: true,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('发现新版本'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                versionName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (changelog.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '更新内容：',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(changelog, maxLines: 10, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后更新'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (apkUrl.isNotEmpty) {
                  _launchUrl(apkUrl);
                }
              },
              child: const Text('立即更新'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
