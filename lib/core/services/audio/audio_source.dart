import 'dart:async';

/// 定义所有音频源必须实现的统一接口
abstract class AudioSource {
  /// 经过处理后，最终提供给识别引擎的音频数据流
  Stream<List<int>> get stream;
  
  /// 开始音频捕获和处理
  Future<void> start();
  
  /// 停止音频捕获和处理
  Future<void> stop();

  /// 释放资源
  void dispose();
}