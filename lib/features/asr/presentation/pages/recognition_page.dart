import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // 在 Widget 生命周期的早期，安全地触发一次性的准备操作。
    // 这不会阻塞 build 方法，让 UI 可以立即渲染出加载状态。
    // 使用 ref.read 是安全的，因为我们不关心后续变化，只想触发动作。
    ref.read(asrViewModelProvider.notifier).prepare();
  }

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

              // 2. 状态显示区域
              Expanded(
                child: _buildStatusWidget(context, uiState),
              ),

              const SizedBox(height: 40),
              
              // 3. 语音按钮
              SpeechButton(
                onPressed: (uiState.status == AsrStatus.ready || uiState.status == AsrStatus.recognizing) 
                           ? viewModel.toggleRecognition
                           : null,
                isRecognizing: uiState.status == AsrStatus.recognizing,
                isLoading: uiState.status == AsrStatus.preparing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 状态显示 Widget，逻辑现在非常统一
  Widget _buildStatusWidget(BuildContext context, AsrScreenState uiState) {
    final textTheme = Theme.of(context).textTheme;

    switch (uiState.status) {
      case AsrStatus.initial:
      case AsrStatus.preparing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (uiState.preparationProgress != null)
              LinearProgressIndicator(value: uiState.preparationProgress)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(uiState.message ?? "初始化..."),
          ],
        );

      case AsrStatus.ready:
        return Center(
          child: Text(
            uiState.message ?? "准备就绪，点击开始",
            style: textTheme.titleLarge,
          ),
        );

      case AsrStatus.recognizing:
        return Center(
          child: SingleChildScrollView(
            child: Text(
              uiState.recognizedText.isEmpty ? "请说话..." : uiState.recognizedText,
              style: textTheme.titleLarge?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case AsrStatus.error:
        return Center(
          child: Text(
            "错误: ${uiState.message}",
            style: textTheme.titleLarge?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
    }
  }
}