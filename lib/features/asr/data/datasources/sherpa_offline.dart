import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/core/services/audio/microphone_audio_source.dart';
import 'package:flutter_frame/core/utils/audio_utils.dart';
import 'package:flutter_frame/features/asr/data/datasources/asr_base.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/data/utils/utils.dart';
import 'package:flutter_frame/features/asr/domain/entities/asr_result.dart';
import 'package:flutter_frame/features/asr/domain/repositories/asr_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

//==============================================================================
// 1. Isolate Communication Protocol (定义通信协议)
//==============================================================================

/// 命令：从主 Isolate 发送到 ASR Isolate
enum _Command { init, process, stop, dispose }

/// 消息体：封装命令和数据
class _IsolateCommand {
  final _Command command;
  final dynamic data;
  _IsolateCommand(this.command, [this.data]);
}

/// ASR Isolate 初始化所需的全部参数
class _InitParams {
  final ModelConfig modelConfig;
  final String modelPath;
  final String vadModelPath;
  // 重要：将主 Isolate 的 SendPort 传进来，以便 ASR Isolate 可以回传消息
  final SendPort mainSendPort;

  _InitParams({
    required this.modelConfig,
    required this.modelPath,
    required this.vadModelPath,
    required this.mainSendPort,
  });
}


//==============================================================================
// 2. Isolate Entry Point (Isolate 的入口函数，将在后台运行)
//==============================================================================

/// 这是 ASR Isolate 的主函数，它不能是类的方法。
void asrIsolateEntry(_InitParams initParams) {
  // Isolate 内部状态
  sherpa_onnx.VoiceActivityDetector? vad;
  sherpa_onnx.OfflineRecognizer? recognizer;
  String accumulatedText = '';
  final mainSendPort = initParams.mainSendPort;

  // Isolate 内部的通信端口，用于接收来自主 Isolate 的后续命令
  final isolateReceivePort = ReceivePort();
  
  // 监听来自主 Isolate 的命令
  isolateReceivePort.listen((message) {
    if (message is! _IsolateCommand) return;

    switch (message.command) {
      case _Command.process:
        if (vad == null || recognizer == null || message.data is! List<int>) return;
        
        final audioChunk = Uint8List.fromList(message.data);
        final samples = AudioUtils.bytesToFloat32(audioChunk);
        vad.acceptWaveform(samples);

        while (!vad.isEmpty()) {
          final segment = vad.front();
          final stream = recognizer.createStream();
          stream.acceptWaveform(samples: segment.samples, sampleRate: 16000);
          recognizer.decode(stream);
          final result = recognizer.getResult(stream).text;
          stream.free();

          if (result.isNotEmpty) {
            accumulatedText += "$result ";
            debugPrint("$result ");
            // 将中间结果发送回主 Isolate
            mainSendPort.send(AsrResult(text: accumulatedText, isFinal: false));
          }
          vad.pop();
        }
        break;
      
      case _Command.stop:
        if (vad == null) break;
        vad.flush();
        // ... (此处可以添加 flush 后的识别逻辑，如果需要) ...
        // 发送最终结果
        mainSendPort.send(AsrResult(text: accumulatedText, isFinal: true));
        accumulatedText = '';
        break;

      case _Command.dispose:
        vad?.free();
        recognizer?.free();
        isolateReceivePort.close(); // 关闭端口，Isolate 将退出
        break;
        
      default:
        break;
    }
  });

  // --- Isolate 初始化流程 ---
  try {
    sherpa_onnx.initBindings();
    
    // 1. 创建 VAD
    final sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
      model: initParams.vadModelPath, minSilenceDuration: 0.5, minSpeechDuration: 0.2);
    final vadConfig = sherpa_onnx.VadModelConfig(sileroVad: sileroVadConfig, numThreads: 1, debug: true);
    vad = sherpa_onnx.VoiceActivityDetector(config: vadConfig, bufferSizeInSeconds: 10);
    
    // 2. 创建 Recognizer
    final modelPath = initParams.modelPath;
    final moonshine = sherpa_onnx.OfflineMoonshineModelConfig(
      preprocessor: '$modelPath/preprocess.onnx', encoder: '$modelPath/encode.int8.onnx',
      uncachedDecoder: '$modelPath/uncached_decode.int8.onnx', cachedDecoder: '$modelPath/cached_decode.int8.onnx');
    final offlineModelConfig = sherpa_onnx.OfflineModelConfig(
      moonshine: moonshine, tokens: '$modelPath/tokens.txt', numThreads: 1);
    final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(model: offlineModelConfig);
    recognizer = sherpa_onnx.OfflineRecognizer(recognizerConfig);

    // 3. 将自己的 SendPort 发送给主 Isolate，以便主 Isolate 可以发送后续命令
    mainSendPort.send(isolateReceivePort.sendPort);
  } catch (e) {
    mainSendPort.send(e); // 如果初始化失败，将异常发送回去
  }
}


//==============================================================================
// 3. OfflineVadDataSource Refactoring (重构数据源作为 Isolate 控制器)
//==============================================================================

class OfflineVadDataSource extends BaseSherpaDataSource implements AsrDataSource {
  Isolate? _asrIsolate;
  SendPort? _asrIsolateSendPort;

