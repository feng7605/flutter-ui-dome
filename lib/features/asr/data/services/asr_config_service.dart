import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsrConfigService {
  Future<AsrConfig> loadFromAssets(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AsrConfig.fromJson(jsonMap);
    } catch (e) {
      // 在生产环境中，你可能希望有一个默认的硬编码配置作为备用
      throw Exception('Failed to load ASR config from $path: $e');
    }
  }
}