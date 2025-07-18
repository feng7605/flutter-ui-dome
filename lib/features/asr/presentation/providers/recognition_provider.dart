import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/iflytek_speech_recognizer.dart'; // 引入讯飞实现
import '../../data/datasources/sherpa_speech_recognizer.dart';  // 引入 Sherpa 实现
import '../../data/datasources/base_speech_recognizer.dart';
import '../../data/datasources/sherpa_model_manager.dart';
import '../../data/datasources/sherpa_model_state.dart';
import '../viewmodels/recognition_viewmodel.dart';

// 1. 定义供应商枚举，用于UI选择和逻辑切换
enum SpeechVendor {
  sherpa('sherpa离线'),
  iflytek('科大讯飞');
  
  // 未来可以继续添加 'Baidu', 'Tencent' 等

  const SpeechVendor(this.displayName);
  final String displayName;
}

// 2. Provider: 管理用户当前选择的供应商
final selectedVendorProvider = StateProvider<SpeechVendor>((ref) => SpeechVendor.sherpa);

// 3. Provider: 专门用于 Sherpa 模型管理的 Provider
//    使用 .autoDispose 可以在 Sherpa 不被选择时自动销毁，释放资源
final sherpaModelManagerProvider = StateNotifierProvider.autoDispose<SherpaModelManager, SherpaModelState>(
  (ref) => SherpaModelManager()
);

// 4. Provider: 根据选择动态提供对应的原始 Recognizer 实例 (DataSource)
//    这部分在最终方案中不是必须的，但保留它可以让非流式逻辑更清晰
final speechRecognizerProvider = Provider.autoDispose<BaseSpeechRecognizer>((ref) {
  final selectedVendor = ref.watch(selectedVendorProvider);
  switch (selectedVendor) {
    case SpeechVendor.iflytek:
      return IflytekSpeechRecognizer();
    case SpeechVendor.sherpa:
      return SherpaSpeechRecognizer();
  }
});


// 5. Provider: 这是您指出的缺失的核心 Provider
//    它负责创建 ViewModel 的实例，并为其注入 Ref，以便 ViewModel 可以访问其他 Provider
final speechRecognitionViewModelProvider = 
  StateNotifierProvider.autoDispose<SpeechRecognitionViewModel, SpeechRecognitionState>((ref) {
    // ViewModel 的创建很简单，它只需要一个 ref 就可以指挥其他所有服务
    return SpeechRecognitionViewModel(ref);
});


// 注意：在最终的流式方案中，我们不再需要 Repository 和 UseCase 层来处理识别逻辑，
// 因为这部分逻辑已经更适合放在 ViewModel 和 Service 层来协调。
// 如果你的“讯飞”或其他非流式提供商仍然想使用 Repository/UseCase 模式，
// 你可以保留下面的 Provider，并在 ViewModel 的 _handleOneShotRecognition 方法中调用它们。

/*
// (可选) 为非流式逻辑保留的 Repository Provider
final speechRecognizerRepositoryProvider = Provider.autoDispose<SpeechRecognizerRepository>((ref) {
  final recognizer = ref.watch(speechRecognizerProvider);
  return SpeechRecognizerRepositoryImpl(recognizer);
});

// (可选) 为非流式逻辑保留的 UseCase Provider
final recognizeSpeechUseCaseProvider = Provider.autoDispose<RecognizeSpeechUseCase>((ref) {
  final repository = ref.watch(speechRecognizerRepositoryProvider);
  return RecognizeSpeechUseCase(repository);
});
*/