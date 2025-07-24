import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/services/download/downloader.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/domain/repositories/asr_repository.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig() async {
  const modelDir ='assets/res/onnx';
  return sherpa_onnx.OnlineModelConfig(
    transducer: sherpa_onnx.OnlineTransducerModelConfig(
      // encoder: await copyAssetFile('$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
      // decoder: await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
      // joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
      // encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx'),
      // decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-4-chunk-16-left-128.onnx'),
      // joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'),
      encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-2-chunk-16-left-256.int8.onnx'),
      decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-2-chunk-16-left-256.onnx'),
      joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-2-chunk-16-left-256.onnx'),
    ),
    tokens: await copyAssetFile('$modelDir/tokens.txt'),
    modelType: 'zipformer2',
  );
}

Future<String> copyAssetFile(String src, [String? dst]) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  if (dst == null) {
    dst = basename(src);
  }
  final target = join(directory.path, dst);
  bool exists = await new File(target).exists();

  final data = await rootBundle.load(src);

  if (!exists || File(target).lengthSync() != data.lengthInBytes) {
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(target).writeAsBytes(bytes);
  }

  return target;
}

Stream<PreparationStatus> downloadAndValidateModel(Directory modelDir, ModelConfig modelConfig, ref) async* {
    final fileManager = ref.read(fileManagerProvider);
    final downloader = ref.read(downloaderProvider);

    final zipFile = File('${modelDir.path}/${modelConfig.downloadUrl.split('/').last}');
      
    // 监听下载流
    yield const PreparationStatus(PreparationStep.downloading, "开始下载...", progress: 0.0);
    await for (final progress in downloader.download(modelConfig.downloadUrl, zipFile.path)) {
      yield PreparationStatus(PreparationStep.downloading, "下载中...", progress: progress.received / progress.total);
    }
    
    // 校验
    yield const PreparationStatus(PreparationStep.checking, "校验文件...");
    if (!await fileManager.verifyChecksum(zipFile, modelConfig.checksum)) {
      throw Exception("文件校验失败");
    }
    
    // 解压
    yield const PreparationStatus(PreparationStep.checking, "解压中...");
    await Downloader.unzip(zipFile, modelDir);
    await zipFile.delete();
    
    // 再次验证解压后的文件
    if (!await fileManager.validateFilesExist(modelDir, modelConfig.files)) {
      throw Exception("解压后的文件不完整");
    }
  }