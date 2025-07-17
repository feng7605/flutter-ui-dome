// 定义模型当前的状态
enum ModelStatus {
  initial,      // 初始状态
  checking,     // 正在检查本地文件
  downloading,  // 正在下载
  ready,        // 模型已就绪，可以进行识别
  error,        // 发生错误
}

// 一个不可变的状态类，用于承载状态信息
class SherpaModelState {
  final ModelStatus status;
  final double? downloadProgress; // 下载进度，0.0 到 1.0
  final String? message;          // 状态消息或错误信息

  const SherpaModelState({
    this.status = ModelStatus.initial,
    this.downloadProgress,
    this.message,
  });

  // 为了方便创建新状态，可以添加一个 copyWith 方法
  SherpaModelState copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? message,
  }) {
    return SherpaModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      message: message ?? this.message,
    );
  }
}
