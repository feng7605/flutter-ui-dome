import '../entities/speech_result.dart';
//仓库接口，领域层只依赖接口。
abstract class SpeechRecognizerRepository {
  Future<SpeechResult> recognize();
}