import 'package:flutter/material.dart';
import 'package:flutter_frame/core/di/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_frame/presentation/providers/vad_providers.dart';
import 'package:flutter_frame/presentation/viewmodels/vad_viewmodel.dart';

class VadPage extends ConsumerWidget {
  const VadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **核心修改**: 监听 vadAudioSourceProvider 来处理初始化过程
    final vadSourceAsyncValue = ref.watch(vadSourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("VAD 功能测试"),
      ),
      // **核心修改**: 使用 .when 来构建不同的 UI
      body: vadSourceAsyncValue.when(
        // 1. 成功加载后，显示主界面
        data: (vadSource) => const VadDetectionView(),
        // 2. 加载中，显示一个加载指示器
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("正在初始化 VAD 引擎..."),
            ],
          ),
        ),
        // 3. 发生错误，显示错误信息
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "VAD 引擎初始化失败:\n$error",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// 将原来的 UI 逻辑提取到一个独立的 Widget 中，使其更清晰
class VadDetectionView extends ConsumerWidget {
  const VadDetectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(vadViewModelProvider);
    final viewModel = ref.read(vadViewModelProvider.notifier);
    
    final bool isDetecting = uiState.status == VadStatus.listening || uiState.status == VadStatus.speaking;
    final String buttonText = isDetecting ? "停止检测" : "开始检测";
    final Color indicatorColor;
    
    // ... (原来的 switch case 和其他 UI 代码完全不变)
    switch (uiState.status) {
        case VadStatus.speaking:
            indicatorColor = Colors.green;
            break;
        case VadStatus.listening:
            indicatorColor = Colors.orange;
            break;
        case VadStatus.error:
            indicatorColor = Colors.red;
            break;
        default:
            indicatorColor = Colors.grey;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor.withOpacity(0.2),
              border: Border.all(color: indicatorColor, width: 4),
            ),
            child: Center(
              child: Icon(
                Icons.mic,
                color: indicatorColor,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            uiState.message,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () => viewModel.toggleDetection(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDetecting ? Colors.redAccent : Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}