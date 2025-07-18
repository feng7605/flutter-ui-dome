import 'package:flutter/foundation.dart';
import '../../domain/repositories/asr_repository.dart';

enum AsrStatus {
  initial,            // 初始，未知状态
  checking,           // 正在检查本地文件状态
  requiresDownload,   // 需要用户手动下载
  downloading,        // 正在下载中
  ready,              // 准备就绪，可以识别
  recognizing,        // 正在识别
  error,              // 发生错误
}

@immutable
class AsrScreenState {
  final AsrStatus status;
  final String recognizedText;
  final String? message; 
  final double? downloadProgress; // 只用于下载进度
  final String? selectedModeType; // e.g., "streaming"
  final String? selectedModelId;  // e.g., "zipformer-test-v1"

  const AsrScreenState({
    this.status = AsrStatus.initial,
    this.recognizedText = '',
    this.message,
    this.downloadProgress,
    this.selectedModeType = '',
    this.selectedModelId='',
  });

  // 便利的 copyWith 方法
  AsrScreenState copyWith({
    AsrStatus? status,
    String? recognizedText,
    String? message,
    double? downloadProgress,
    bool clearMessage = false,
    bool clearProgress = false,
    String? selectedModeType,
    String? selectedModelId,
  }) {
    return AsrScreenState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      message: clearMessage ? null : message ?? this.message,
      downloadProgress: clearProgress ? null : downloadProgress ?? this.downloadProgress,
      selectedModeType: selectedModeType ?? this.selectedModeType,
      selectedModelId: selectedModelId ?? this.selectedModelId,
    );
  }
}