
import 'dart:isolate';
import 'package:record/record.dart';

/// 这是将在 Isolate 中运行的音频录制逻辑
void audioRecordingWorker<Q>(SendPort sendPort, Q params) {
  // 参数已经被 _streamRunner 解包，可以直接使用！
  // final configParams = params as Map<String, dynamic>?; // 如果你需要传递复杂参数

  final audioRecorder = AudioRecorder();

  Future<void> start() async {
    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      final stream = await audioRecorder.startStream(config);
      
      stream.listen(
        (data) {
          sendPort.send(data);
        },
        onError: (e) {
          sendPort.send(Exception("Audio stream error: $e"));
        },
        onDone: () {
          audioRecorder.dispose();
          sendPort.send('done'); // 发送完成信号
        }
      );
    } catch (e) {
      sendPort.send(Exception("Failed to start recording in isolate: $e"));
    }
  }

  start();
}