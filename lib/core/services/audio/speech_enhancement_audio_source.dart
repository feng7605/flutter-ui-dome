//人声增强
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class SpeechEnhancementAudioSource implements AudioSource {
  final AudioSource _inputSource;
  final Ref _ref;
  
  sherpa_onnx.OfflineSpeechDenoiser? _speechDenoiser;
  StreamSubscription<List<int>>? _inputSubscription;
  final _outputController = StreamController<List<int>>.broadcast();
  bool _isDisposed = false;

  // 内部缓冲区，用于收集一小段音频进行处理
  final List<int> _audioBuffer = [];
  // 决定处理多长的音频块（以字节为单位），例如 0.5 秒
  // 16000 (采样率) * 2 (字节/采样) * 0.5 (秒) = 16000 字节
  final int _chunkSizeInBytes = 16000;

  SpeechEnhancementAudioSource({required AudioSource inputSource, required Ref ref})
      : _inputSource = inputSource,
        _ref = ref;

  @override
  Stream<List<int>> get stream => _outputController.stream;

  /// 初始化人声增强引擎
  Future<void> _initialize() async {
    if (_isDisposed || _speechDenoiser != null) return;
    
    try {
      // 假设模型也放在 assets 中
      final modelPath = await _getEnhancementModelPathFromAssets();
      if (modelPath == null) {
        print("人声增强模型未能准备好，音频将直接透传。");
        return;
      }

      final config = sherpa_onnx.OfflineSpeechDenoiserConfig(
        model: sherpa_onnx.OfflineSpeechDenoiserModelConfig(
          gtcrn: sherpa_onnx.OfflineSpeechDenoiserGtcrnModelConfig(model: modelPath),
          numThreads: 1,
          debug: false,
          provider: 'cpu',
        ),
      );

      _speechDenoiser = sherpa_onnx.OfflineSpeechDenoiser(config);
      print("Speech Enhancement Service initialized successfully.");

    } catch (e) {
      print("初始化人声增强时发生错误: $e");
    }
  }
  
  /// 从 assets 复制模型到本地
  Future<String?> _getEnhancementModelPathFromAssets() async {
    // 这个逻辑与 VAD 的完全一样，可以进一步抽象成一个通用服务
    try {
      const assetPath = 'assets/res/models/gtcrn.onnx'; 
      final appDocsDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocsDir.path}/gtcrn.onnx';
      final localFile = File(localPath);

      if (await localFile.exists()) return localPath;
      
      final byteData = await rootBundle.load(assetPath);
      await localFile.writeAsBytes(byteData.buffer.asUint8List());
      return localPath;
    } catch (e) {
      print("从 assets 复制人声增强模型时失败: $e");
      return null;
    }
  }

  @override
  Future<void> start() async {
    if (_isDisposed) return;
    
    await _initialize();
    await _inputSource.start();

    _inputSubscription = _inputSource.stream.listen((audioChunk) {
      if (_isDisposed || _outputController.isClosed) return;
      
      // 如果未初始化，直接透传
      if (_speechDenoiser == null) {
        _outputController.add(audioChunk);
        return;
      }

      // 将音频数据加入缓冲区
      _audioBuffer.addAll(audioChunk);

      // 当缓冲区数据足够时，进行处理
      while (_audioBuffer.length >= _chunkSizeInBytes) {
        // 取出一个音频块
        final chunkToProcess = _audioBuffer.sublist(0, _chunkSizeInBytes);
        _audioBuffer.removeRange(0, _chunkSizeInBytes);
        
        // 转换并处理
        final floatSamples = AudioUtils.bytesToFloat32(Uint8List.fromList(chunkToProcess));
        final denoised = _speechDenoiser!.run(samples: floatSamples, sampleRate: 16000);
        
        // 将处理后的数据发送到输出流
        if (!_outputController.isClosed) {
          _outputController.add(AudioUtils.float32ToBytes(denoised.samples));
        }
      }
    });
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;
    
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    
    // **重要**: 处理缓冲区中剩余的音频
    if (_speechDenoiser != null && _audioBuffer.isNotEmpty) {
      final floatSamples = AudioUtils.bytesToFloat32(Uint8List.fromList(_audioBuffer));
      final denoised = _speechDenoiser!.run(samples: floatSamples, sampleRate: 16000);
      if (!_outputController.isClosed) {
        _outputController.add(AudioUtils.float32ToBytes(denoised.samples));
      }
      _audioBuffer.clear();
    }
    
    await _inputSource.stop();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    _inputSubscription?.cancel();
    _speechDenoiser?.free();
    if (!_outputController.isClosed) {
      _outputController.close();
    }
    _inputSource.dispose();
    print("SpeechEnhancementAudioSource disposed.");
  }
}