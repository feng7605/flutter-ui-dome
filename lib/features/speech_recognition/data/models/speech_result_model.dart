//数据层模型，便于与实体转换。
import '../../domain/entities/speech_result.dart';

class SpeechResultModel extends SpeechResult {
  SpeechResultModel({required super.text});

  factory SpeechResultModel.fromJson(Map<String, dynamic> json) =>
      SpeechResultModel(text: json['text']);
}