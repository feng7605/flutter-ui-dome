import 'package:flutter/foundation.dart';

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

  // 辅助方法，通过名称获取特定的供应商配置
  SupplierConfig? getSupplier(String name) {
    try {
      return suppliers.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }
}

@immutable
class SupplierConfig {
  final String name; // e.g., "sherpa", "iflytek"
  final String label;
  final String desc;
  final List<ModelConfig> models;

  const SupplierConfig({
    required this.name,
    required this.label,
    required this.desc,
    required this.models,
  });

  factory SupplierConfig.fromJson(Map<String, dynamic> json) {
    return SupplierConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      desc: json['desc'] as String,
      models: (json['models'] as List<dynamic>)
          .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class ModelConfig {
  final String name;
  final String version;
  final String localPath;
  final String downloadUrl;
  final String modelType;
  final String modelParams;
  final String modelVersion;
  final int fileSize;
  final String checksum;

  const ModelConfig({
    required this.name,
    required this.version,
    required this.localPath,
    required this.downloadUrl,
    required this.modelType,
    required this.modelParams,
    required this.modelVersion,
    required this.fileSize,
    required this.checksum,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      name: json['name'] as String,
      version: json['version'] as String,
      localPath: json['localPath'] as String,
      downloadUrl: json['downloadUrl'] as String,
      modelType: json['modelType'] as String,
      modelParams: json['modelParams'] as String,
      modelVersion: json['modelVersion'] as String,
      fileSize: json['fileSize'] as int,
      checksum: json['checksum'] as String,
    );
  }
}