import 'dart:async';
import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../datasources/asr_data_source.dart';

class AsrRepositoryImpl implements AsrRepository {
  final AsrDataSource _dataSource;
  
  AsrRepositoryImpl(this._dataSource);

  @override
  Stream<PreparationStatus> prepare() {
    return _dataSource.prepare();
  }

  @override
  Stream<AsrResult> startStreamingRecognition() {
    _dataSource.start();
    return _dataSource.resultStream;
  }

  @override
  Future<void> stopStreamingRecognition() {
    return _dataSource.stop();
  }

  @override
  void dispose() {
    _dataSource.dispose();
  }
}