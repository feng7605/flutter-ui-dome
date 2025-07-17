//定义统一的仓库接口
//实现聚合逻辑，选择用哪个 provider。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/speech_recognizer_repository.dart';
import '../datasources/base_speech_recognizer.dart';
import '../../domain/entities/speech_result.dart';

class SpeechRecognizerRepositoryImpl implements SpeechRecognizerRepository {
  final BaseSpeechRecognizer _recognizer;
  final Ref _ref;
  // 1. 构造函数
  SpeechRecognizerRepositoryImpl(this._recognizer, this._ref);

  @override
  Future<SpeechResult> recognize() async {
    final text = await _recognizer.executeRecognition(_ref);
    return SpeechResult(text: text);
  }
}