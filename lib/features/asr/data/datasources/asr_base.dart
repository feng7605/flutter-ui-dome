import 'dart:async';
import 'package:flutter_frame/core/constants/app_constants.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_frame/core/services/audio/audio_source.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';

abstract class AsrDataSource {

  Future<bool> isReady(String modelId);

  /// 准备数据源所需资源（如模型），并报告进度
  Stream<PreparationStatus> prepare(String modelId);

  /// 开始识别
  Future<void> start();
  
  /// 停止识别
  Future<void> stop();
  
  /// 识别结果流
  Stream<AsrResult> get resultStream;
  
  /// 释放资源
  void dispose();

  /// 识别一次
  Future<AsrResult> recognizeOnce();
}

abstract class BaseSherpaDataSource implements AsrDataSource {
  final Ref ref;
  final SupplierConfig config; // 所有 Sherpa 源都需要供应商配置

  // 共享的属性
  AudioSource? audioSource;
  StreamSubscription? audioSubscription;
  final resultController = StreamController<AsrResult>.broadcast();

  BaseSherpaDataSource({required this.config, required this.ref});

  @override
  Stream<AsrResult> get resultStream => resultController.stream;

  // **共享的实现**: isModelReady
  @override
  Future<bool> isReady(String modelId) async {
    final modelConfig = findModelConfigById(modelId);
    if (modelConfig == null) return false;

    final fileManager = ref.read(fileManagerProvider);
    final modelDir = await fileManager.getResourceDirectory(
      moduleName: AppConstants.moduleAsr,
      resourceType: AppConstants.resourceTypeModels,
      resourceId: modelConfig.id,
    );
    return await fileManager.validateFilesExist(modelDir, modelConfig.files);
  }
  
  @override
  Future<void> stop() async {
    await audioSubscription?.cancel();
    audioSubscription = null;
    await audioSource?.stop();
  }

  // **共享的实现**: dispose
  @override
  void dispose() {
    audioSubscription?.cancel();
    audioSource?.dispose();
    resultController.close();
  }

  @override
  Future<AsrResult> recognizeOnce() async{
    return AsrResult(text: "");
  }

  // **共享的帮助方法**: findModelConfigById
  ModelConfig? findModelConfigById(String modelId) {
    for (final mode in config.modes) {
      for (final model in mode.models) {
        if (model.id == modelId) {
          return model;
        }
      }
    }
    return null;
  }

  // 子类必须实现的抽象方法
  @override
  Stream<PreparationStatus> prepare(String modelId);

  @override
  Future<void> start();
}