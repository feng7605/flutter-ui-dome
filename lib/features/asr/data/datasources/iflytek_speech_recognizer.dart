import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base_speech_recognizer.dart';

class IflytekSpeechRecognizer extends BaseSpeechRecognizer {

  @override
  Future<String> recognize() async {
    // 只实现核心识别逻辑
    await Future.delayed(Duration(seconds: 1));
    return "你好，世界（来自讯飞）";
  }
}