import 'dart:async';
import 'package:flutter_frame/features/speech_recognition/data/models/speech_config.dart';
import 'package:flutter_frame/features/speech_recognition/data/services/config_service.dart';
import 'package:flutter_frame/features/speech_recognition/data/services/recognition_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/recognition_provider.dart';

/// 表示语音识别UI的状态
class SpeechRecognitionState {
  /// 是否正在进行录音和识别
  final bool isRecognizing;
  
  /// 识别的结果，可能包含数据、加载中或错误状态
  final AsyncValue<String> result;

  const SpeechRecognitionState({
    this.isRecognizing = false,
    this.result = const AsyncValue.data(""),
  });

  /// 一个辅助方法，用于创建状态的副本，便于在 StateNotifier 中更新状态
  SpeechRecognitionState copyWith({
    bool? isRecognizing,
    AsyncValue<String>? result,
  }) {
    return SpeechRecognitionState(
      isRecognizing: isRecognizing ?? this.isRecognizing,
      result: result ?? this.result,
    );
  }
}

/// ViewModel: 负责处理语音识别的业务逻辑和UI状态管理
class SpeechRecognitionViewModel extends StateNotifier<SpeechRecognitionState> {
  final Ref _ref;
  
  // 用于监听识别服务的结果流
  StreamSubscription? _resultSubscription;
  
  // 用于持有对服务的监听，以确保 .autoDispose 的服务在交互期间保持存活
  ProviderSubscription? _serviceSubscription;

  SpeechRecognitionViewModel(this._ref) : super(const SpeechRecognitionState());

  /// UI调用的统一入口方法，根据当前状态决定是开始还是停止
  Future<void> recognize() async {
    // 如果当前正在识别，则调用停止逻辑
    if (state.isRecognizing) {
      await _stopRecognition();
      return;
    }

    // 根据用户在UI上选择的供应商，执行不同的逻辑
    final selectedVendor = _ref.read(selectedVendorProvider);
    if (selectedVendor == SpeechVendor.sherpa) {
      await _startSherpaRecognition();
    } else {
      await _handleOneShotRecognition(); // 处理如讯飞等一次性识别的逻辑
    }
  }

  /// 开始 Sherpa 的流式识别流程
  Future<void> _startSherpaRecognition() async {
    // final configFuture = _ref.read(speechConfigProvider.future);
    // final config = await configFuture;
    print("todo://需优化");
    // 1. 更新UI状态为“加载中”，这将触发模型下载等前置任务
    state = state.copyWith(result: const AsyncValue.loading());

    // 2. **核心修复**: 使用 listen 来订阅服务，这会创建服务实例并保持其存活
    //    即使回调是空的，这个监听本身也是至关重要的
    _serviceSubscription = _ref.listen(recognitionServiceProvider, (previous, next) {});
    final sherpaService = _ref.read(recognitionServiceProvider);

    try {
      // 3. 调用服务进行初始化（包含模型下载检查）
      await sherpaService.ensureInitialized();
      if (!mounted) return; // 检查ViewModel是否还存活

      // 4. 初始化成功后，更新UI状态为“正在识别”
      state = state.copyWith(
        isRecognizing: true, 
        result: const AsyncValue.data("请开始说话...")
      );
      
      // 5. 监听识别服务的结果流，并用其更新UI状态
      _resultSubscription = sherpaService.resultStream.listen(
        (recognitionResult) {
          if (!mounted) return;
          state = state.copyWith(result: AsyncValue.data(recognitionResult.text));
        },
        onError: (e, st) {
          if (!mounted) return;
          state = state.copyWith(isRecognizing: false, result: AsyncValue.error(e, st));
        },
      );
      
      // 6. 正式启动录音和识别
      await sherpaService.start();

    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(isRecognizing: false, result: AsyncValue.error(e, st));
      // 如果在启动过程中出错，也要确保清理订阅
      _cleanUpSubscriptions();
    }
  }

  /// 停止识别流程
  Future<void> _stopRecognition() async {
    final selectedVendor = _ref.read(selectedVendorProvider);
    if (selectedVendor == SpeechVendor.sherpa) {
       // 使用 ref.read 是安全的，因为 _serviceSubscription 保证了服务实例还存活
       await _ref.read(recognitionServiceProvider).stop();
    }
    
    // 清理所有订阅，这会让服务可以被安全地销毁
    _cleanUpSubscriptions();

    // 更新UI状态为“未在识别”
    state = state.copyWith(isRecognizing: false);
  }

  /// 示例：处理非流式供应商的一次性识别请求
  Future<void> _handleOneShotRecognition() async {
    state = state.copyWith(result: const AsyncValue.loading());
    try {
      // 模拟网络请求或SDK调用
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      state = state.copyWith(result: const AsyncValue.data("你好，世界（来自讯飞）"));
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(result: AsyncValue.error(e, st));
    }
  }

  /// 抽离出一个私有方法来统一清理所有订阅
  void _cleanUpSubscriptions() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    
    // 关闭对服务的监听，允许 Riverpod 在需要时自动销毁它
    _serviceSubscription?.close();
    _serviceSubscription = null;
  }

  /// 重写 StateNotifier 的 dispose 方法，确保 ViewModel 被销毁时，所有资源都被释放
  @override
  void dispose() {
    _cleanUpSubscriptions();
    super.dispose();
  }
}