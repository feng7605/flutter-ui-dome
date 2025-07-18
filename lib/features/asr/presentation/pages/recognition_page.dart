import 'package:flutter/material.dart';
import 'package:flutter_frame/features/asr/presentation/state/asr_screen_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asr_provider.dart';
import '../widgets/speech_button.dart';

class SpeechRecognitionPage extends ConsumerWidget {
  const SpeechRecognitionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听 ViewModel 的状态，这是 UI 唯一需要的数据源
    
    final uiState = ref.watch(asrViewModelProvider);
    final viewModel = ref.read(asrViewModelProvider.notifier);
    
    final selectedVendor = ref.watch(selectedVendorProvider);

    // 2. 按钮是否可用的逻辑被大大简化
    final bool isActionInProgress = 
        uiState.status == AsrStatus.preparing || 
        uiState.status == AsrStatus.recognizing;

    return Scaffold(
      appBar: AppBar(title: const Text("语音识别")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3. 下拉菜单逻辑简化
              DropdownButton<AsrVendor>(
                value: selectedVendor,
                isExpanded: true,
                items: AsrVendor.values
                    .map((vendor) => DropdownMenuItem(
                          value: vendor,
                          child: Text(vendor.displayName),
                        ))
                    .toList(),
                onChanged: isActionInProgress ? null : (vendor) {
                  if (vendor != null) {
                    ref.read(selectedVendorProvider.notifier).state = vendor;
                  }
                },
              ),
              const SizedBox(height: 40),

              // 4. 状态显示区域现在只依赖一个 uiState 对象
              Expanded(
                child: _buildStatusWidget(context, uiState),
              ),

              const SizedBox(height: 40),
              
              // 5. 按钮逻辑简化
              SpeechButton(
                onPressed: (uiState.status == AsrStatus.ready || uiState.status == AsrStatus.recognizing) 
                           ? () => viewModel.toggleRecognition()
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

  // 6. 状态显示 Widget 逻辑变得清晰，因为它只处理 AsrScreenState
  Widget _buildStatusWidget(BuildContext context, AsrScreenState uiState) {
    final textTheme = Theme.of(context).textTheme;

    switch (uiState.status) {
      case AsrStatus.initial:
      case AsrStatus.preparing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (uiState.preparationProgress == null)
              const CircularProgressIndicator()
            else
              LinearProgressIndicator(value: uiState.preparationProgress),
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
          child: Text(
            uiState.recognizedText.isEmpty ? "请说话..." : uiState.recognizedText,
            style: textTheme.titleLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
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