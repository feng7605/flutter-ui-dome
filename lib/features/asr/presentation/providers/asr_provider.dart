// features/asr/presentation/providers/asr_providers.dart
import 'package:flutter_frame/core/bootstrap/module_bootstrapper.dart';
import 'package:flutter_frame/features/asr/data/datasources/sherpa_offline.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/data/services/asr_config_service.dart';
import 'package:flutter_frame/features/asr/domain/entities/asr_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/asr_base.dart';
import '../../data/datasources/iflytek_data_source.dart';
// 关键的 import: 导入存根文件，而不是任何一个具体实现
import '../../data/datasources/sherpa_data.dart';
import '../../data/repositories/asr_repository_impl.dart';
import '../../domain/repositories/asr_repository.dart';
import '../state/asr_screen_state.dart';
import '../viewmodels/asr_viewmodel.dart';

// 新增 ASR 模块的引导程序
final asrBootstrapProvider = Provider<ModuleBootstrap>((ref) {
  return (bootstrapRef) async {
    // 这个模块的初始化任务就是等待配置加载完成
    await bootstrapRef.read(asrConfigProvider.future);
  };
});

//语音识别配置
final asrConfigProvider = FutureProvider<AsrConfig>((ref) {
  final service = AsrConfigService();
  return service.loadFromAssets('assets/config/asr_config.json');
});

// 1. 供应商枚举
enum AsrVendor {
  sherpa('Sherpa Offline'),
  iflytek('iFlytek');
  
  const AsrVendor(this.displayName);
  final String displayName;
}

// 2. Provider: 管理用户当前选择的供应商
final selectedVendorProvider = StateProvider<AsrVendor>((ref) {
  // watch FutureProvider 的 .value，这会在数据准备好后返回数据，否则返回 null
  final config = ref.watch(asrConfigProvider).value;

  // 如果配置还没加载好，返回一个默认值
  if (config == null) {
    return AsrVendor.sherpa; // 或者任何你想要的启动时默认值
  }
  
  // 配置加载好后，使用配置中的默认值
  final defaultVendorName = config.defaultSupplier;
  return AsrVendor.values.firstWhere(
    (v) => v.name.toLowerCase() == defaultVendorName.toLowerCase(),
    orElse: () => AsrVendor.sherpa,
  );
});

// 3. Provider: 根据选择动态提供 AsrRepository
final asrRepositoryProvider = Provider.autoDispose<AsrRepository>((ref) {
  final vendor = ref.watch(selectedVendorProvider);
  
  // **关键**: 在这里 watch asrConfigProvider。
  // 这会建立一个依赖关系：当配置加载完成时，这个 Provider 会自动重建。
  final asyncConfig = ref.watch(asrConfigProvider);

  // **处理异步状态**: 只有当配置成功加载后，才创建 Repository
  return asyncConfig.when(
    data: (config) {
      // 配置加载成功，继续正常逻辑
      late final AsrDataSource dataSource;
      switch (vendor) {
        case AsrVendor.sherpa:
          final sherpaConfig = config.getSupplier('sherpa');
          dataSource = OfflineVadDataSource(config: sherpaConfig!, ref: ref);
          break;
        case AsrVendor.iflytek:
          final iflytekConfig = config.getSupplier('iflytek');
          dataSource = IflytekDataSource(config: iflytekConfig!);
          break;
      }
      ref.onDispose(() => dataSource.dispose());
      return AsrRepositoryImpl(dataSource);
    },
    // 在配置加载时或加载失败时，提供一个“空”的或“无效”的 Repository 实现
    loading: () => InactiveAsrRepository('配置加载中...'),
    error: (err, stack) => InactiveAsrRepository('ASR 配置加载失败: $err'),
  );
});


// 4. Provider: 提供 ViewModel
final asrViewModelProvider = 
  StateNotifierProvider.autoDispose<AsrViewModel, AsrScreenState>((ref) {
    final repository = ref.watch(asrRepositoryProvider);
    final config = ref.watch(asrConfigProvider).value;
    final initialMode = config?.suppliers.first.modes.first.type;
    final initialModel = config?.suppliers.first.modes.first.models.first.id;
    final viewModel = AsrViewModel(repository, initialMode: initialMode, initialModel: initialModel);
    
    //viewModel.checkStatus();

    //ref.onDispose(() => viewModel.dispose());

    return viewModel;
});


// 4. 新增一个“无效”的 Repository 实现，用于加载和错误状态
class InactiveAsrRepository implements AsrRepository {
  final String _message;
  InactiveAsrRepository(this._message);

  @override
  Stream<PreparationStatus> prepare(String modelId) => Stream.value(PreparationStatus(PreparationStep.error, _message));
  @override
  Stream<AsrResult> startStreamingRecognition() => Stream.error(StateError(_message));
  @override
  Future<void> stopStreamingRecognition() async {}
  @override
  void dispose() {}
  
  @override
  Future<bool> isReady(String modelId) {
    return Future.value(true);
  }
  
  @override
  Future<AsrResult> recognizeOnce() {
    // TODO: implement recognizeOnce
    throw UnimplementedError();
  }
}