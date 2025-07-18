
import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../utils/utils.dart';
import 'asr_data_source.dart';

// 这是移动端的实现
class SherpaDataSourceImpl implements AsrDataSource {
  final _audioRecorder = AudioRecorder();
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  String _lastRecognizedText = '';

  final _resultController = StreamController<AsrResult>.broadcast();

  @override
  Stream<AsrResult> get resultStream => _resultController.stream;

  @override
  Stream<PreparationStatus> prepare() async* {
    try {
      sherpa_onnx.initBindings();
      yield const PreparationStatus(PreparationStep.checking, "正在检查模型文件...");
      await Future.delayed(const Duration(milliseconds: 500)); 

      final modelConfig = await getOnlineModelConfig();
      final config = sherpa_onnx.OnlineRecognizerConfig(model: modelConfig, ruleFsts: '');
      _recognizer = sherpa_onnx.OnlineRecognizer(config);

      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");
    } catch (e) {
      yield PreparationStatus(PreparationStep.error, "模型准备失败: $e");
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
    _audioSubscription?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    _resultController.close();
  }
}