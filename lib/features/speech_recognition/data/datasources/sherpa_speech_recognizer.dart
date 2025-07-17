import 'package:flutter_frame/features/speech_recognition/data/datasources/sherpa_model_state.dart';
import 'package:flutter_frame/features/speech_recognition/presentation/providers/recognition_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base_speech_recognizer.dart';

class SherpaSpeechRecognizer extends BaseSpeechRecognizer {
  // 不再需要依赖 ModelManager 了！
  SherpaSpeechRecognizer();

  @override
  Future<void> prepare(Ref ref) async {
    final modelManager = ref.read(sherpaModelManagerProvider.notifier);
    await modelManager.setupModels();

    // 安全地检查模型状态
    final modelState = ref.read(sherpaModelManagerProvider);
    if (modelState.status != ModelStatus.ready) {
      throw Exception(modelState.message ?? "Sherpa 模型准备失败");
    }
  }
  
  @override
  Future<String> recognize() async {
    
    // 这里的逻辑现在假定模型已经就绪
    // 它只负责最后的识别步骤
    print("模型已就绪，使用 Sherpa 引擎进行识别...");
    await Future.delayed(const Duration(milliseconds: 800));
    return "你好，世界 (来自 Sherpa)";
  }
}