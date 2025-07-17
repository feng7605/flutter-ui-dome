//语音识别配置
class SpeechConfig {
  //默认供应商
  final String defaultSupplier;
  final List<SpeechSupplier> suppliers;

  SpeechConfig({
    required this.suppliers,
    required this.defaultSupplier,
  });

  factory SpeechConfig.fromJson(Map<String, dynamic> json) {
    return SpeechConfig(
      defaultSupplier: json['defaultSupplier'],
      suppliers: (json['suppliers'] as List)
        .map<SpeechSupplier>((supplier) => SpeechSupplier.fromJson(supplier))
        .toList(),
    );
  }
}

class SpeechSupplier {
  final String name;
  final String label;
  final String desc;
  final List<SpeechModel> models;

  SpeechSupplier({
    required this.name,
    required this.label,
    required this.desc,
    required this.models,
  });

  factory SpeechSupplier.fromJson(Map<String, dynamic> json) {
    return SpeechSupplier(
      name: json['name'],
      label: json['label'],
      desc: json['desc'],
      models: (json['models'] as List)
        .map<SpeechModel>((model) => SpeechModel.fromJson(model))
        .toList(),
    );
  }
}

class SpeechModel {
  final String name;
  final String version;
  final String localPath;
  final String downloadUrl;
  final String modelType;
  final String modelParams;
  final String modelVersion;
  final int fileSize; // 文件大小（字节），用于校验和显示下载进度
  final String checksum;
  //final List<String> fileType; // 解压后需要校验的文件列表
  final bool isUse;

  SpeechModel({
    required this.name,
    required this.version,
    required this.localPath,
    required this.downloadUrl,
    required this.modelType,
    required this.modelParams,
    required this.modelVersion,
    required this.fileSize,
    required this.checksum,
    //required this.fileType,
    this.isUse = false,
  });
  factory SpeechModel.fromJson(Map<String, dynamic> json) {
    return SpeechModel(
      name: json['name'],
      version: json['version'],
      localPath: json['localPath'],
      downloadUrl: json['downloadUrl'],
      modelType: json['modelType'],
      modelParams: json['modelParams'],
      modelVersion: json['modelVersion'],
      fileSize: json['fileSize'],
      checksum: json['checksum'],
      //fileType: json['fileType'],
      isUse: json['isUse'] ?? false,
    );
  }
}