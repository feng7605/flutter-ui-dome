import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'abstract_recognition_service.dart';

// 注意：这个文件不导入任何原生库

class RecognitionService implements AbstractRecognitionService {
  final Ref _ref;
  final _resultController = StreamController<RecognitionResult>.broadcast();

  RecognitionService(this._ref);

  @override
  Stream<RecognitionResult> get resultStream => _resultController.stream;

  @override
  Future<void> ensureInitialized() async {
    print("Web a recognition service initialized (no-op).");
    // Web端不需要初始化模型
  }

  @override
  Future<void> start() async {
    final message = "语音识别在 Web 平台不受支持。";
    print(message);
    _resultController.addError(UnimplementedError(message));
    // 或者可以向流中发送一条提示信息
    // _resultController.add(RecognitionResult(message, RecognitionResultType.finalResult));
  }

  @override
  Future<void> stop() async {
    // 无操作
  }

  @override
  void dispose() {
    _resultController.close();
    print("WebRecognitionService disposed");
  }
}