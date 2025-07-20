import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter_frame/core/constants/app_constants.dart';

// 简化的下载状态
class DownloadProgress {
  final int received;
  final int total;
  DownloadProgress(this.received, this.total);
}

class Downloader {
  final _dio = Dio();

  /// 下载一个文件，支持断点续传，并返回进度流
  Stream<DownloadProgress> download(String url, String savePath) {
    final controller = StreamController<DownloadProgress>();
    _performDownload(controller, url, savePath);
    return controller.stream;
  }
  
  Future<void> _performDownload(StreamController<DownloadProgress> controller, String url, String savePath) async {
    int downloadedBytes = 0;
    final file = File(savePath);
    if (await file.exists()) {
      downloadedBytes = await file.length();
    }
    
    try {
      await _dio.download(
        url,
        savePath,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          if (total != -1 && !controller.isClosed) {
            controller.add(DownloadProgress(downloadedBytes + received, downloadedBytes + total));
          }
        },
        options: Options(headers: {
          AppConstants.headerRange: '${AppConstants.headerBytesPrefix}$downloadedBytes-'
        })
      );
      await controller.close();
    } catch(e) {
      controller.addError(e);
    }
  }

  /// 静态的解压方法
  static Future<void> unzip(File zipFile, Directory targetDir) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    extractArchiveToDisk(archive, targetDir.path);
  }
}