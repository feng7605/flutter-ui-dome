import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle; // 引入 rootBundle
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart'; // 引入 path_provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

//音源检测
class VadAudioSource implements AudioSource {
  final AudioSource _inputSource;
  final Ref _ref;
  
  sherpa_onnx.VoiceActivityDetector? _vad;
  StreamSubscription<List<int>>? _inputSubscription;
  final _outputController = StreamController<List<int>>.broadcast();

  // **新增**: 用于存储从 assets 复制出来的 VAD 模型文件的路径
  String? _localVadModelPath;

  VadAudioSource({required AudioSource inputSource, required Ref ref})
      : _inputSource = inputSource,
        _ref = ref;

  @override
  Stream<List<int>> get stream => _outputController.stream;

  /// **核心修改**: 初始化方法现在从 assets 加载模型
  Future<void> _initialize() async {
    if (_vad != null) return;
    
    try {
      // 1. 获取本地 VAD 模型文件的路径
      _localVadModelPath = await _getVadModelPathFromAssets();
      
      // 如果路径为 null，说明文件有问题，VAD 将不被启用
      if (_localVadModelPath == null) {
        print("VAD 模型文件未能从 assets 中准备好。VAD 功能将不被启用。");
        return; 
      }

      // 2. 使用本地文件路径初始化 SileroVadModelConfig
      final sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
        model: _localVadModelPath!,
        minSilenceDuration: 0.25,
        minSpeechDuration: 0.2,
        windowSize: 512,
      );

      final vadConfig = sherpa_onnx.VadModelConfig(
        sileroVad: sileroVadConfig,
        numThreads: 1,
        debug: false,
      );

      _vad = sherpa_onnx.VoiceActivityDetector(
        config: vadConfig,
        bufferSizeInSeconds: 30,
      );
      print("VAD Service initialized successfully from assets.");

    } catch (e) {
      print("初始化 VAD 时发生错误: $e");
      // 出错时，_vad 保持为 null，音频将直接透传
    }
  }

  ///文件复制到本地并返回路径
  Future<String?> _getVadModelPathFromAssets() async {
    try {
      // 定义 assets 中的路径和目标本地路径
      const assetPath = 'assets/res/models/vad.onnx';
      final appDocsDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocsDir.path}/vad.onnx';
      
      final localFile = File(localPath);

      // 检查本地文件是否已存在
      if (await localFile.exists()) {
        print("VAD 模型文件已存在于本地: $localPath");
        return localPath;
      }
      
      print("VAD 模型文件不存在，正在从 assets 复制...");
      // 从 assets 读取文件数据
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      
      // 将数据写入本地文件
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

  // start(), stop(), dispose() 和转换函数都保持不变
  // ...
  @override
  Future<void> start() async {
    // 先初始化 VAD 引擎
    await _initialize();
    
    // 再启动输入源
    await _inputSource.start();

    _inputSubscription = _inputSource.stream.listen((audioChunk) {
      // 如果 VAD 未初始化，直接透传原始音频
      if (_vad == null) {
        _outputController.add(audioChunk);
        return;
      }
      
      // VAD 逻辑
      final floatSamples = AudioUtils.bytesToFloat32(Uint8List.fromList(audioChunk));
      _vad!.acceptWaveform(floatSamples);
      
      if (_vad!.isDetected()) {
        while (!_vad!.isEmpty()) {
          final segment = _vad!.front();
          // **修改点 4**: 将 VAD 输出的 Float32List 转换回 List<int>
          _outputController.add(AudioUtils.float32ToBytes(segment.samples));
          _vad!.pop();
        }
      }
    });
  }

  @override
  Future<void> stop() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;

    if (_vad != null) {
      _vad!.flush();
      while (!_vad!.isEmpty()) {
        final segment = _vad!.front();
        _outputController.add(AudioUtils.float32ToBytes(segment.samples));
        _vad!.pop();
      }
    }
    
    await _inputSource.stop();
  }

  @override
  void dispose() {
    _inputSubscription?.cancel();
    _vad?.free();
    _outputController.close();
    _inputSource.dispose(); // 确保输入源也被 dispose
    print("VadAudioSource disposed.");
  }

}