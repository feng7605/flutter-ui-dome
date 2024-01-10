
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/features/demo/models/demo_configs.dart';

import '../repositories/demo_repositories.dart';

final demoProvider = FutureProvider<DemoConfigInfos>((ref) async {
  final repositor = ref.watch(demoRepositorProvider);
  return repositor.get();
});