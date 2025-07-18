import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_frame/features/asr/data/datasources/sherpa_model_state.dart';
import 'package:flutter_frame/features/asr/data/utils/utils.dart';
import 'package:flutter_frame/features/asr/presentation/providers/recognition_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx; // 依赖原生库
import 'audio_recorder_service.dart'; // 依赖原生库
import 'abstract_recognition_service.dart'; // 引入抽象接口

// 注意类名改为 MobileRecognitionService
class RecognitionService implements AbstractRecognitionService {
  final Ref _ref;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  final int _sampleRate = 16000;

  final _resultController = StreamController<RecognitionResult>.broadcast();
  
  @override // 实现接口
  Stream<RecognitionResult> get resultStream => _resultController.stream;

  RecognitionService(this._ref);

  Future<void> _initialize() async {
    // ... 你的 _initialize 方法代码完全不变 ...
    if (_recognizer != null) return;
    sherpa_onnx.initBindings();

    final modelManager = _ref.read(sherpaModelManagerProvider.notifier);
    await modelManager.setupModels();

    final modelState = _ref.read(sherpaModelManagerProvider);
    if (modelState.status != ModelStatus.ready) {
      throw Exception(modelState.message ?? "Sherpa 模型未能准备就绪");
    }

    final modelConfig = await getOnlineModelConfig();
    final config = sherpa_onnx.OnlineRecognizerConfig(model: modelConfig, ruleFsts: '',);
    _recognizer = sherpa_onnx.OnlineRecognizer(config);
    print("Sherpa Recognizer 已成功初始化。");
  }

  @override // 实现接口
  Future<void> ensureInitialized() async {
    await _initialize();
  }

  @override // 实现接口
  Future<void> start() async {
    // ... 你的 start 方法代码完全不变 ...
    if (_recognizer == null) {
      throw Exception("识别器未初始化。请先调用 ensureInitialized。");
    }
    _stream = _recognizer!.createStream();

    final audioService = _ref.read(audioRecorderServiceProvider);
    await audioService.start();

    String lastText = '';

    _audioSubscription = audioService.audioStream?.listen((data) {
      if (_recognizer == null || _stream == null || !_resultController.hasListener) {
        return;
      }

      final samples = convertBytesToFloat32(Uint8List.fromList(data));
      _stream!.acceptWaveform(samples: samples, sampleRate: _sampleRate);

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }
      
      final currentText = _recognizer!.getResult(_stream!).text;
      _resultController.add(RecognitionResult(lastText + currentText, RecognitionResultType.partial));

      if (_recognizer!.isEndpoint(_stream!)) {
        final finalTranscript = lastText + currentText;
        if (finalTranscript.isNotEmpty) {
           _resultController.add(RecognitionResult(finalTranscript, RecognitionResultType.finalResult));
           lastText = '$finalTranscript\n';
        }
        _recognizer!.reset(_stream!);
      }
    });
  }

  @override // 实现接口
  Future<void> stop() async {
    // ... 你的 stop 方法代码完全不变 ...
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    
    if (_recognizer != null && _stream != null) {
      final remainingText = _recognizer!.getResult(_stream!).text;
      if (remainingText.isNotEmpty) {
        _resultController.add(RecognitionResult(remainingText, RecognitionResultType.finalResult));
      }
    }

    _ref.read(audioRecorderServiceProvider).stop();
    _stream?.free();
    _stream = null;
  }
  
  @override // 实现接口
  void dispose() {
    // ... 你的 dispose 方法代码完全不变 ...
    _audioSubscription?.cancel();
    _resultController.close();
    _stream?.free();
    _recognizer?.free();
    print("MobileRecognitionService disposed");
  }
}