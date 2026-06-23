import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/app_version.dart';
import '../services/supabase_service.dart';

/// 版本更新检查器
class UpdateChecker {
  /// 检查更新，有新版则弹窗
  static Future<void> checkAndShow(BuildContext context) async {
    final currentVersionCode = AppConfig.versionCode;
    final latest = await SupabaseService().getLatestVersion();

    if (latest == null) return;
    if (latest.versionCode <= currentVersionCode) return;

    if (!context.mounted) return;

    await _showUpdateDialog(context, latest);
  }

  static Future<void> _showUpdateDialog(
      BuildContext context, AppVersion latest) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      barrierDismissible: !latest.isRequired,
      builder: (ctx) => PopScope(
        canPop: !latest.isRequired,
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
                'v${latest.versionName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (latest.changelog.isNotEmpty) ...[
                Text(
                  '更新内容：',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(latest.changelog),
                const SizedBox(height: 12),
              ],
              if (latest.isRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '必须更新后才能继续使用',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            if (!latest.isRequired)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('稍后更新'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadApk(latest.apkUrl);
              },
              child: const Text('立即更新'),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开浏览器下载 APK
  static Future<void> _downloadApk(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
