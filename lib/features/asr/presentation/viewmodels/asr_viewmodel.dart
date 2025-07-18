import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/asr_repository.dart';
import '../state/asr_screen_state.dart';

class AsrViewModel extends StateNotifier<AsrScreenState> {
  final AsrRepository _asrRepository;
  StreamSubscription? _recognitionSubscription;
  StreamSubscription? _preparationSubscription;

  AsrViewModel(this._asrRepository) : super(const AsrScreenState(status: AsrStatus.initial));

  void prepare() {
    _preparationSubscription?.cancel();
    state = const AsrScreenState(status: AsrStatus.preparing, message: "准备中...");

    _preparationSubscription = _asrRepository.prepare().listen(
      (status) {
        switch (status.step) {
          case PreparationStep.checking:
          case PreparationStep.downloading:
            state = state.copyWith(
              status: AsrStatus.preparing,
              message: status.message,
              preparationProgress: status.progress,
            );
            break;
          case PreparationStep.ready:
            state = state.copyWith(
              status: AsrStatus.ready,
              message: status.message,
              clearProgress: true,
            );
            break;
          case PreparationStep.error:
            state = state.copyWith(
              status: AsrStatus.error,
              message: status.message,
            );
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

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _preparationSubscription?.cancel();
    super.dispose();
  }
}