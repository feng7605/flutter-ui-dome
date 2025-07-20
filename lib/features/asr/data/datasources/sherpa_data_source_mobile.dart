
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_frame/core/constants/app_constants.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/services/download/downloader.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:flutter_frame/features/asr/data/datasources/sherpa_preparation_worker.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../utils/utils.dart';
import 'asr_data_source.dart';

// 这是移动端的实现
class SherpaDataSourceImpl implements AsrDataSource {
  final Ref _ref;
  final SupplierConfig config;

  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  String _lastRecognizedText = '';

  final _resultController = StreamController<AsrResult>.broadcast();

  SherpaDataSourceImpl({required this.config, required Ref ref}): _ref = ref;

  @override
  Future<bool> isReady(String modelId) async {
    // 如果识别器已经加载到内存，那肯定是 ready
    if (_recognizer != null) {
      // TODO: 需要一个更好的方法来判断当前加载的 recognizer 是否是用户选择的那个
      // 简单起见，我们假设只要有 recognizer 就绪就可以，但实际应该更严谨
      return true;
    }

    final modelConfig = _findModelConfigById(modelId);
    if (modelConfig == null) return false;

    // 只做文件系统的检查，这是快速的
    final fileManager = _ref.read(fileManagerProvider);
    final modelDir = await fileManager.getResourceDirectory(
      moduleName: 'asr',
      resourceType: 'models',
      resourceId: modelConfig.id);
    return await fileManager.validateFilesExist(modelDir, modelConfig.files);
  }

  @override
  Stream<AsrResult> get resultStream => _resultController.stream;

  @override
  Stream<PreparationStatus> prepare(String modelId) async* {
    final modelConfig = _findModelConfigById(modelId);
    if (modelConfig == null) {
      yield PreparationStatus(PreparationStep.error, "未找到ID为 '$modelId' 的模型配置");
      return;
    }
    Directory? modelDir;
    final fileManager = _ref.read(fileManagerProvider);
    try {
      sherpa_onnx.initBindings();
      
      yield const PreparationStatus(PreparationStep.checking, "正在检查本地模型...");
      
      modelDir = await fileManager.getResourceDirectory(
      moduleName: AppConstants.moduleAsr,
      resourceType: AppConstants.resourceTypeModels,
      resourceId: modelConfig.id);
      
      final bool isModelValid = await fileManager.validateFilesExist(modelDir, modelConfig.files);

      if (!isModelValid) {
        // 如果模型无效，则下载并解压
        yield* _downloadAndValidateModel(modelDir, modelConfig);
        await fileManager.cleanOldVersions(
          moduleName: AppConstants.moduleAsr,
          resourceType: AppConstants.resourceTypeModels,
          resourceName: modelConfig.name, // 假设 name 是'zipformer'
          currentVersionId: modelConfig.id, // 假设 id 是 'zipformer-v2'
        );
      }
     // 步骤 2: **将耗时操作交给后台 Isolate**
      yield const PreparationStatus(PreparationStep.checking, "正在加载模型到内存...");

      // 准备传递给 Isolate 的参数
      final params = SherpaInitParams(
        modelConfig: modelConfig,
        modelPath: modelDir.path,
      );

      // 使用 compute 在后台执行模型加载和识别器创建
      // `compute` 函数返回一个 Future，它代表了 Isolate 的计算结果。
      _recognizer = await compute(prepareRecognizerInIsolate, params);
      
      // 步骤 3: Isolate 返回结果后，在主线程更新状态
      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");
      
    } catch (e) {
      if (modelDir != null) {
        await fileManager.cleanDirectory(modelDir);
      }
      yield PreparationStatus(PreparationStep.error, "模型准备失败: $e");
    }
  }

  // 保持 prepare 方法的逻辑清晰
  Stream<PreparationStatus> _downloadAndValidateModel(Directory modelDir, ModelConfig modelConfig) async* {
    final fileManager = _ref.read(fileManagerProvider);
    final downloader = _ref.read(downloaderProvider);

    final zipFile = File('${modelDir.path}/${modelConfig.downloadUrl.split('/').last}');
    
    // 监听下载流
    yield const PreparationStatus(PreparationStep.downloading, "开始下载...", progress: 0.0);
    await for (final progress in downloader.download(modelConfig.downloadUrl, zipFile.path)) {
      yield PreparationStatus(PreparationStep.downloading, "下载中...", progress: progress.received / progress.total);
    }
    
    // 校验
    yield const PreparationStatus(PreparationStep.checking, "校验文件...");
    if (!await fileManager.verifyChecksum(zipFile, modelConfig.checksum)) {
      throw Exception("文件校验失败");
    }
    
    // 解压
    yield const PreparationStatus(PreparationStep.checking, "解压中...");
    await Downloader.unzip(zipFile, modelDir);
    await zipFile.delete();

    // 再次验证解压后的文件
    if (!await fileManager.validateFilesExist(modelDir, modelConfig.files)) {
      throw Exception("解压后的文件不完整");
    }
  }

  @override
  Future<void> start() async {
    if (_recognizer == null) throw Exception("Sherpa Recognizer 未初始化。请先调用 prepare。");
    
    _stream = _recognizer!.createStream();
    _lastRecognizedText = '';
    
    final audioSource = _ref.read(audioSourceProvider);
    try{
      await audioSource.start();
    }catch(e){
      throw Exception("启动音频源失败: $e");
    }

    _audioSubscription = audioSource.stream.listen((data) {
      if (_recognizer == null || _stream == null) return;
      
      final samples = AudioUtils.bytesToFloat32(Uint8List.fromList(data));
      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }
      
      final currentText = _recognizer!.getResult(_stream!).text;
      _resultController.add(AsrResult(text: _lastRecognizedText + currentText, isFinal: false));

      if (_recognizer!.isEndpoint(_stream!)) {
        final finalTranscript = _lastRecognizedText + currentText;
        if (finalTranscript.isNotEmpty) {
           _lastRecognizedText = '$finalTranscript\n';
           _resultController.add(AsrResult(text: finalTranscript, isFinal: true));
        }
        _recognizer!.reset(_stream!);
      }
    });
  }

  @override
  Future<void> stop() async {
    // ... stop 方法保持不变 ...
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    if (_recognizer != null && _stream != null) {
      final remainingText = _recognizer!.getResult(_stream!).text;
      if (remainingText.isNotEmpty) {
        _resultController.add(AsrResult(text: _lastRecognizedText + remainingText, isFinal: true));
      }
    }
    final audioSource = _ref.read(audioSourceProvider);
    await audioSource.stop();
    _stream?.free();
    _stream = null;
  }


  @override
  void dispose() {
    // ... dispose 方法保持不变 ...
    final audioSource = _ref.read(audioSourceProvider);
    _audioSubscription?.cancel();
    audioSource.dispose();
    _stream?.free();
    _recognizer?.free();
    _resultController.close();
  }
  
  @override
  Future<AsrResult> recognizeOnce() async {
    if (_recognizer == null) throw Exception("识别器未准备好");
    return AsrResult(text: "test");
  }

  ModelConfig? _findModelConfigById(String? modelId) {
    if (modelId == null) return null;
    for (final mode in config.modes) {
      for (final model in mode.models) {
        if (model.id == modelId) {
          return model;
        }
      }
    }
    return null;
  }
}