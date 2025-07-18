import 'dart:async';

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import 'asr_data_source.dart';

// 注意这里的类名，与 mobile 版本完全相同
class SherpaDataSourceImpl implements AsrDataSource {
  final _resultController = StreamController<AsrResult>.broadcast();

  @override
  Stream<AsrResult> get resultStream => _resultController.stream;

  @override
  Stream<PreparationStatus> prepare() async* {
    // 在Web上，Sherpa是不可用的，所以直接报告错误
    const message = "Sherpa 离线识别在 Web 平台不受支持。";
    yield const PreparationStatus(PreparationStep.error, message);
  }
  
  @override
  Future<void> start() async {
    // 不做任何事，因为 prepare 已经报告了错误
  }
  
  @override
  Future<void> stop() async {
    // 不做任何事
  }
  
  @override
  void dispose() {
    _resultController.close();
  }
}