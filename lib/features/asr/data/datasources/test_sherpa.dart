
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_frame/core/constants/app_constants.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:flutter_frame/features/asr/data/datasources/sherpa_preparation_worker.dart';
import 'package:flutter_frame/features/asr/data/utils/utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import 'asr_base.dart';

class SherpaDataSourceImpl1 extends BaseSherpaDataSource {
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  String _lastRecognizedText = '';

  // **修改点 3**: 调用 super 构造函数
  SherpaDataSourceImpl1({required super.config, required super.ref});

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
      modelDir = await fileManager.getResourceDirectory(
          moduleName: AppConstants.moduleAsr, resourceType: AppConstants.resourceTypeModels, resourceId: modelConfig.id);
      
      if (!await fileManager.validateFilesExist(modelDir, modelConfig.files)) {
        yield* downloadAndValidateModel(modelDir, modelConfig, ref);
        await fileManager.cleanOldVersions(moduleName: AppConstants.moduleAsr, resourceType: AppConstants.resourceTypeModels,
            resourceName: modelConfig.name, currentVersionId: modelConfig.id);
      }
      
      yield const PreparationStatus(PreparationStep.checking, "正在加载模型到内存...");
      final params = SherpaInitParams(modelConfig: modelConfig, modelPath: modelDir.path);
      _recognizer = await compute(prepareRecognizerInIsolate, params);
      
      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");
    } catch (e) {
      if (modelDir != null) await fileManager.cleanDirectory(modelDir);
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