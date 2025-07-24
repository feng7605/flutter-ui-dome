// features/asr/data/datasources/offline_vad_data_source.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:flutter_frame/features/asr/data/datasources/asr_base.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/data/utils/utils.dart';
import 'package:flutter_frame/features/asr/domain/entities/asr_result.dart';
import 'package:flutter_frame/features/asr/domain/repositories/asr_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

//==============================================================================
// Isolate Worker Functions and Parameters (Top-Level)
//==============================================================================

/// Parameters for initializing offline recognizers in a separate isolate.
class OfflineInitParams {
  final ModelConfig modelConfig;
  final String modelPath;
  final String vadModelPath;

  OfflineInitParams({
    required this.modelConfig,
    required this.modelPath,
    required this.vadModelPath,
  });
}

/// Top-level function to prepare VAD and OfflineRecognizer in an isolate.
/// This function is safe to be sent via `compute`.
Future<Map<String, dynamic>> _prepareRecognizersInIsolate(OfflineInitParams params) async {
  sherpa_onnx.initBindings();
  final modelPath = params.modelPath;
  final modelConfig = params.modelConfig;

  // Create VAD
  final sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
    model: params.vadModelPath,
    minSilenceDuration: 0.25,
    minSpeechDuration: 0.5,
  );
  final vadConfig = sherpa_onnx.VadModelConfig(sileroVad: sileroVadConfig);
  final vad = sherpa_onnx.VoiceActivityDetector(config: vadConfig, bufferSizeInSeconds: 10);
  
  // Create Offline Recognizer
  final moonshine = sherpa_onnx.OfflineMoonshineModelConfig(
    preprocessor: '$modelPath/preprocess.onnx',
    encoder: '$modelPath/encode.int8.onnx',
    uncachedDecoder: '$modelPath/uncached_decode.int8.onnx',
    cachedDecoder: '$modelPath/cached_decode.int8.onnx',
  );
  final offlineModelConfig = sherpa_onnx.OfflineModelConfig(
    moonshine: moonshine,
    tokens: '$modelPath/tokens.txt',
    numThreads: 1,
  );
  final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(model: offlineModelConfig);
  final recognizer = sherpa_onnx.OfflineRecognizer(recognizerConfig);
  
  return {'vad': vad, 'recognizer': recognizer};
}

/// Top-level function to decode audio in an isolate.
String _decodeInIsolate(Map<String, dynamic> params) {
  final recognizer = params['recognizer'] as sherpa_onnx.OfflineRecognizer;
  final samples = params['samples'] as Float32List;

  final stream = recognizer.createStream();
  stream.acceptWaveform(samples: samples, sampleRate: 16000);
  recognizer.decode(stream);
  final result = recognizer.getResult(stream).text;
  stream.free();
  return result;
}

/// Top-level helper function to get VAD model path from assets.
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


//==============================================================================
// OfflineVadDataSource Implementation
//==============================================================================

class OfflineVadDataSource extends BaseSherpaDataSource implements AsrDataSource {
  sherpa_onnx.VoiceActivityDetector? _vad;
  sherpa_onnx.OfflineRecognizer? _recognizer;
  String _accumulatedText = '';

  OfflineVadDataSource({required super.config, required super.ref});

  @override
  Stream<PreparationStatus> prepare(String modelId) async* {
    final modelConfig = findModelConfigById(modelId);
    if (modelConfig == null) {
      yield PreparationStatus(PreparationStep.error, "未找到ID为 '$modelId' 的模型配置");
      return;
    }

    Directory? modelDir;
    try {
      final localVadModelPath = await _getVadModelPathFromAssets();
      if (localVadModelPath == null) {
        throw Exception("无法准备 VAD 模型");
      }

      final fileManager = ref.read(fileManagerProvider);
      modelDir = await fileManager.getResourceDirectory(
          moduleName: 'asr', resourceType: 'models', resourceId: modelConfig.id);
      
      if (!await fileManager.validateFilesExist(modelDir, modelConfig.files)) {
        yield* downloadAndValidateModel(modelDir, modelConfig, ref);
        await fileManager.cleanOldVersions(moduleName: 'asr', resourceType: 'models', 
            resourceName: modelConfig.name, currentVersionId: modelConfig.id);
      }
      
      yield const PreparationStatus(PreparationStep.checking, "正在加载模型到内存...");
      
      final params = OfflineInitParams(
        modelConfig: modelConfig, 
        modelPath: modelDir.path,
        vadModelPath: localVadModelPath,
      );
      
      final recognizers = await compute(_prepareRecognizersInIsolate, params);
      _vad = recognizers['vad'];
      _recognizer = recognizers['recognizer'];
      
      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");

    } catch (e) {
      if (modelDir != null) await ref.read(fileManagerProvider).cleanDirectory(modelDir);
      yield PreparationStatus(PreparationStep.error, "模型准备失败: $e");
    }
  }

  @override
  Future<void> start() async {
    print("[OfflineVadDataSource] start called.");
    if (_vad == null || _recognizer == null) {
      final errorMsg = "引擎未初始化，无法开始录音。";
      print("[OfflineVadDataSource] ERROR: $errorMsg");
      resultController.addError(StateError(errorMsg));
      return;
    }
    
    _accumulatedText = '';
    audioSource = ref.read(audioSourceProvider);
    try {
      print("[OfflineVadDataSource] Starting audio source...");
      await audioSource!.start();
      print("[OfflineVadDataSource] Audio source started. Listening to stream...");
    } catch(e) {
      print("[OfflineVadDataSource] ERROR starting audio source: $e");
      resultController.addError(e);
      return;
    }

    audioSubscription = audioSource!.stream.listen((audioChunk) {
      // This is a high-frequency log, uncomment only if needed
      // print("[OfflineVadDataSource] Received audio chunk of size ${audioChunk.length}");
      final samples = AudioUtils.bytesToFloat32(Uint8List.fromList(audioChunk));
      _vad!.acceptWaveform(samples);
      if(_vad!.isDetected()){
        while (!_vad!.isEmpty()) {
          print("[OfflineVadDataSource] VAD detected speech segment.");
          final segment = _vad!.front().samples;
          _runOfflineRecognition(segment);
          _vad!.pop();
        }
      }
      
    });
  }
  
  Future<void> _runOfflineRecognition(Float32List samples) async {
    if (_recognizer == null) return;
    
    // print("[OfflineVadDataSource] Running offline recognition in background...");
    final text = await compute(_decodeInIsolate, {'recognizer': _recognizer!, 'samples': samples});

    if (text.isNotEmpty) {
      _accumulatedText += "$text ";
      print("[OfflineVadDataSource] Recognition result: '$text'. Accumulated: '$_accumulatedText'");
      resultController.add(AsrResult(text: _accumulatedText, isFinal: false));
    }
}

  @override
  Future<void> stop() async {
    print("[OfflineVadDataSource] stop called.");
    
    print("[OfflineVadDataSource] Flushing VAD buffer...");
    _vad?.flush();
    while (_vad != null && !_vad!.isEmpty()) {
      print("[OfflineVadDataSource] VAD detected speech segment during flush.");
      final segment = _vad!.front().samples;
      await _runOfflineRecognition(segment);
      _vad!.pop();
    }
    
    print("[OfflineVadDataSource] Emitting final result: '$_accumulatedText'");
    resultController.add(AsrResult(text: _accumulatedText, isFinal: true));
    
    await super.stop();
    print("[OfflineVadDataSource] Audio source stopped.");
  }

  @override
  void dispose() {
    _vad?.free();
    _recognizer?.free();
    super.dispose();
  }
}