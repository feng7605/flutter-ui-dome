import 'dart:async';

import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VadStatus {
  stopped,      // 停止状态
  listening,    // 正在监听，但未检测到语音
  speaking,     // 检测到语音
  error,
}
// 1. 定义页面的状态
class VadTestState {
  final VadStatus status;
  final String message;
  
  const VadTestState({
    this.status = VadStatus.stopped,
    this.message = '点击 "开始检测"',
  });

  VadTestState copyWith({VadStatus? status, String? message}) {
    return VadTestState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}


class VadViewModel extends StateNotifier<VadTestState> {
  final AudioSource? _vadAudioSource;
  StreamSubscription? _subscription;
  Timer? _speechResetTimer;
  VadViewModel(this._vadAudioSource) : super(const VadTestState()) {
    // 如果在创建时 _vadAudioSource 就为 null (因为 FutureProvider 在加载)
    // 可以在这里设置一个初始的加载中状态
    if (_vadAudioSource == null) {
      state = state.copyWith(message: "正在初始化 VAD 引擎...");
    }
  }

  Future<void> toggleDetection() async {
    if (_vadAudioSource == null) {
      print("VAD source 尚未准备好。");
      state = state.copyWith(status: VadStatus.error, message: "VAD 引擎初始化失败，请重试。");
      return;
    }
    if (state.status == VadStatus.stopped || state.status == VadStatus.error) {
      await _start();
    } else {
      await _stop();
    }
  }

  Future<void> _start() async {
    if (_vadAudioSource == null) return;
    try {
      state = state.copyWith(status: VadStatus.listening, message: "正在聆听...");
      await _vadAudioSource.start();
      
      _subscription = _vadAudioSource.stream.listen((audioChunk) {
        // 只要从 VAD 源收到数据，就说明检测到了语音
        if (mounted) {
          state = state.copyWith(status: VadStatus.speaking, message: "检测到语音！");
          
          // **修改点 3**: 添加计时器，如果在 1 秒内没有新的语音，则重置回 listening
          _speechResetTimer?.cancel();
          _speechResetTimer = Timer(const Duration(seconds: 1), () {
            if (mounted && state.status == VadStatus.speaking) {
              state = state.copyWith(status: VadStatus.listening, message: "正在聆听...");
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        state = state.copyWith(status: VadStatus.error, message: e.toString());
      }
    }
  }

  Future<void> _stop() async {
    if (_vadAudioSource == null) return;
    state = state.copyWith(status: VadStatus.stopped, message: '点击 "开始检测"');
    await _vadAudioSource.stop();
    await _subscription?.cancel();
    _speechResetTimer?.cancel();
  }

  @override
  void dispose() {
    _speechResetTimer?.cancel();
    _subscription?.cancel();
    // AudioSource 的 dispose 由 vadTestSourceProvider 的 onDispose 管理
    super.dispose();
  }
  
}