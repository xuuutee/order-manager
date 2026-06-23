import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/update_checker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ===== 账号信息 =====
          _sectionTitle('账号', theme),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('当前账号'),
            subtitle: Text(auth.userEmail ?? '未登录'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(indent: 72),

          // ===== 版本与更新 =====
          _sectionTitle('版本与更新', theme),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('检查更新'),
            subtitle: const Text('从 GitHub Releases 获取最新版本'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('正在检查更新...'),
                  duration: Duration(seconds: 1),
                ),
              );
              UpdateChecker.checkAndShow(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('当前版本'),
            subtitle: const Text('v${AppConfig.versionName}'),
            trailing: Text(
              'Build ${AppConfig.versionCode}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(102)),
            ),
          ),
          const Divider(indent: 72),

          // ===== 数据 =====
          _sectionTitle('数据', theme),
          ListTile(
            leading: Icon(Icons.storage_outlined,
                color: theme.colorScheme.onSurface.withAlpha(153)),
            title: const Text('数据存储在 Supabase'),
            subtitle: const Text('订单数据实时同步到云端数据库'),
          ),

          const SizedBox(height: 32),

          // ===== 退出登录 =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('退出登录'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后需要重新输入邮箱密码登录'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: Text(
              '退出',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
