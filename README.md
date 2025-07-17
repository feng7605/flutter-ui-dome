# Flutter Frame

高性能、模块化的Flutter应用架构框架，采用MVVM模式设计。

## 项目概述

Flutter Frame是一个基于最佳实践构建的应用框架，专注于：

- 高性能与响应式设计
- 模块化与可扩展架构
- 全面的错误处理机制
- 强类型安全实现
- 灵活的主题与本地化支持

## 目录结构

```
lib/
├── core/                    # 核心框架模块
│   ├── config/              # 应用配置
│   ├── di/                  # 依赖注入
│   ├── error/               # 错误处理
│   ├── helpers/             # 通用工具函数
│   ├── localization/        # 本地化实现
│   ├── network/             # 网络通信
│   ├── permissions/         # 权限管理
│   ├── routing/             # 路由管理
│   ├── storage/             # 数据存储
│   ├── theme/               # 主题配置
│   └── utils/               # 工具类
├── data/                    # 数据层
│   ├── datasources/         # 数据源
│   ├── models/              # 数据模型
│   ├── repositories/        # 仓库实现
│   └── services/            # 服务实现
├── domain/                  # 领域层
│   ├── entities/            # 业务实体
│   ├── repositories/        # 仓库接口
│   ├── services/            # 服务接口
│   └── usecases/            # 用例实现
└── presentation/            # 表示层
    ├── common/              # 通用UI组件
    ├── pages/               # 页面
    │   ├── home/            # 首页相关
    │   ├── login/           # 登录相关
    │   ├── settings/        # 设置相关
    │   └── splash/          # 启动页相关
    ├── providers/           # 状态提供者
    ├── viewmodels/          # 视图模型
    └── widgets/             # 自定义组件
```

## 核心架构组件

### 依赖注入

使用Riverpod实现依赖注入，所有服务和提供者集中在`lib/core/di/providers.dart`中管理。

```dart
// 示例提供者
final loggerProvider = Provider<AppLogger>((ref) => AppLogger());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
```

### 错误处理

采用错误优先的方法，统一的异常处理流程：

- `AppException`类层级用于分类和处理异常
- 全局错误处理通过`ErrorHandler`统一管理
- 详细的错误日志记录与分析

### 状态管理

基于Riverpod的状态管理策略：

- 使用`StateNotifier`和`StateNotifierProvider`管理复杂状态
- 支持异步状态管理与依赖追踪
- 更好的测试支持和状态隔离

### 路由管理

使用go_router进行声明式路由管理：

- 支持路由守卫与权限检查
- 深层链接支持
- 参数传递与页面转换

### 存储策略

灵活的数据持久化方案：

- SharedPreferences用于简单键值对
- Hive用于复杂对象存储
- 加密存储支持

### 网络通信

基于Dio的高度可定制网络层：

- 请求拦截与修改
- 响应转换与错误处理
- 连接状态监控

### 主题与本地化

支持动态主题切换与多语言支持：

- 明/暗主题自动切换
- 支持自定义主题配置
- 完整的国际化支持

## 已实现页面

1. 启动页 (Splash Page)
2. 登录页 (Login Page)
3. 注册页 (Registration Page)
4. 主页 (Home Page)
5. 设置页 (Settings Page)

## 开发指南

### 环境配置

支持多环境配置，在`lib/core/config/app_config.dart`中定义：

```dart
// 可用环境
- development
- staging
- production
```

### 新增功能

1. 在适当的层次添加所需的实体/模型/服务
2. 实现对应的仓库与用例
3. 创建视图模型关联业务逻辑
4. 在UI层引用视图模型展示数据

### 测试策略

- 单元测试：逻辑组件与服务
- 集成测试：跨组件交互
- UI测试：用户界面流程

## 性能注意事项

- 尽量减少重建范围
- 适当使用缓存机制
- 避免阻塞主线程
- 图片资源优化与懒加载

## 安全考量

- 敏感数据加密存储
- 安全的API通信
- 错误处理不暴露敏感信息
- 完善的权限管理

## 依赖项

主要依赖包：

- flutter_riverpod: 状态管理
- go_router: 路由管理
- dio: 网络请求
- hive: 本地存储
- shared_preferences: 轻量级存储
- logger: 日志记录
- connectivity_plus: 网络状态监控

## 贡献指南

1. 遵循项目的代码风格与架构
2. 新增代码需包含相应测试
3. 完整的文档记录
4. 提交前进行代码格式化
