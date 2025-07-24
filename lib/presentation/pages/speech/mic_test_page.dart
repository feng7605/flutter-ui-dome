import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_frame/presentation/providers/mic_test_providers.dart';
import 'package:flutter_frame/presentation/viewmodels/mic_test_viewmodel.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
class MicTestPage extends ConsumerWidget {
  const MicTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(micTestViewModelProvider);
    final viewModel = ref.read(micTestViewModelProvider.notifier);
    final recorderController = viewModel.recorderController;

    final bool isListening = uiState.status == MicStatus.listening;
    final String buttonText = isListening ? "停止监听" : "开始监听";

    return Scaffold(
      appBar: AppBar(
        title: const Text("麦克风基础测试 (最新版波形)"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // **核心修改**: 使用新的 AudioWaveform 组件和 WaveStyle API
            AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width * 0.8, 150),
              recorderController: recorderController,
              waveStyle: const WaveStyle(
                waveColor: Colors.green,
                showDurationLabel: false,
                extendWaveform: true,
                showMiddleLine: false,
                spacing: 6.0,
                waveCap: StrokeCap.round,
                waveThickness: 4.0,
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
              onPressed: viewModel.toggleRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: isListening ? Colors.redAccent : Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}