import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // 对外暴露录音数据流
  Stream<List<int>>? _audioStream;
  Stream<List<int>>? get audioStream => _audioStream;

  // 检查权限
  Future<bool> hasPermission() => _audioRecorder.hasPermission();

  // 开始录音并返回数据流
  Future<void> start() async {
    if (await _audioRecorder.hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      _audioStream = await _audioRecorder.startStream(config);
    } else {
      throw Exception("录音权限被拒绝");
    }
  }

  // 停止录音
  Future<void> stop() async {
    await _audioRecorder.stop();
    _audioStream = null;
  }

  // 释放资源
  void dispose() {
    _audioRecorder.dispose();
  }
}

// 为这个服务创建一个 Provider
final audioRecorderServiceProvider = Provider.autoDispose<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(() => service.dispose());
  return service;
});