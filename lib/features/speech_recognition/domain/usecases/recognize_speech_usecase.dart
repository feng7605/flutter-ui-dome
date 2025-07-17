import '../repositories/speech_recognizer_repository.dart';
import '../entities/speech_result.dart';
//用例，业务逻辑的入口。
class RecognizeSpeechUseCase {
  final SpeechRecognizerRepository repository;

  RecognizeSpeechUseCase(this.repository);

  Future<SpeechResult> call() => repository.recognize();
}