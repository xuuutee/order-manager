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
import 'services/dns_resolver.dart';
import 'services/supabase_http_client.dart';
import 'widgets/update_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- 自定义 DNS 初始化 ----
  // 创建 DoH DNS 解析器，预热关键域名
  final dnsResolver = DnsResolver();
  final supabaseHost = Uri.parse(AppConfig.supabaseUrl).host;
  // 预热：提前解析 Supabase 域名，填充 DNS 缓存
  await dnsResolver.warmup([supabaseHost]);

  // 创建自定义 HTTP 客户端（对 *.supabase.co 走 DoH 直连）
  final customHttpClient = SupabaseDnsHttpClient(dnsResolver: dnsResolver);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    httpClient: customHttpClient,
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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wasLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      // 登录成功后重新加载订单类型（首次启动时被 RLS 拦截了）
      if (!_wasLoggedIn) {
        _wasLoggedIn = true;
        Future.microtask(() {
          context.read<OrderTypeProvider>().loadTypes();
        });
      }
      return const MainShell();
    }

    _wasLoggedIn = false;
    return const LoginPage();
  }
}

/// 主页面壳子 — 包含底部导航栏
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 登录后检查版本更新
    Future.microtask(() => UpdateChecker.checkAndShow(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          RepaintBoundary(child: DashboardPage()),
          RepaintBoundary(child: OrderListPage()),
          RepaintBoundary(child: FinanceStatsPage()),
        ],
      ),
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
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrderFormPage(),
                  ),
                );
                // 从新建/编辑页返回后，重新加载确保列表最新
                if (mounted) {
                  context.read<OrderProvider>().loadOrders();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('发布订单'),
            )
          : null,
    );
  }
}
