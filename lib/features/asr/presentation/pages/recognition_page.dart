import 'package:flutter/material.dart';
import 'package:flutter_frame/features/asr/data/models/asr_config.dart';
import 'package:flutter_frame/features/asr/presentation/viewmodels/asr_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asr_provider.dart';
import '../state/asr_screen_state.dart';
import '../widgets/speech_button.dart';

class SpeechRecognitionPage extends ConsumerStatefulWidget {
  const SpeechRecognitionPage({super.key});

  @override
  ConsumerState<SpeechRecognitionPage> createState() => _SpeechRecognitionPageState();
}

class _SpeechRecognitionPageState extends ConsumerState<SpeechRecognitionPage> {
  // 注意：这个页面现在是 StatefulWidget，但我们没有使用 initState，
  // 因为所有初始化逻辑都在 ViewModel 的构造函数中。
  // 如果未来有需要，这个结构是方便扩展的。

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(asrViewModelProvider);
    final viewModel = ref.read(asrViewModelProvider.notifier);
    
    // 从配置中获取动态数据
    final configAsyncValue = ref.watch(asrConfigProvider);
    final selectedVendor = ref.watch(selectedVendorProvider);
    
    // 使用 .when 处理配置加载状态，确保 config 不为 null
    return Scaffold(
      appBar: AppBar(title: const Text("语音识别配置")),
      body: configAsyncValue.when(
        data: (config) {
          final supplierConfig = config.getSupplier(selectedVendor.name);
          return _buildMainContent(context, uiState, viewModel, supplierConfig, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, stack) => Center(child: Text("加载配置文件失败: $err")),
      ),
    );
  }
  
  // 主内容构建方法
  Widget _buildMainContent(
    BuildContext context, 
    AsrScreenState uiState, 
    AsrViewModel viewModel,
    SupplierConfig? supplierConfig,
    WidgetRef ref,
  ) {
    // 判断是否有任何后台操作正在进行，用于禁用UI
    final bool isBusy = uiState.status == AsrStatus.recognizing ||
                        uiState.status == AsrStatus.downloading ||
                        uiState.status == AsrStatus.checking;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 1. 供应商选择
          DropdownButtonFormField<AsrVendor>(
            value: ref.watch(selectedVendorProvider),
            decoration: const InputDecoration(
              labelText: '供应商',
              border: OutlineInputBorder(),
            ),
            items: AsrVendor.values
                .map((vendor) => DropdownMenuItem(
                      value: vendor,
                      child: Text(vendor.displayName),
                    ))
                .toList(),
            onChanged: isBusy ? null : (vendor) {
              if (vendor != null) {
                ref.read(selectedVendorProvider.notifier).state = vendor;
              }
            },
          ),
          const SizedBox(height: 16),
          
          // 2. 识别模式选择
          if (supplierConfig != null)
            DropdownButtonFormField<String>(
              value: uiState.selectedModeType,
              decoration: const InputDecoration(
                labelText: '识别模式',
                border: OutlineInputBorder(),
              ),
              hint: const Text("选择模式"),
              items: supplierConfig.modes
                  .map((mode) => DropdownMenuItem(
                        value: mode.type,
                        child: Text(mode.label),
                      ))
                  .toList(),
              onChanged: isBusy ? null : (modeType) {
                if (modeType != null) {
                  viewModel.selectMode(modeType);
                }
              },
            ),

          const SizedBox(height: 16),
          
          // 3. 模型选择 (联动)
          if (uiState.selectedModeType != null)
            DropdownButtonFormField<String>(
              value: uiState.selectedModelId,
              decoration: const InputDecoration(
                labelText: '模型',
                border: OutlineInputBorder(),
              ),
              hint: const Text("选择模型"),
              items: supplierConfig
                      ?.getMode(uiState.selectedModeType!)
                      ?.models
                      .map((model) => DropdownMenuItem(
                            value: model.id,
                            child: Text(model.name),
                          ))
                      .toList() ??
                  [],
              onChanged: isBusy ? null : (modelId) {
                if (modelId != null) {
                  viewModel.selectModel(modelId);
                }
              },
            ),

          // 4. 状态显示和操作区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: _buildStatusView(context, uiState, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据 ViewModel 的聚合状态，构建不同的UI视图
  Widget _buildStatusView(BuildContext context, AsrScreenState uiState, AsrViewModel viewModel) {
    switch (uiState.status) {
      case AsrStatus.initial:
      case AsrStatus.checking:
        return const Center(child: CircularProgressIndicator());

      case AsrStatus.requiresDownload:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_for_offline_outlined, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 24),
            Text(uiState.message ?? '当前模型未下载', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('下载并准备模型'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: viewModel.prepareAndLoad,
            ),
          ],
        );

      case AsrStatus.downloading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: uiState.downloadProgress, minHeight: 8),
            const SizedBox(height: 16),
            Text(uiState.message ?? '下载中...', style: Theme.of(context).textTheme.titleSmall),
            if (uiState.downloadProgress != null)
              Text('${(uiState.downloadProgress! * 100).toStringAsFixed(0)} %'),
          ],
        );
      
      case AsrStatus.ready:
      case AsrStatus.recognizing:
        return _buildInteractionView(context, uiState, viewModel);
        
      case AsrStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("发生错误:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
              Text(uiState.message ?? "未知错误", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: viewModel.checkStatus, // 提供一个重试/检查的按钮
                child: const Text('重试检查'),
              )
            ],
          ),
        );
    }
  }

  /// 当模型就绪或正在识别时，构建交互视图
  Widget _buildInteractionView(BuildContext context, AsrScreenState uiState, AsrViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                _getDisplayText(uiState),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        _getActionButton(uiState, viewModel),
      ],
    );
  }

  /// 根据状态获取显示的文本
  String _getDisplayText(AsrScreenState uiState) {
    if (uiState.status == AsrStatus.ready) {
      return uiState.recognizedText.isEmpty 
        ? "准备就绪，点击开始" 
        : "上次结果: ${uiState.recognizedText}";
    }
    if (uiState.status == AsrStatus.recognizing) {
      return uiState.recognizedText.isEmpty ? "请说话..." : uiState.recognizedText;
    }
    return '';
  }

  /// 根据选择的模式，获取对应的操作按钮
  Widget _getActionButton(AsrScreenState uiState, AsrViewModel viewModel) {
    if (uiState.selectedModeType == 'streaming') {
      return SpeechButton(
        onPressed: viewModel.toggleRecognition,
        isRecognizing: uiState.status == AsrStatus.recognizing,
      );
    }
    if (uiState.selectedModeType == 'once') {
      return Column(
        children: [
          FloatingActionButton.large(
            heroTag: 'once_button',
            onPressed: uiState.status == AsrStatus.ready ? viewModel.recognizeOnce : null,
            child: uiState.status == AsrStatus.recognizing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.mic_none),
          ),
          const SizedBox(height: 8),
          const Text("点击说一句话"),
        ],
      );
    }
    // 如果没有选择模式，则不显示按钮
    return const SizedBox.shrink();
  }
}