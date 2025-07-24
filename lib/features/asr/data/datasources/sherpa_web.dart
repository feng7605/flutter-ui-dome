import 'dart:async';

import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import 'asr_base.dart';

// 注意这里的类名，与 mobile 版本完全相同
class SherpaDataSourceImpl extends BaseSherpaDataSource {

  SherpaDataSourceImpl({required super.config, required super.ref});
  
  @override
  Stream<PreparationStatus> prepare(String modelId) {
    // TODO: implement prepare
    throw UnimplementedError();
  }
  
  @override
  Future<void> start() {
    // TODO: implement start
    throw UnimplementedError();
  }

 
}