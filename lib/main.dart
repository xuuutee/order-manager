import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/order_type_provider.dart';
import 'providers/order_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/order_list_page.dart';
import 'pages/order_form_page.dart';
import 'pages/finance_stats_page.dart';
import 'widgets/connectivity_banner.dart';
import 'utils/supabase_http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 创建带 DoH DNS 直连的 HTTP 客户端（大陆网络优化）
  final supabaseHost = Uri.parse(AppConfig.supabaseUrl).host;
  final httpClient = SupabaseHttpClient(supabaseHost);

  // 预热：DoH 解析 + TCP 连通测试（不阻塞 UI）
  httpClient.warmup();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    httpClient: httpClient,
  );

  runApp(const OrderManagerApp());
}

class OrderManagerApp extends StatelessWidget {
  const OrderManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => OrderTypeProvider()..loadTypes()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: '订单管理',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

/// 登录状态路由守卫
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return const MainShell();
    }

    return const LoginPage();
  }
}

/// 主页面壳子 — 嵌套连通性检测
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectivityChecker(
      child: _MainTabs(),
    );
  }
}

/// 底部导航栏页面壳
class _MainTabs extends StatefulWidget {
  const _MainTabs();

  @override
  State<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<_MainTabs> {
  int _currentIndex = 0;

  // 占位页面（第六、七步替换为真实页面）
  static const _pages = [
    DashboardPage(),
    OrderListPage(),
    FinanceStatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '工作台',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '财务',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrderFormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('新建订单'),
            )
          : null,
    );
  }
}
