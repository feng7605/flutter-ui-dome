import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/repositories/asr_repository.dart';
import '../models/asr_config.dart'; // 引入 ModelConfig 以便使用 checksum

class ModelDownloader {
  final _dio = Dio();
  
  /// 下载并解压模型，返回一个包含详细进度的流
  Stream<PreparationStatus> downloadAndUnzip(
    ModelConfig modelConfig, // 传入完整的模型配置
    Directory targetDir,
  ) {
    final controller = StreamController<PreparationStatus>();
    _download(controller, modelConfig, targetDir);
    return controller.stream;
  }

  Future<void> _download(
    StreamController<PreparationStatus> controller,
    ModelConfig modelConfig,
    Directory targetDir,
  ) async {
    final zipFileName = modelConfig.downloadUrl.split('/').last;
    final zipFile = File('${targetDir.path}/$zipFileName');

    try {
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // --- 1. 获取文件总大小和检查已下载部分 ---
      controller.add(const PreparationStatus(PreparationStep.checking, "连接服务器..."));
      final totalSize = await _getTotalFileSize(modelConfig.downloadUrl);
      if (totalSize <= 0) {
        throw Exception("无法获取文件大小或文件为空");
      }
      
      int downloadedBytes = 0;
      if (await zipFile.exists()) {
        downloadedBytes = await zipFile.length();
        // 如果文件已完整下载，但未解压，先进行校验
        if (downloadedBytes == totalSize) {
          controller.add(const PreparationStatus(PreparationStep.checking, "文件已存在，正在校验..."));
          final isValid = await _verifyChecksum(zipFile, modelConfig.checksum);
          if (isValid) {
            // 如果文件有效，直接进入解压步骤
            await _unzip(zipFile, targetDir, controller);
            await controller.close();
            return;
          } else {
            // 校验失败，删除文件重新下载
            print("校验和不匹配，删除文件并重新下载...");
            await zipFile.delete();
            downloadedBytes = 0;
          }
        } else if (downloadedBytes > totalSize) {
            // 本地文件比服务器文件还大，肯定是坏的
            await zipFile.delete();
            downloadedBytes = 0;
        }
      }
      
      // --- 2. 执行断点续传下载 ---
      controller.add(PreparationStatus(PreparationStep.downloading, "开始下载...", progress: downloadedBytes / totalSize));
      
      final options = Options(headers: {'Range': 'bytes=$downloadedBytes-'});

      await _dio.download(
        modelConfig.downloadUrl,
        zipFile.path,
        options: options,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
           if (!controller.isClosed) {
            // 使用我们预先获取的 totalSize 进行精确计算
            final currentProgress = (downloadedBytes + received) / totalSize;
            controller.add(PreparationStatus(PreparationStep.downloading, "下载中...", progress: currentProgress));
           }
        },
      );
      
      if (controller.isClosed) return;

      // --- 3. 下载后校验和解压 ---
      controller.add(const PreparationStatus(PreparationStep.checking, "下载完成，正在校验..."));
      final isValid = await _verifyChecksum(zipFile, modelConfig.checksum);
      if (!isValid) {
        throw Exception("下载的文件校验和不匹配，文件可能已损坏。");
      }

      await _unzip(zipFile, targetDir, controller);
      await controller.close();

    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
      // 出错时不删除文件，以便下次续传
    }
  }

  /// 辅助方法：通过 HEAD 请求获取文件总大小
  Future<int> _getTotalFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final size = int.parse(response.headers.value(Headers.contentLengthHeader) ?? '0');
      return size;
    } catch (e) {
      print("获取文件大小失败: $e");
      return -1;
    }
  }

  /// 辅助方法：验证文件的 SHA256 校验和
  Future<bool> _verifyChecksum(File file, String expectedChecksum) async {
    if (expectedChecksum.isEmpty || expectedChecksum == "1") {
      print("Warning: 未提供有效的校验和，跳过验证。");
      return true; // 如果没有提供 checksum，则认为有效
    }
    final digest = await sha256.bind(file.openRead()).first;
    final calculatedChecksum = digest.toString();
    print("计算出的校验和: $calculatedChecksum");
    print("期望的校验和: $expectedChecksum");

    return calculatedChecksum.toLowerCase() == expectedChecksum.toLowerCase();
  }

  /// 辅助方法：解压文件
  Future<void> _unzip(File zipFile, Directory targetDir, StreamController<PreparationStatus> controller) async {
    if (controller.isClosed) return;
    controller.add(const PreparationStatus(PreparationStep.downloading, "正在解压...", progress: 1.0));
    
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, targetDir.path);
      
      // 解压成功后，可以安全地删除 zip 文件以节省空间
      await zipFile.delete();

    } catch(e) {
      throw Exception("解压文件失败: $e");
    }
  }

  
}