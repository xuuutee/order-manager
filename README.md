# 工作室订单管理系统

Flutter 实现的内部订单管理工具，支持订单 CRUD、财务统计、多状态流转。

## 技术栈

- **框架**: Flutter 3.2+
- **状态管理**: Provider
- **后端**: Supabase (PostgreSQL + Auth)
- **图表**: fl_chart
- **路由**: go_router

## 功能

- 共享账号登录
- 订单新建 / 编辑 / 删除
- 状态流转（待处理 → 进行中 → 已完成 → 已结算）
- 仪表盘（今日/本月/累计订单 & 收入）
- 财务统计（月度柱状图）
- 搜索 & 状态筛选
- 亮色/暗色主题

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行 Web 版
flutter run -d chrome

# 打包 Android APK
flutter build apk --release
```

## 目录结构

```
lib/
├── config/          # 主题、常量、API 配置
├── models/          # 数据模型
├── providers/       # 状态管理
├── services/        # 数据访问层
├── pages/           # 页面
├── widgets/         # 可复用组件
└── utils/           # 工具函数
```

## 大陆网络优化

`setup_hosts.bat` — 右键管理员运行，添加 hosts 条目绕过 DNS 污染。

详见代码内注释。

## License

MIT
