import 'package:flutter/foundation.dart';
import '../../domain/repositories/asr_repository.dart';

enum AsrStatus {
  initial,    // 初始状态
  preparing,  // 准备中 (如下载模型)
  ready,      // 准备就绪，可以开始
  recognizing,// 正在识别
  error,      // 发生错误
}

@immutable
class AsrScreenState {
  final AsrStatus status;
  final String recognizedText;
  final String? message; // 用于显示准备信息或错误信息
  final double? preparationProgress; // 0.0 to 1.0

  const AsrScreenState({
    this.status = AsrStatus.initial,
    this.recognizedText = '',
    this.message,
    this.preparationProgress,
  });

  // 便利的 copyWith 方法
  AsrScreenState copyWith({
    AsrStatus? status,
    String? recognizedText,
    String? message,
    double? preparationProgress,
    bool clearMessage = false,
    bool clearProgress = false,
  }) {
    return AsrScreenState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      message: clearMessage ? null : message ?? this.message,
      preparationProgress: clearProgress ? null : preparationProgress ?? this.preparationProgress,
    );
  }
}