import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/services/audio/microphone_audio_source.dart';
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

final audioSourceProvider = Provider.autoDispose<AudioSource>((ref) {
  final useVad = ref.watch(useVadProvider);

  final microphoneSource = MicrophoneAudioSource();

  final AudioSource finalSource = useVad
      ? VadAudioSource(inputSource: microphoneSource, ref: ref)
      : microphoneSource;

  ref.onDispose(() => finalSource.dispose());
  
  return finalSource;
});