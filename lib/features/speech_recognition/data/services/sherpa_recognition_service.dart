import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_frame/features/speech_recognition/data/datasources/sherpa_model_state.dart';
import 'package:flutter_frame/features/speech_recognition/data/utils/utils.dart';
import 'package:flutter_frame/features/speech_recognition/presentation/providers/recognition_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'audio_recorder_service.dart';// 假设 getOnlineModelConfig 和 convertBytesToFloat32 在这里

// 定义识别结果的类型，方便区分
enum RecognitionResultType { partial, finalResult }

class RecognitionResult {
  final String text;
  final RecognitionResultType type;
  RecognitionResult(this.text, this.type);
}

class SherpaRecognitionService {
  final Ref _ref;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  final int _sampleRate = 16000;

  // 使用 StreamController 向外广播识别结果
  final _resultController = StreamController<RecognitionResult>.broadcast();
  Stream<RecognitionResult> get resultStream => _resultController.stream;

  SherpaRecognitionService(this._ref);

  // 初始化识别器
  Future<void> _initialize() async {
    if (_recognizer != null) return; // 已经初始化
    sherpa_onnx.initBindings();

    final modelManager = _ref.read(sherpaModelManagerProvider.notifier);
    await modelManager.setupModels(); // 这个方法会处理检查/下载逻辑

    // 3. 检查模型状态
    final modelState = _ref.read(sherpaModelManagerProvider);
    if (modelState.status != ModelStatus.ready) {
      throw Exception(modelState.message ?? "Sherpa 模型未能准备就绪");
    }

    // 4. 模型就绪后，才创建识别器
    final modelConfig = await getOnlineModelConfig();
    final config = sherpa_onnx.OnlineRecognizerConfig(model: modelConfig, ruleFsts: '',);
    _recognizer = sherpa_onnx.OnlineRecognizer(config);
    print("Sherpa Recognizer 已成功初始化。");
  }
  Future<void> ensureInitialized() async {
    await _initialize();
  }
  // 开始识别
  Future<void> start() async {
    if (_recognizer == null) {
      throw Exception("识别器未初始化。请先调用 ensureInitialized。");
    }
    _stream = _recognizer!.createStream();

    final audioService = _ref.read(audioRecorderServiceProvider);
    await audioService.start();

    String lastText = ''; // 用于拼接最终结果

    _audioSubscription = audioService.audioStream?.listen((data) {
      if (_recognizer == null || _stream == null || !_resultController.hasListener) {
        print('Skipping waveform processing. Recognizer/Stream is null or no listeners.');
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
        // 是一个端点，意味着一句话说完了
        final finalTranscript = lastText + currentText;
        if (finalTranscript.isNotEmpty) {
           _resultController.add(RecognitionResult(finalTranscript, RecognitionResultType.finalResult));
           lastText = '$finalTranscript\n'; // 为下一句做准备
        }
        _recognizer!.reset(_stream!);
      }
    });
  }

  // 停止识别
  Future<void> stop() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    
    // 发送最后一次识别结果
    if (_recognizer != null && _stream != null) {
      // 在停止前，进行一次“冲刷”，获取最后的识别结果
      final remainingText = _recognizer!.getResult(_stream!).text;
      if (remainingText.isNotEmpty) {
        _resultController.add(RecognitionResult(remainingText, RecognitionResultType.finalResult));
      }
    }

    _ref.read(audioRecorderServiceProvider).stop();
    _stream?.free();
    _stream = null;
  }
  
  // 释放所有资源
  void dispose() {
    _audioSubscription?.cancel();
    _resultController.close();
    _stream?.free();
    _recognizer?.free();
    print("SherpaRecognitionService disposed");
  }
}

// 为这个服务创建 Provider
final sherpaRecognitionServiceProvider = Provider.autoDispose<SherpaRecognitionService>((ref) {
  final service = SherpaRecognitionService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});