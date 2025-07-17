import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_frame/features/speech_recognition/data/models/speech_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  // 从本地 assets 加载配置（也可以改成从网络加载）
  Future<SpeechConfig> loadConfig() async {
    // 假设你的配置文件放在 assets/config/speech_config.json
    final jsonString = await rootBundle.loadString('assets/config/speech_config.json');
    final jsonMap = json.decode(jsonString);
    return SpeechConfig.fromJson(jsonMap);
  }
}

final speechConfigProvider = FutureProvider<SpeechConfig>((ref) {
  final configService = ConfigService();
  return configService.loadConfig();
});