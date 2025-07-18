
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_frame/features/asr/data/datasources/sherpa_preparation_worker.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/data/services/model_downloader.dart';
import 'package:flutter_frame/features/asr/data/services/model_file_manager.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../utils/utils.dart';
import 'asr_data_source.dart';

// 这是移动端的实现
class SherpaDataSourceImpl implements AsrDataSource {
  final SupplierConfig config;
  final _fileManager = ModelFileManager();
  final _downloader = ModelDownloader();

  final _audioRecorder = AudioRecorder();
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  String _lastRecognizedText = '';

  final _resultController = StreamController<AsrResult>.broadcast();

  SherpaDataSourceImpl({required this.config});

  @override
  Stream<AsrResult> get resultStream => _resultController.stream;

  @override
  Stream<PreparationStatus> prepare() async* {
    final modelConfig = config.models.first;
    Directory? modelDir;
    try {
      sherpa_onnx.initBindings();
      
      yield const PreparationStatus(PreparationStep.checking, "正在检查本地模型...");
      modelDir = await _fileManager.getModelDirectory(modelConfig);
      
      final bool isModelValid = await _fileManager.validateModelFiles(modelDir, modelConfig);

      if (!isModelValid) {
        // 如果模型无效，则下载并解压
        yield* _downloadAndValidateModel(modelDir, modelConfig);
        _fileManager.cleanOldVersions(modelConfig);
      }
     // 步骤 2: **将耗时操作交给后台 Isolate**
      yield const PreparationStatus(PreparationStep.checking, "正在加载模型到内存...");

      // 准备传递给 Isolate 的参数
      final params = SherpaInitParams(
        supplierConfig: config!,
        modelPath: modelDir.path,
      );

      // 使用 compute 在后台执行模型加载和识别器创建
      // `compute` 函数返回一个 Future，它代表了 Isolate 的计算结果。
      _recognizer = await compute(prepareRecognizerInIsolate, params);
      
      // 步骤 3: Isolate 返回结果后，在主线程更新状态
      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");
      
    } catch (e) {
      if (modelDir != null) {
        await _fileManager.cleanDirectory(modelDir);
      }
      yield PreparationStatus(PreparationStep.error, "模型准备失败: $e");
    }
  }

  // 保持 prepare 方法的逻辑清晰
  Stream<PreparationStatus> _downloadAndValidateModel(Directory modelDir, ModelConfig modelConfig) async* {
    // 清理可能存在的损坏文件
    await _fileManager.cleanDirectory(modelDir);
    // 重新创建目录
    await modelDir.create(recursive: true); // 确保目录存在

    // 使用 yield* 委托下载和解压流
    yield* _downloader.downloadAndUnzip(modelConfig, modelDir);

    // 下载解压后再次验证
    final isDownloadedModelValid = await _fileManager.validateModelFiles(modelDir, modelConfig);
    if (!isDownloadedModelValid) {
      // 如果验证失败，抛出异常，让外层 try-catch 处理回滚
      throw Exception("下载后的模型文件验证失败");
    }
  }

  @override
  Future<void> start() async {
    if (_recognizer == null) throw Exception("Sherpa Recognizer 未初始化。请先调用 prepare。");
    
    _stream = _recognizer!.createStream();
    _lastRecognizedText = '';
    
    if (!await _audioRecorder.hasPermission()) throw Exception("录音权限被拒绝");

    final audioStream = await _audioRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _audioSubscription = audioStream.listen((data) {
      if (_recognizer == null || _stream == null) return;
      
      final samples = convertBytesToFloat32(Uint8List.fromList(data));
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
    
    await _audioRecorder.stop();
    _stream?.free();
    _stream = null;
  }


  @override
  void dispose() {
    // ... dispose 方法保持不变 ...
    _audioSubscription?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    _resultController.close();
  }
}