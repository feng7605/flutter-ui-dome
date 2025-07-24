import 'package:flutter_frame/core/services/audio/microphone_audio_source.dart';
import 'package:flutter_frame/presentation/viewmodels/mic_test_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider 用于创建和销毁 MicrophoneAudioSource 实例
final micTestSourceProvider = Provider.autoDispose((ref) {
  final source = MicrophoneAudioSource();
  // 当 Provider 不再被使用时，自动调用 dispose 方法清理资源
  ref.onDispose(() {
    print("micTestSourceProvider disposed, cleaning up MicrophoneAudioSource.");
    source.dispose();
  });
  return source;
});


// StateNotifierProvider 用于提供 ViewModel 实例
final micTestViewModelProvider = 
    StateNotifierProvider.autoDispose<MicTestViewModel, MicTestState>((ref) {
  // 当 Provider 被销毁时，ViewModel 的 dispose 方法会自动被调用
  return MicTestViewModel();
});