// features/asr/presentation/providers/asr_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/asr_data_source.dart';
import '../../data/datasources/iflytek_data_source.dart';
// 关键的 import: 导入存根文件，而不是任何一个具体实现
import '../../data/datasources/sherpa_data_source.dart';
import '../../data/repositories/asr_repository_impl.dart';
import '../../domain/repositories/asr_repository.dart';
import '../state/asr_screen_state.dart';
import '../viewmodels/asr_viewmodel.dart';


// 1. 供应商枚举
enum AsrVendor {
  sherpa('Sherpa Offline'),
  iflytek('iFlytek');
  
  const AsrVendor(this.displayName);
  final String displayName;
}

// 2. Provider: 管理用户当前选择的供应商
final selectedVendorProvider = StateProvider<AsrVendor>((ref) => AsrVendor.sherpa);

// 3. Provider: 根据选择动态提供 AsrRepository
final asrRepositoryProvider = Provider.autoDispose<AsrRepository>((ref) {
  final vendor = ref.watch(selectedVendorProvider);
  
  late final AsrDataSource dataSource;
  
  switch (vendor) {
    case AsrVendor.sherpa:
      // 现在这行代码是安全的。编译器会根据平台选择正确的 SherpaDataSourceImpl
      dataSource = SherpaDataSourceImpl();
      break;
    case AsrVendor.iflytek:
      dataSource = IflytekDataSource();
      break;
  }

  ref.onDispose(() => dataSource.dispose());
  return AsrRepositoryImpl(dataSource);
});


// 4. Provider: 提供 ViewModel
final asrViewModelProvider = 
  StateNotifierProvider.autoDispose<AsrViewModel, AsrScreenState>((ref) {
    final repository = ref.watch(asrRepositoryProvider);
    final viewModel = AsrViewModel(repository);
    
    viewModel.prepare();

    //ref.onDispose(() => viewModel.dispose());

    return viewModel;
});