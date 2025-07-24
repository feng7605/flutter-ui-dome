import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 状态定义保持不变
enum MicStatus { stopped, listening, error }

class MicTestState {
  final MicStatus status;
  final String message;

  const MicTestState({
    this.status = MicStatus.stopped,
    this.message = '点击 "开始监听"',
  });

  MicTestState copyWith({MicStatus? status, String? message}) {
    return MicTestState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

// ViewModel 现在直接管理 RecorderController
class MicTestViewModel extends StateNotifier<MicTestState> {
  // **核心修改**: 使用 RecorderController
  final RecorderController recorderController = RecorderController()
    ..androidEncoder = AndroidEncoder.aac // 设置编码器
    ..sampleRate = 16000 // 设置采样率
    ..bitRate = 16000 * 16 // 设置比特率
    ..updateFrequency = const Duration(milliseconds: 100); // 波形更新频率

  StreamSubscription<RecorderState>? _recorderStateSubscription;

  MicTestViewModel() : super(const MicTestState()) {
    // 监听控制器状态的变化来更新UI
    _recorderStateSubscription = recorderController.onRecorderStateChanged.listen((state) {
      if (mounted) {
        this.state = this.state.copyWith(
          status: state.isRecording ? MicStatus.listening : MicStatus.stopped,
          message: state.isRecording ? "正在聆听..." : '点击 "开始监听"',
        );
      }
    });
  }

  Future<void> toggleRecording() async {
    try {
      if (state.status == MicStatus.stopped) {
        // **核心修改**: 直接调用 record()
        // 无需指定路径，因为我们只需要实时波形
        await recorderController.record();
      } else {
        // **核心修改**: 调用 stop()
        await recorderController.stop();
      }
    } catch (e) {
      state = state.copyWith(status: MicStatus.error, message: "发生错误: $e");
    }
  }

  @override
  void dispose() {
    print("MicTestViewModel disposing...");
    _recorderStateSubscription?.cancel();
    // **核心修改**: 必须 dispose 控制器
    recorderController.dispose();
    super.dispose();
  }
}