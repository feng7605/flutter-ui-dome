import 'package:flutter/material.dart';
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

  // @override
  // void initState() {
  //   super.initState();
  //   // 在 Widget 生命周期的早期，安全地触发一次性的准备操作。
  //   // 这不会阻塞 build 方法，让 UI 可以立即渲染出加载状态。
  //   // 使用 ref.read 是安全的，因为我们不关心后续变化，只想触发动作。
  //   ref.read(asrViewModelProvider.notifier).prepare();
  // }

  @override
  Widget build(BuildContext context) {
    // 现在，我们只 watch ViewModel 的状态，它会驱动所有UI变化
    final uiState = ref.watch(asrViewModelProvider);
    final viewModel = ref.read(asrViewModelProvider.notifier);
    final selectedVendor = ref.watch(selectedVendorProvider);
    
    // 根据聚合后的 uiState 来构建 UI
    return Scaffold(
      appBar: AppBar(title: const Text("语音识别")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 下拉菜单
              DropdownButton<AsrVendor>(
                value: selectedVendor,
                isExpanded: true,
                items: AsrVendor.values
                    .map((vendor) => DropdownMenuItem(
                          value: vendor,
                          child: Text(vendor.displayName),
                        ))
                    .toList(),
                // 只有在非识别状态下才能切换
                onChanged: uiState.status != AsrStatus.recognizing ? (vendor) {
                  if (vendor != null) {
                    ref.read(selectedVendorProvider.notifier).state = vendor;
                  }
                } : null,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _buildStatusView(context, uiState, viewModel),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 状态显示 Widget，逻辑现在非常统一
  Widget _buildStatusView(BuildContext context, AsrScreenState uiState, AsrViewModel viewModel) {
    switch (uiState.status) {
      case AsrStatus.initial:
      case AsrStatus.checking:
        return const Center(child: CircularProgressIndicator());

      case AsrStatus.requiresDownload:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_for_offline, size: 60, color: Colors.blue),
            const SizedBox(height: 24),
            Text(uiState.message ?? '需要下载模型文件', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('下载模型'),
              onPressed: viewModel.prepareAndLoad,
            ),
          ],
        );

      case AsrStatus.downloading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: uiState.downloadProgress),
            const SizedBox(height: 16),
            Text(uiState.message ?? '下载中...'),
          ],
        );
      
      case AsrStatus.ready:
      case AsrStatus.recognizing:
        // 当准备好或正在识别时，显示主交互UI
        return Column(
          children: [
            Expanded(child: _buildRecognitionResultView(context, uiState)),
            const SizedBox(height: 40),
            SpeechButton(
              onPressed: viewModel.toggleRecognition,
              isRecognizing: uiState.status == AsrStatus.recognizing,
            ),
          ],
        );
        
      case AsrStatus.error:
        return Center(
          child: Text("错误: ${uiState.message}", style: const TextStyle(color: Colors.red)),
        );
    }
  }
  Widget _buildRecognitionResultView(BuildContext context, AsrScreenState uiState) {
    if (uiState.status == AsrStatus.ready) {
      return Center(child: Text("准备就绪，点击开始", style: Theme.of(context).textTheme.titleLarge));
    }
    return Center(
      child: Text(
        uiState.recognizedText.isEmpty ? "请说话..." : uiState.recognizedText,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }
}