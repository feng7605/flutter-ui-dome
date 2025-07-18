import 'dart:async';
import '../../domain/entities/asr_result.dart';
import '../../domain/repositories/asr_repository.dart';
import '../datasources/asr_data_source.dart';

class AsrRepositoryImpl implements AsrRepository {
  final AsrDataSource _dataSource;
  
  AsrRepositoryImpl(this._dataSource);
    
  @override
  Stream<PreparationStatus> prepare(String modelId) {
    return _dataSource.prepare(modelId);
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
  
  @override
  Future<bool> isReady(String modelId) {
    return _dataSource.isReady(modelId);
  }

  @override
  Future<AsrResult> recognizeOnce() {
    return _dataSource.recognizeOnce();
  }
}