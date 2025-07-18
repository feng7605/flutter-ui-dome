import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asr_config.dart'; // 引入 ModelConfig

class ModelFileManager {
  Future<Directory> _getModelsBaseDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDocDir.path}/asr_models');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }
  /// 获取特定模型的存储目录，采用分层结构
  Future<Directory> getModelDirectory(ModelConfig modelConfig) async {
    final baseDir = await _getModelsBaseDirectory();
    //采用分层路径
    final modelPath = '${baseDir.path}/${modelConfig.name}/${modelConfig.version}';
    final modelDir = Directory(modelPath);
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// 验证本地模型文件的完整性
  Future<bool> validateModelFiles(Directory modelDir, ModelConfig modelConfig) async {
    // 假设必须的文件列表
    final requiredFiles = modelConfig.files; 
    
    for (final fileName in requiredFiles) {
      final file = File('${modelDir.path}/$fileName');
      if (!await file.exists()) {
        print("Model file missing: ${file.path}");
        return false;
      }
    }
    
    // (可选) 添加校验和验证
    // final modelFile = File('${modelDir.path}/encoder-plus-decoder.onnx');
    // final fileHash = sha256.convert(await modelFile.readAsBytes()).toString();
    // if (fileHash != modelConfig.checksum) {
    //   print("Model file checksum mismatch!");
    //   return false;
    // }

    print("Local model files validated successfully.");
    return true;
  }

  /// 清理指定的模型目录
  Future<void> cleanDirectory(Directory modelDir) async {
    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
    }
  }

  /// 清理指定模型的所有旧版本
  Future<void> cleanOldVersions(ModelConfig currentModelConfig) async {
    print("开始清理 ${currentModelConfig.name} 的旧版本...");
    try {
      final baseDir = await _getModelsBaseDirectory();
      final modelTypeDir = Directory('${baseDir.path}/${currentModelConfig.name}');
      
      if (!await modelTypeDir.exists()) {
        // 如果该模型的根目录都不存在，说明没有旧版本
        return;
      }
      
      // 列出该模型下的所有版本目录
      final versions = modelTypeDir.list();
      await for (final FileSystemEntity entity in versions) {
        if (entity is Directory) {
          // 获取目录名，即版本号
          final versionName = entity.path.split(Platform.pathSeparator).last;
          
          // 如果版本名不是当前版本，就删除它
          if (versionName != currentModelConfig.version) {
            print("找到旧版本目录: ${entity.path}，正在删除...");
            await entity.delete(recursive: true);
          }
        }
      }
      print("旧版本清理完毕。");
    } catch (e) {
      // 清理失败不应该阻塞主流程，只打印错误
      print("清理旧版本时发生错误: $e");
    }
  }
}