import 'dart:async';

enum RecognitionResultType { partial, finalResult }

class RecognitionResult {
  final String text;
  final RecognitionResultType type;
  RecognitionResult(this.text, this.type);
}
/// 定义所有语音识别服务必须实现的通用接口
abstract class AbstractRecognitionService {
  /// 结果流
  Stream<RecognitionResult> get resultStream;

  /// 初始化服务，准备识别所需资源（如模型）
  Future<void> ensureInitialized();

  /// 开始识别
  Future<void> start();

  /// 停止识别
  Future<void> stop();

  /// 释放资源
  void dispose();
}