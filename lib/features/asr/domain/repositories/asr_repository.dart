import 'dart:async';
import 'package:flutter/foundation.dart';

import '../entities/asr_result.dart';

abstract class AsrRepository {
  /// 准备识别器（如下载模型）。返回一个包含准备进度的状态流。
  Stream<PreparationStatus> prepare();

  /// 开始流式语音识别，返回一个结果流
  Stream<AsrResult> startStreamingRecognition();

  /// 停止流式语音识别
  Future<void> stopStreamingRecognition();

  /// 释放与当前识别器相关的资源
  void dispose();
}

/// 定义准备过程的状态
enum PreparationStep { checking, downloading, ready, error }

@immutable
class PreparationStatus {
  final PreparationStep step;
  final String message;
  final double? progress; // 0.0 to 1.0 for downloading

  const PreparationStatus(this.step, this.message, {this.progress});
}