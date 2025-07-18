import 'dart:async';
import '../entities/asr_result.dart';
import '../repositories/asr_repository.dart';

class StartRecognitionUseCase {
  final AsrRepository _repository;
  StartRecognitionUseCase(this._repository);

  Stream<AsrResult> call() {
    return _repository.startStreamingRecognition();
  }
}