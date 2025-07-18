//定义所有语音识别“提供商”需实现的统一接口。
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseSpeechRecognizer {
  Future<String> executeRecognition(Ref ref) async {
    // 步骤 1: 执行准备工作
    await prepare(ref);
    // 步骤 2: 执行核心识别工作
    return recognize();
  }
  
  Future<void> prepare(Ref ref) async {
    return;
  }

  /// 子类必须实现这个方法来执行真正的识别逻辑。
  Future<String> recognize();
}