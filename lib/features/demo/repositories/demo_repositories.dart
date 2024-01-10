

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/services/http/http_service_provider.dart';
import 'package:frame/features/demo/models/demo_configs.dart';

final demoRepositorProvider = Provider<DemoRepositor>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  //定义数据源
  return MokeDemoRepositor(httpService);
});

abstract class DemoRepositor{
  Future<DemoConfigInfos> get({bool forceRefresh = false});
}

class MokeDemoRepositor implements DemoRepositor{
  MokeDemoRepositor(this.httpService);
  final HttpService httpService;

  //实现
  @override
  Future<DemoConfigInfos> get({bool forceRefresh = true}) async {
    final response = await httpService.get("/web3/xcjh/front/user_login/password", forceRefresh: forceRefresh);

    return DemoConfigInfos.fromJson(response);
  }
}