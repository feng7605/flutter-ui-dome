//动态路由
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// 引入你所有的“插件”页面
import 'package:flutter_frame/presentation/pages/help/help_page.dart';
// import 'package:flutter_frame/presentation/pages/another_plugin_page.dart';

// 1. 创建一个从 Widget 名称到 Widget Builder 的映射
// 这是我们新的、简化的“插件注册表”
final Map<String, Widget Function(Map<String, dynamic>? params)> _pluginPages = {
  'HelpPage': (params) => const HelpPage(),
  // 'AnotherPluginPage': (params) => AnotherPluginPage(someValue: params?['value']),
};

// 2. 修改加载函数，使其直接返回一个 Future<List<GoRoute>>
Future<List<GoRoute>> loadDynamicRoutes() async {
  final String jsonStr = await rootBundle.loadString('assets/res/dynamic_routes.json');
  final List<dynamic> jsonList = json.decode(jsonStr);

  final List<GoRoute> dynamicRoutes = [];

  for (var routeConfig in jsonList) {
    final String path = routeConfig['path'];
    final String widgetName = routeConfig['widget'];
    final Map<String, dynamic> defaultParams = Map<String, dynamic>.from(routeConfig['params'] ?? {});

    // 从注册表中查找对应的 Widget Builder
    final widgetBuilder = _pluginPages[widgetName];

    if (widgetBuilder != null) {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          // 你甚至可以给动态路由命名
          name: path.substring(1), 
          builder: (context, state) {
            // 合并默认参数和运行时传递的参数 (来自 state.extra)
            final extraParams = state.extra as Map<String, dynamic>? ?? {};
            final allParams = {...defaultParams, ...extraParams};
            return widgetBuilder(allParams);
          },
        ),
      );
    } else {
      // 在开发期间打印警告，方便调试
      debugPrint('Warning: Widget "$widgetName" for path "$path" not found in _pluginPages registry.');
    }
  }

  return dynamicRoutes;
}