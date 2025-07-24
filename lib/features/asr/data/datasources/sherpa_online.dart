
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_frame/core/constants/app_constants.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:flutter_frame/features/asr/data/datasources/asr_base.dart';
import 'package:flutter_frame/features/asr/data/datasources/sherpa_preparation_worker.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../utils/utils.dart';

// 这是移动端的实现
class SherpaDataSourceImpl extends BaseSherpaDataSource {

  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  String _lastRecognizedText = '';


  SherpaDataSourceImpl({required super.config, required super.ref});

  @override
  Stream<PreparationStatus> prepare(String modelId) async* {
    final modelConfig = findModelConfigById(modelId);
    if (modelConfig == null) {
      yield PreparationStatus(PreparationStep.error, "未找到ID为 '$modelId' 的模型配置");
      return;
    }
    Directory? modelDir;
    final fileManager = ref.read(fileManagerProvider);
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
        yield* downloadAndValidateModel(modelDir, modelConfig, ref);
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

  @override
  Future<void> start() async {
    if (_recognizer == null) throw Exception("Sherpa Recognizer 未初始化。");
    
    _stream = _recognizer!.createStream();
    _lastRecognizedText = '';
    
    audioSource = ref.read(audioSourceProvider);
    await audioSource!.start();

    audioSubscription = audioSource!.stream.listen((data) {
      if (_recognizer == null || _stream == null) return;
      final samples = AudioUtils.bytesToFloat32(Uint8List.fromList(data));
      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }
      
      final currentText = _recognizer!.getResult(_stream!).text;
      debugPrint("[SHERPA_LOG] Recognizer raw result: '$currentText'");
      resultController.add(AsrResult(text: _lastRecognizedText + currentText, isFinal: false));

      if (_recognizer!.isEndpoint(_stream!)) {
        final finalTranscript = _lastRecognizedText + currentText;
        if (finalTranscript.isNotEmpty) {
           _lastRecognizedText = '$finalTranscript\n';
           resultController.add(AsrResult(text: finalTranscript, isFinal: true));
        }
        _recognizer!.reset(_stream!);
      }
    });
  }

  @override
  Future<void> stop() async {
    // 先处理 recognizer 特有的逻辑
    if (_recognizer != null && _stream != null) {
      final remainingText = _recognizer!.getResult(_stream!).text;
      if (remainingText.isNotEmpty) {
        resultController.add(AsrResult(text: _lastRecognizedText + remainingText, isFinal: true));
      }
    }
    _stream?.free();
    _stream = null;
    
    // 然后调用基类的通用停止逻辑
    await super.stop();
  }

  @override
  void dispose() {
    _stream?.free();
    _recognizer?.free();
    super.dispose(); // 调用基类的 dispose 来释放通用资源
  }
}