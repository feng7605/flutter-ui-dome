
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'abstract_recognition_service.dart';

// 条件化导入平台特定的实现文件
import 'web_recognition_service.dart' 
    if (dart.library.io) 'mobile_recognition_service.dart';

// 条件化导入，但是现在两个文件都定义了同一个名为 'RecognitionService' 的类
import 'web_recognition_service.dart' 
    if (dart.library.io) 'mobile_recognition_service.dart';

// 这是你的应用将要使用的唯一 Provider
final recognitionServiceProvider = Provider.autoDispose<AbstractRecognitionService>((ref) {
  final service = RecognitionService(ref); 
  
  ref.onDispose(() => service.dispose());
  return service;
});