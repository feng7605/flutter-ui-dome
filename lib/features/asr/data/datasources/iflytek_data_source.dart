import 'dart:async';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import 'asr_base.dart';

class IflytekDataSource implements AsrDataSource {
  final SupplierConfig config;
  IflytekDataSource({required this.config});
  final _resultController = StreamController<AsrResult>.broadcast();

  @override
  Future<bool> isReady(String modelId) async {
    return true;
  }

  @override
  Stream<AsrResult> get resultStream => _resultController.stream;

  @override
  Stream<PreparationStatus> prepare(String modelId) async* {
    // 讯飞可能不需要准备，直接返回 ready
    yield const PreparationStatus(PreparationStep.ready, "讯飞识别已就绪");
  }

  @override
  Future<void> start() async {
    // 模拟一次性识别
    await Future.delayed(const Duration(seconds: 2));
    _resultController.add(const AsrResult(text: "你好，世界（来自讯飞）", isFinal: true));
  }
  
  @override
  Future<void> stop() async {
    // 一次性识别，stop 无操作
  }
  
  @override
  void dispose() {
    _resultController.close();
  }
  
  @override
  Future<AsrResult> recognizeOnce() {
    // TODO: implement recognizeOnce
    throw UnimplementedError();
  }
}