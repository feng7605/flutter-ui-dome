import 'package:flutter/foundation.dart';
// AsrConfig (顶层)
@immutable
class AsrConfig {
  final String defaultSupplier;
  final List<SupplierConfig> suppliers;

  const AsrConfig({required this.defaultSupplier, required this.suppliers});

  factory AsrConfig.fromJson(Map<String, dynamic> json) {
    return AsrConfig(
      defaultSupplier: json['defaultSupplier'] as String,
      suppliers: (json['suppliers'] as List<dynamic>)
          .map((e) => SupplierConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  SupplierConfig? getSupplier(String name) {
    try {
      return suppliers.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}

// SupplierConfig (供应商)
@immutable
class SupplierConfig {
  final String name;
  final String label;
  final String desc;
  final List<RecognitionModeConfig> modes;

  const SupplierConfig({
    required this.name,
    required this.label,
    required this.desc,
    required this.modes,
  });

  factory SupplierConfig.fromJson(Map<String, dynamic> json) {
    return SupplierConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      desc: json['desc'] as String,
      modes: (json['modes'] as List<dynamic>)
          .map((e) => RecognitionModeConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  RecognitionModeConfig? getMode(String type) {
    try {
      return modes.firstWhere((m) => m.type.toLowerCase() == type.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}

// RecognitionModeConfig (识别模式)
@immutable
class RecognitionModeConfig {
  final String type; // "streaming" or "once"
  final String label;
  final List<ModelConfig> models;

  const RecognitionModeConfig({
    required this.type,
    required this.label,
    required this.models,
  });

  factory RecognitionModeConfig.fromJson(Map<String, dynamic> json) {
    return RecognitionModeConfig(
      type: json['type'] as String,
      label: json['label'] as String,
      models: (json['models'] as List<dynamic>)
          .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}


// ModelConfig (具体模型)
@immutable
class ModelConfig {
  final String id; // Unique ID for the model
  final String name;
  final String version;
  final String downloadUrl;
  final String modelType;
  final List<String> files;
  final String checksum;

  const ModelConfig({
    required this.id,
    required this.name,
    required this.version,
    required this.downloadUrl,
    required this.modelType,
    required this.files,
    required this.checksum,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      downloadUrl: json['downloadUrl'] as String,
      modelType: json['modelType'] as String,
      files: List<String>.from(json['files'] as List),
      checksum: json['checksum'] as String,
    );
  }
}