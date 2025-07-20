import 'dart:async';
import 'package:record/record.dart';
import 'audio_source.dart';

class MicrophoneAudioSource implements AudioSource {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Stream<List<int>>? _audioStream;

  @override
  Stream<List<int>> get stream {
    if (_audioStream == null) {
      throw StateError("Audio stream is not available. Call start() first.");
    }
    return _audioStream!;
  }

  @override
  Future<void> start() async {
    if (!await _audioRecorder.hasPermission()) {
      throw Exception("录音权限被拒绝");
    }
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );
    _audioStream = await _audioRecorder.startStream(config);
  }

  @override
  Future<void> stop() async {
    await _audioRecorder.stop();
    _audioStream = null;
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
  }
}