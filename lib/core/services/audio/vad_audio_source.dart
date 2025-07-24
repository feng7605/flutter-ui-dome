import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Isolate 之间传递消息的封装类
class _IsolateMessage {
  final SendPort? sendPort;
  final dynamic data; // 可以是 List<int> 或控制命令 (如 'stop')

  _IsolateMessage({this.sendPort, this.data});
}

/// Isolate 初始化时需要的信息
class _VadInitParams {
  final SendPort sendPort;
  final String modelPath;

  _VadInitParams(this.sendPort, this.modelPath);
}

/// 这是将在新 Isolate 中执行的顶层函数
/// 它不能是类的方法
Future<void> _vadIsolateEntrypoint(_VadInitParams params) async {
  final receivePort = ReceivePort();
  params.sendPort.send(_IsolateMessage(sendPort: receivePort.sendPort));

  sherpa_onnx.VoiceActivityDetector? vad;

  try {
    final sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
      model: params.modelPath,
      minSilenceDuration: 0.25,
      minSpeechDuration: 0.2,
      windowSize: 512,
    );
    final vadConfig = sherpa_onnx.VadModelConfig(
      sileroVad: sileroVadConfig,
      numThreads: 1, // Isolate 内部是单线程的
      debug: false,
    );
    vad = sherpa_onnx.VoiceActivityDetector(
      config: vadConfig,
      bufferSizeInSeconds: 5, // 保持较小的缓冲区
    );
  } catch (e) {
    params.sendPort.send(_IsolateMessage(data: Exception("VAD worker failed to initialize: $e")));
    return;
  }
  
  await for (final message in receivePort) {
    if (message is _IsolateMessage) {
      if (message.data is List<int>) {
        // 这是音频数据，执行密集计算
        final floatSamples = AudioUtils.bytesToFloat32(Uint8List.fromList(message.data));
        vad.acceptWaveform(floatSamples);

        if (vad.isDetected()) {
          while (!vad.isEmpty()) {
            final segment = vad.front();
            // 将处理结果发回主 Isolate
            params.sendPort.send(_IsolateMessage(data: AudioUtils.float32ToBytes(segment.samples)));
            vad.pop();
          }
        }
      } else if (message.data == 'stop') {
        // 处理停止命令
        vad.flush();
        while (!vad.isEmpty()) {
          final segment = vad.front();
          params.sendPort.send(_IsolateMessage(data: AudioUtils.float32ToBytes(segment.samples)));
          vad.pop();
        }
      } else if (message.data == 'reset') {
        vad.reset();
      }
    }
  }
}


// --- 这是您项目中使用的主要类 ---

class VadAudioSource implements AudioSource {
  final AudioSource _inputSource;
  
  final _outputController = StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _inputSubscription;
  
  Isolate? _vadIsolate;
  SendPort? _vadSendPort;
  final _isolateReadyCompleter = Completer<void>();

  VadAudioSource({required AudioSource inputSource}) : _inputSource = inputSource;

  @override
  Stream<List<int>> get stream => _outputController.stream;

  /// 新的 init 方法，负责创建 Isolate
  Future<void> init() async {
    if (_vadIsolate != null) return;

    final receivePort = ReceivePort();
    final modelPath = await _getVadModelPathFromAssets();
    if (modelPath == null) {
      throw Exception("VAD 模型文件未能从 assets 中准备好。");
    }

    _vadIsolate = await Isolate.spawn(
      _vadIsolateEntrypoint,
      _VadInitParams(receivePort.sendPort, modelPath),
      onError: receivePort.sendPort,
      onExit: receivePort.sendPort,
    );

    receivePort.listen((message) {
      if (message is _IsolateMessage) {
        if (message.sendPort != null) {
          // Isolate 已经准备好，并把它的 SendPort 发回来了
          _vadSendPort = message.sendPort;
          if (!_isolateReadyCompleter.isCompleted) {
            _isolateReadyCompleter.complete();
            print("VAD Isolate is ready.");
          }
        } else if (message.data is List<int>) {
          // 从 Isolate 接收到处理好的语音数据
          _outputController.add(message.data);
        } else if (message.data is Exception) {
          // Isolate 发生了错误
          if (!_isolateReadyCompleter.isCompleted) {
            _isolateReadyCompleter.completeError(message.data);
          }
          print("Error from VAD Isolate: ${message.data}");
        }
      } else {
        print("VAD Isolate exited unexpectedly.");
        if (!_isolateReadyCompleter.isCompleted) {
            _isolateReadyCompleter.completeError(Exception("VAD Isolate exited unexpectedly."));
        }
      }
    });

    return _isolateReadyCompleter.future;
  }

  @override
  Future<void> start() async {
    // 等待 Isolate 完全准备好
    await _isolateReadyCompleter.future;

    if (_vadSendPort == null) {
      throw StateError("VAD Isolate is not available.");
    }
    
    // 发送重置命令，确保状态干净
    _vadSendPort!.send(_IsolateMessage(data: 'reset'));

    await _inputSource.start();
    _inputSubscription = _inputSource.stream.listen((audioChunk) {
      // 将原始数据发送到 Isolate 进行处理，主线程不进行任何计算
      _vadSendPort?.send(_IsolateMessage(data: audioChunk));
    });
  }

  @override
  Future<void> stop() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;

    // 向 Isolate 发送停止命令，让它 flush 剩余的缓冲区
    _vadSendPort?.send(_IsolateMessage(data: 'stop'));
    
    await _inputSource.stop();
  }

  @override
  void dispose() {
    _inputSubscription?.cancel();
    _vadIsolate?.kill(priority: Isolate.immediate);
    _vadIsolate = null;
    _outputController.close();
    _inputSource.dispose();
    print("VadAudioSource disposed and Isolate killed.");
  }

  // _getVadModelPathFromAssets 保持不变
  Future<String?> _getVadModelPathFromAssets() async {
    try {
      const assetPath = 'assets/res/models/vad.onnx';
      final appDocsDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocsDir.path}/vad.onnx';
      
      final localFile = File(localPath);
      if (await localFile.exists()) {
        print("VAD 模型文件已存在于本地: $localPath");
        return localPath;
      }
      
      print("VAD 模型文件不存在，正在从 assets 复制...");
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      
      await localFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
      );
      
      print("VAD 模型文件成功复制到: $localPath");
      return localPath;
    } catch (e) {
      print("从 assets 复制 VAD 模型文件时失败: $e");
      return null;
    }
  }
}