
import 'package:flutter/material.dart';
import 'package:flutter_frame/features/speech_recognition/presentation/pages/recognition_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DemoType {
  speechRecognition('语音识别'),
  keywordSpotting('关键词识别'),
  textToSpeech('语音合成');

  const DemoType(this.displayName);
  final String displayName;
}
class SpeechPage extends ConsumerWidget {
  const SpeechPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有功能大类的列表
    final demoTypes = DemoType.values;

    // 使用 DefaultTabController 来自动管理 TabBar 和 TabBarView 的状态
    return DefaultTabController(
      length: demoTypes.length, // Tab 的数量
      child: Scaffold(
        appBar: AppBar(
          title: const Text("功能演示中心"),
          // 将 TabBar 放在 AppBar 的底部
          bottom: TabBar(
            isScrollable: true, // 如果 Tab 太多，可以横向滚动
            tabs: demoTypes.map((demo) {
              // 为每个功能大类创建一个 Tab
              return Tab(text: demo.displayName);
            }).toList(),
          ),
        ),
        // TabBarView 用于显示与每个 Tab 对应的内容
        body: TabBarView(
          // TabBarView 的子项必须和 TabBar 的 Tab 一一对应
          children: demoTypes.map((demo) {
            // 根据 DemoType 构建对应的 UI
            return _buildDemoUI(context, ref, demo);
          }).toList(),
        ),
      ),
    );
  }

  /// 根据选择的 DemoType 构建对应的 UI
  Widget _buildDemoUI(BuildContext context, WidgetRef ref, DemoType demoType) {
    switch (demoType) {
      case DemoType.speechRecognition:
        return const SpeechRecognitionPage(); // 抽离出 ASR 的专属 Widget
      case DemoType.keywordSpotting:
        return const Center(child: Text("关键词识别 (KWS) UI 待实现")); // 占位符
      case DemoType.textToSpeech:
        return const Center(child: Text("语音合成 (TTS) UI 待实现")); // 占位符
    }
  }
}