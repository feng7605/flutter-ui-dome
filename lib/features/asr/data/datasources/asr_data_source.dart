import 'dart:async';
import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';

abstract class AsrDataSource {
  /// 准备数据源所需资源（如模型），并报告进度
  Stream<PreparationStatus> prepare();

  /// 开始识别
  Future<void> start();
  
  /// 停止识别
  Future<void> stop();
  
  /// 识别结果流
  Stream<AsrResult> get resultStream;
  
  /// 释放资源
  void dispose();
}