import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/services/audio/microphone_audio_source.dart';
import 'package:flutter_frame/core/services/audio/speech_enhancement_audio_source.dart';
import 'package:flutter_frame/core/services/audio/vad_audio_source.dart';
import 'package:flutter_frame/core/services/download/downloader.dart';
import 'package:flutter_frame/core/services/file/file_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileManagerProvider = Provider<FileManager>((ref) => FileManager());
final downloaderProvider = Provider<Downloader>((ref) => Downloader());

// 做一个开关控制切换
final useVadProvider = StateProvider<bool>((ref) {
  // 默认值为 true，表示默认启用 VAD 功能
  return true;
});

final audioSourceProvider = Provider<AudioSource>((ref) {
  final useVad = ref.watch(useVadProvider);

  AudioSource currentSource = MicrophoneAudioSource();

  //人身增强
  // currentSource = SpeechEnhancementAudioSource(inputSource: currentSource, ref: ref);
  // final AudioSource finalSource = useVad
  //     ? VadAudioSource(inputSource: microphoneSource, ref: ref)
  //     : microphoneSource;

  ref.onDispose(() => currentSource.dispose());
  
  return currentSource;
});

final vadSourceProvider = FutureProvider<VadAudioSource>((ref) async {
  // 依赖底层的麦克风输入源
  final micSource = ref.watch(audioSourceProvider);
  
  final vadSource = VadAudioSource(inputSource: micSource);
  
  // 在这里调用耗时的 init 方法
  await vadSource.init();

  // 当 Future 完成后，返回已经完全初始化好的 vadSource 实例
  ref.onDispose(() {
    vadSource.dispose();
    print("vadAudioSourceProvider disposed and cleaned up VadAudioSource.");
  });

  return vadSource;
});