  OfflineVadDataSource({required super.config, required super.ref});

  @override
  Stream<PreparationStatus> prepare(String modelId) async* {
    // 清理旧的 Isolate (如果有)
    await _disposeIsolate();

    final modelConfig = findModelConfigById(modelId);
    if (modelConfig == null) {
      yield PreparationStatus(PreparationStep.error, "未找到ID为 '$modelId' 的模型配置");
      return;
    }

    yield const PreparationStatus(PreparationStep.checking, "准备资源文件...");
    Directory? modelDir;
    try {
      // 在主 Isolate 中安全地准备文件路径
      final fileManager = ref.read(fileManagerProvider);
      modelDir = await fileManager.getResourceDirectory(
          moduleName: 'asr', resourceType: 'models', resourceId: modelConfig.id);
      
      if (!await fileManager.validateFilesExist(modelDir, modelConfig.files)) {
        yield* downloadAndValidateModel(modelDir, modelConfig, ref);
        await fileManager.cleanOldVersions(moduleName: 'asr', resourceType: 'models', 
            resourceName: modelConfig.name, currentVersionId: modelConfig.id);
      }
      final localVadModelPath = await _getVadModelPathFromAssets(); // 传递 ref

      yield const PreparationStatus(PreparationStep.checking, "正在启动并加载模型到后台...");

      // 创建一个端口，用于接收来自新 Isolate 的消息 (它的 SendPort 或错误)
      final mainReceivePort = ReceivePort();
      final completer = Completer<void>();

      mainReceivePort.listen((message) {
        if (message is SendPort) {
          // 成功！收到了 ASR Isolate 的 SendPort
          _asrIsolateSendPort = message;
          if (!completer.isCompleted) completer.complete();
        } else if (message is Error || message is Exception) {
          // 失败！收到了来自 ASR Isolate 的错误
          if (!completer.isCompleted) completer.completeError(message);
        } else if (message is AsrResult) {
          // 在运行期间，收到识别结果
          resultController.add(message);
        }
      });
      
      // 准备初始化参数
      final initParams = _InitParams(
        modelConfig: modelConfig,
        modelPath: modelDir.path,
        vadModelPath: localVadModelPath!,
        mainSendPort: mainReceivePort.sendPort,
      );

      // 启动 Isolate
      _asrIsolate = await Isolate.spawn(asrIsolateEntry, initParams, 
        onError: mainReceivePort.sendPort, onExit: mainReceivePort.sendPort);

      // 等待 Isolate 初始化完成 (或失败)
      await completer.future;

      yield const PreparationStatus(PreparationStep.ready, "模型已就绪");

    } catch (e) {
      if (modelDir != null) await ref.read(fileManagerProvider).cleanDirectory(modelDir);
      yield PreparationStatus(PreparationStep.error, "模型准备失败: $e");
      await _disposeIsolate();
    }
  }

  @override
  Future<void> start() async {
    if (_asrIsolateSendPort == null) {
      resultController.addError(StateError("引擎未就绪，无法开始。"));
      return;
    }
    
    // 使用原始麦克风数据
    audioSource = ref.read(microphoneAudioSourceProvier); // 假设你有这个 Provider
    await audioSource!.start();
    
    audioSubscription = audioSource!.stream.listen((audioChunk) {
      // 将音频数据块发送到后台 Isolate 进行处理
      _asrIsolateSendPort?.send(_IsolateCommand(_Command.process, audioChunk));
    });
  }

  @override
  Future<void> stop() async {
    await super.stop(); // 停止麦克风和监听
    // 发送 stop 命令到后台 Isolate，让它处理 final result
    _asrIsolateSendPort?.send(_IsolateCommand(_Command.stop));
  }

  @override
  void dispose() {
    _disposeIsolate();
    super.dispose();
  }
  
  Future<void> _disposeIsolate() async {
    _asrIsolateSendPort?.send(_IsolateCommand(_Command.dispose));
    _asrIsolate?.kill(priority: Isolate.immediate);
    _asrIsolate = null;
    _asrIsolateSendPort = null;
  }

/// 由于 _getVadModelPathFromAssets 不再是类成员，需要作为 top-level 函数
/// 或者在调用处传递 ref (如上所示)
Future<String?> _getVadModelPathFromAssets() async {
  try {
    const assetPath = 'assets/res/models/vad.onnx';
    // 注意：这里不能直接调用 getApplicationDocumentsDirectory
    // 需要通过一种方式来访问，如果这个类是 ConsumerStatefulWidget 的一部分，会很简单
    // 既然是在 Provider 中，我们假定它能以某种方式获取到 context 或路径
    final appDocsDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDocsDir.path}/vad.onnx';
    final localFile = File(localPath);
    if (await localFile.exists()) {
      return localPath;
    }
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;
    await localFile.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
    );
    return localPath;
  } catch (e) {
    debugPrint("从 assets 复制 VAD 模型文件时失败: $e");
    return null;
  }
}

}


// 别忘了你需要一个原始麦克风的 Provider
final microphoneAudioSourceProvier = Provider<AudioSource>((ref) {
  final source = MicrophoneAudioSource();
  ref.onDispose(() => source.dispose());
  return source;
});