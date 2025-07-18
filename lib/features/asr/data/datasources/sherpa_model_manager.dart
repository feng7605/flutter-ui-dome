import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sherpa_model_state.dart';

class SherpaModelManager extends StateNotifier<SherpaModelState> {
  SherpaModelManager() : super(const SherpaModelState());

  Completer<void>? _setupCompleter;

  Future<void> setupModels() async {
    if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
      return _setupCompleter!.future;
    }
    if (state.status == ModelStatus.ready) {
      return;
    }

    _setupCompleter = Completer<void>();

    try {
      // 第一次状态修改，此时一定是 mounted
      state = state.copyWith(status: ModelStatus.checking, message: "正在检查模型文件...");
      await Future.delayed(const Duration(milliseconds: 500));


      final bool modelsExist = await _checkIfModelsExist();
      if (modelsExist) {
        state = state.copyWith(status: ModelStatus.ready, message: "模型已就绪");
      } else {
        await _downloadModels();
        state = state.copyWith(status: ModelStatus.ready, message: "模型已就绪");
      }
      
      // 如果 completer 还没完成，就完成它
      if (!_setupCompleter!.isCompleted) {
        _setupCompleter!.complete();
      }

    } catch (e) {
      // **关键修复点 4**
      if (!mounted) return;
      state = state.copyWith(status: ModelStatus.error, message: "模型准备失败: $e");
      
      if (!_setupCompleter!.isCompleted) {
        _setupCompleter!.completeError(e);
      }
    }
  }

  Future<bool> _checkIfModelsExist() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 模拟IO
    return Random().nextBool();
  }

  Future<void> _downloadModels() async {
    // 第一次状态修改，此时一定是 mounted
    state = state.copyWith(status: ModelStatus.downloading, downloadProgress: 0.0);

    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      state = state.copyWith(downloadProgress: i / totalSteps);
    }
  }

  // StateNotifier 的 dispose 方法是自动调用的
  // 我们可以在这里确保 Completer 被处理
  @override
  void dispose() {
    if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
      _setupCompleter!.completeError(StateError('SherpaModelManager was disposed during setup.'));
    }
    super.dispose();
  }
}