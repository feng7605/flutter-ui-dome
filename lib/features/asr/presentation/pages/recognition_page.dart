import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/sherpa_model_state.dart';
import '../providers/recognition_provider.dart';
import '../viewmodels/recognition_viewmodel.dart';
import '../widgets/speech_button.dart';

class SpeechRecognitionPage extends ConsumerWidget {
  const SpeechRecognitionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取完整的 ViewModel 状态对象
    final vmState = ref.watch(speechRecognitionViewModelProvider);
    final viewModel = ref.read(speechRecognitionViewModelProvider.notifier);
    final selectedVendor = ref.watch(selectedVendorProvider);

    final sherpaModelState = (selectedVendor == SpeechVendor.sherpa)
        ? ref.watch(sherpaModelManagerProvider)
        : null;

    // isBusy 用于显示加载指示器并禁用按钮，它优先于 isRecognizing
    // 当模型在准备，或者识别结果在加载（但还没进入正在识别状态时），都算繁忙
    final bool isBusy = sherpaModelState?.status == ModelStatus.checking ||
                        sherpaModelState?.status == ModelStatus.downloading ||
                        (vmState.result.isLoading && !vmState.isRecognizing);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).canvasColor,
            child:DropdownButton<SpeechVendor>(
                value: selectedVendor,
                isExpanded: true,
                items: SpeechVendor.values
                    .map((vendor) => DropdownMenuItem(
                          value: vendor,
                          child: Text(vendor.displayName),
                        ))
                    .toList(),
                // 当正在识别或繁忙时，禁止切换供应商
                onChanged: (vmState.isRecognizing || isBusy) ? null : (vendor) {
                  if (vendor != null) {
                    ref.read(selectedVendorProvider.notifier).state = vendor;
                  }
                },
              )
            ),
            const SizedBox(height: 40),

              // **核心修复点：**
              // 将 vmState.result 传递给 _buildStatusWidget，而不是不存在的 recognitionState
              Expanded(
                child: _buildStatusWidget(context, vmState.result, sherpaModelState),
              ),

              const SizedBox(height: 40),
              
              SpeechButton(
                onPressed: isBusy ? null : () => viewModel.recognize(),
                isRecognizing: vmState.isRecognizing,
                isLoading: isBusy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 抽离出一个方法来处理复杂的UI状态显示，保持 build 方法整洁
  /// 这个方法内部不需要任何改动，因为它本来就期望接收 AsyncValue<String>
  Widget _buildStatusWidget(
    BuildContext context,
    AsyncValue<String> recognitionResult,
    SherpaModelState? sherpaModelState,
  ) {
    // 优先显示 Sherpa 模型的准备状态
    if (sherpaModelState != null) {
      switch (sherpaModelState.status) {
        case ModelStatus.checking:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(sherpaModelState.message ?? "正在检查模型...")
            ],
          );
        case ModelStatus.downloading:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(value: sherpaModelState.downloadProgress),
              const SizedBox(height: 16),
              Text('正在下载模型... ${(sherpaModelState.downloadProgress! * 100).toStringAsFixed(0)}%'),
            ],
          );
        case ModelStatus.error:
          return Center(
            child: Text(
              "模型错误: ${sherpaModelState.message}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        case ModelStatus.ready:
        case ModelStatus.initial:
          // 如果模型已就绪或在初始状态，则交由识别状态来处理UI
          break;
      }
    }

    // 如果模型状态正常，则显示识别结果状态
    return recognitionResult.when(
      data: (text) {
        final displayText = text.isEmpty ? "点击按钮开始识别" : text;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
            ),
          ),
        );
      },
      loading: () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("准备中...")
        ],
      ),
      error: (e, _) => Center(
        child: Text(
          "出错: $e",
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}