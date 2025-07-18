import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/asr_repository.dart';
import '../state/asr_screen_state.dart';

class AsrViewModel extends StateNotifier<AsrScreenState> {
  final AsrRepository _asrRepository;
  StreamSubscription? _recognitionSubscription;
  StreamSubscription? _preparationSubscription;

  AsrViewModel(this._asrRepository, {
    String? initialMode, 
    String? initialModel,
  }) : super(AsrScreenState(
          status: AsrStatus.initial,
          selectedModeType: initialMode,
          selectedModelId: initialModel,
        )) {
    checkStatus();
  }

  /// 检查本地模型状态（快速，非阻塞）
  Future<void> checkStatus() async {
    state = state.copyWith(status: AsrStatus.checking, message: "检查模型状态...");
    try {
      final bool ready = await _asrRepository.isReady(state.selectedModelId!);
      
      if (ready) {
        // 如果模型文件存在，我们仍然需要加载它到内存
        // 为了简化，我们直接进入准备流程，但可以优化
        // 为了更好的体验，这里可以设置为 readyToLoad 状态
        // 这里我们直接调用 prepare，但用户也可以手动调用
        prepareAndLoad();
      } else {
        // 如果文件不存在，进入需要下载的状态
        state = state.copyWith(
          status: AsrStatus.requiresDownload,
          message: "离线识别引擎需要下载模型文件。",
        );
      }
    } catch (e) {
      state = state.copyWith(status: AsrStatus.error, message: "检查状态时出错: $e");
    }
  }

  /// 下载、解压并加载模型到内存（重量级操作，由用户触发）
  void prepareAndLoad() {
    _preparationSubscription?.cancel();
    _preparationSubscription = _asrRepository.prepare(state.selectedModelId!).listen(
      (status) {
        switch (status.step) {
          case PreparationStep.checking:
             state = state.copyWith(status: AsrStatus.checking, message: status.message);
             break;
          case PreparationStep.downloading:
            state = state.copyWith(
              status: AsrStatus.downloading, // 使用新的下载状态
              message: status.message,
              downloadProgress: status.progress,
            );
            break;
          case PreparationStep.ready:
            state = state.copyWith(status: AsrStatus.ready, message: status.message);
            break;
          case PreparationStep.error:
            state = state.copyWith(status: AsrStatus.error, message: status.message);
            break;
        }
      },
      onError: (e) => state = state.copyWith(status: AsrStatus.error, message: e.toString()),
    );
  }

  void toggleRecognition() {
    if (state.status == AsrStatus.recognizing) {
      _stop();
    } else if (state.status == AsrStatus.ready) {
      _start();
    }
  }

  void _start() {
    _recognitionSubscription?.cancel();
    state = state.copyWith(status: AsrStatus.recognizing, recognizedText: '');
    
    _recognitionSubscription = _asrRepository.startStreamingRecognition().listen(
      (result) => state = state.copyWith(recognizedText: result.text),
      onError: (e) => state = state.copyWith(status: AsrStatus.error, message: e.toString()),
      onDone: () {
        if (state.status == AsrStatus.recognizing) {
          state = state.copyWith(status: AsrStatus.ready);
        }
      },
    );
  }

  void _stop() {
    _asrRepository.stopStreamingRecognition();
    _recognitionSubscription?.cancel();
    _recognitionSubscription = null;
    state = state.copyWith(status: AsrStatus.ready);
  }

  //处理用户的选择变化
  void selectMode(String modeType) {
    // 切换模式时，重置模型选择，并重新检查状态
    state = state.copyWith(selectedModeType: modeType, selectedModelId: null);
    checkStatus();
  }
  void selectModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
    checkStatus();
  }
  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _preparationSubscription?.cancel();
  }

  void recognizeOnce() {
    _asrRepository.recognizeOnce();
  }
}