import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class VadAudioSource implements AudioSource {
  final AudioSource inputSource;
  sherpa_onnx.VoiceActivityDetector? _vad;
  final _outputController = StreamController<List<int>>.broadcast();
  List<Float32List> _allDetectedSamples = [];
  StreamSubscription? _inputSubscription;

  VadAudioSource({required this.inputSource});

  init() async{
   sherpa_onnx.initBindings();
   final sileroVad = await _getVadModelPathFromAssets();
   final sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
    model: sileroVad!,
    minSilenceDuration: 0.25,
    minSpeechDuration: 0.5,
  );

  final config = sherpa_onnx.VadModelConfig(
    sileroVad: sileroVadConfig,
    numThreads: 1,
    debug: true,
  );

  _vad = sherpa_onnx.VoiceActivityDetector(config: config, bufferSizeInSeconds: 10);
  }


  @override
  void dispose() {
    _inputSubscription?.cancel();
    _vad?.free(); // **核心修复 5**: 必须释放原生资源
    _vad = null;
    _outputController.close();
    inputSource.dispose();
    debugPrint("VadAudioSource disposed.");
  }

  @override
  Future<void> start() async {
    if (_vad == null){
      await init();
    }
    _vad?.reset();
    _allDetectedSamples.clear();

    await inputSource.start();
    inputSource.stream.listen((audioChunk) {
      final samples = AudioUtils.bytesToFloat32(Uint8List.fromList(audioChunk));
      _vad?.acceptWaveform(samples);
      
      if (_vad!.isDetected()) {
          // 只要 VAD 缓冲区不为空，就持续从中取出数据
          while (!_vad!.isEmpty()) {
            // 安全地获取数据
            final speechSegment = _vad!.front();
            _allDetectedSamples.add(speechSegment.samples);
            // 将 VAD 输出的 Float32List 转换回字节流并添加到输出流
            _outputController.add(AudioUtils.float32ToBytes(speechSegment.samples));
            debugPrint("检测到语音...");
            // 从缓冲区中移除已处理的数据
            _vad!.pop();
          }
        }
    },
    onError: (e) {
      _outputController.addError(e); // 将错误也转发出去
    });
  }

  @override
  Future<void> stop() async {
    // 取消对输入流的监听
    await _inputSubscription?.cancel();
    _inputSubscription = null;

    // 停止底层麦克风
    await inputSource.stop();

    // **核心修复 4**: 安全地 flush 剩余的音频
    if (_vad != null) {
      _vad!.flush();
      while (!_vad!.isEmpty()) {
        final speechSegment = _vad!.front();
        _allDetectedSamples.add(speechSegment.samples);
        _outputController.add(AudioUtils.float32ToBytes(speechSegment.samples));
        _vad!.pop();
      }
    }

    _stopSaveFile();
    
  }

  void _stopSaveFile() async{
    if (_allDetectedSamples.isEmpty) {
      debugPrint('No speech detected, nothing to save.');
      return;
    }
    // 4. 合并所有语音片段
    // .expand() 将 List<List<double>> 展平为 Iterable<double>
    final combinedSamples = Float32List.fromList(
      _allDetectedSamples.expand((e) => e).toList()
    );
    // 5. 生成保存路径
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputWavPath = '${directory.path}/vad_output_$timestamp.wav';

      // 6. 写入文件
      sherpa_onnx.writeWave(
        filename: outputWavPath,
        samples: combinedSamples,
        sampleRate: 16000, // 确保采样率与录音时一致
      );
      debugPrint('Detected speech saved to: $outputWavPath');
      
    } catch (e) {
      debugPrint('Failed to save WAV file: $e');
    }
  }

  @override
  Stream<List<int>> get stream {
    return _outputController.stream;
  }


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