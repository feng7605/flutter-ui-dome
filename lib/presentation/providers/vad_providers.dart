import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/presentation/viewmodels/vad_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vadViewModelProvider = StateNotifierProvider<VadViewModel, VadTestState>((ref) {
  // 使用 ref.watch 来获取 AsyncValue
  final asyncVadSource = ref.watch(vadSourceProvider);

  // 只在 vadAudioSource 成功加载后才创建 ViewModel
  // 在加载中或错误状态下，可以传递一个 null 或虚拟对象，但更好的方式是在 UI 层处理
  final source = asyncVadSource.asData?.value;
  
  // 如果 source 还未就绪，ViewModel 将不会执行任何操作
  return VadViewModel(source); 
});