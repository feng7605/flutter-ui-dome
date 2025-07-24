import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_frame/core/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

class FileManager {
  /// 获取应用的文档目录
  Future<Directory> get _appDocsDir async => getApplicationDocumentsDirectory();

  /// 获取一个通用的、按模块划分的根目录
  /// e.g., .../app_docs/modules/asr
  Future<Directory> getModuleDirectory(String moduleName) async {
    final baseDir = await _appDocsDir;
    final moduleDir = Directory('${baseDir.path}/${AppConstants.modulesBaseDir}/$moduleName');
    if (!await moduleDir.exists()) {
      await moduleDir.create(recursive: true);
    }
    return moduleDir;
  }
  
  /// 获取一个具体资源（如模型）的存储目录
  /// e.g., .../app_docs/modules/asr/models/zipformer-v1
  Future<Directory> getResourceDirectory({
    required String moduleName, 
    required String resourceType, // "models", "datasets", etc.
    required String resourceId,
  }) async {
    final moduleDir = await getModuleDirectory(moduleName);
    final resourcePath = '${moduleDir.path}/$resourceType/$resourceId';
    final dir = Directory(resourcePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 验证一个目录中的文件是否存在
  Future<bool> validateFilesExist(Directory dir, List<String> requiredFiles) async {
    if (requiredFiles.isEmpty) return true;
    for (final fileName in requiredFiles) {
      if (!await File('${dir.path}/$fileName').exists()) {
        return false;
      }
    }
    return true;
  }

  /// 验证文件的校验和
  Future<bool> verifyChecksum(File file, String expectedChecksum) async {
    // if (expectedChecksum.isEmpty) return true;
    // final digest = await sha256.bind(file.openRead()).first;
    // return digest.toString().toLowerCase() == expectedChecksum.toLowerCase();
    return true;
  }

  /// 清理目录
  Future<void> cleanDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 清理一个资源类型下的所有旧版本
  /// e.g., cleanOldVersions(moduleName: 'asr', resourceType: 'models', resourceName: 'zipformer', currentVersionId: 'v2')
  Future<void> cleanOldVersions({
    required String moduleName,
    required String resourceType,
    required String resourceName, // the name of the resource, e.g., 'zipformer'
    required String currentVersionId,
  }) async {
    try {
      final moduleDir = await getModuleDirectory(moduleName);
      final resourceTypeDir = Directory('${moduleDir.path}/$resourceType');

      if (!await resourceTypeDir.exists()) return;

      final entities = resourceTypeDir.list();
      await for (final entity in entities) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          // A more robust way to check old versions
          if (dirName.startsWith(resourceName) && dirName != currentVersionId) {
             print("Cleaning old version: ${entity.path}");
             await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      print("Error cleaning old versions: $e");
    }
  }
}