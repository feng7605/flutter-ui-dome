import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import '../models/asr_config.dart';

// Isolate 需要的所有数据都必须通过这个参数类传递
class SherpaInitParams {
  final ModelConfig modelConfig;
  final String modelPath;

  SherpaInitParams({required this.modelConfig, required this.modelPath});
}

// 这是将在 Isolate 中运行的顶层函数
Future<sherpa_onnx.OnlineRecognizer> prepareRecognizerInIsolate(SherpaInitParams params) async {
  // 在新的 Isolate 中，我们需要重新初始化绑定
  sherpa_onnx.initBindings();
  
  // 从参数中获取数据
  final modelDir = Directory(params.modelPath);
  
  // 这个函数现在是纯计算和同步I/O，它会阻塞当前 Isolate，但不会阻塞UI线程
  final sherpaModelConfig = _getSherpaModelConfigFromLocal(modelDir, params.modelConfig);
  final recognizerConfig = sherpa_onnx.OnlineRecognizerConfig(model: sherpaModelConfig);
  
  // 创建并返回识别器实例
  return sherpa_onnx.OnlineRecognizer(recognizerConfig);
}


// 将 _getSherpaModelConfigFromLocal 也变成一个顶层函数

sherpa_onnx.OnlineModelConfig _getSherpaModelConfigFromLocal(
  Directory modelDir, 
  ModelConfig modelConfig // 传入完整的模型配置
) {
  final modelPath = modelDir.path;

  // 根据 modelType 动态构建配置
  switch (modelConfig.modelType) {
    case "zipformer":
      // 适用于包含独立 encoder, decoder, joiner 的模型
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelPath/encoder.onnx',
          decoder: '$modelPath/decoder.onnx',
          joiner: '$modelPath/joiner.onnx',
        ),
        tokens: '$modelPath/tokens.txt',
      );
    case "zipformer2":
      // 适用于包含独立 encoder, decoder, joiner 的模型
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelPath/encoder.onnx',
          decoder: '$modelPath/decoder.onnx',
          joiner: '$modelPath/joiner.onnx',
        ),
        tokens: '$modelPath/tokens.txt',
      );
    
    case "transducer":
      // 适用于将 encoder, decoder, joiner 整合到一起的模型
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          // 假设整合后的模型文件名在配置中指定
          encoder: '$modelPath/encoder-plus-decoder.onnx', 
          decoder: '',
          joiner: '',
        ),
        tokens: '$modelPath/tokens.txt',
      );

    // 你可以根据需要添加更多模型类型
    // case "paraformer":
    //   return sherpa_onnx.OnlineModelConfig(
    //     paraformer: sherpa_onnx.OnlineParaformerModelConfig(...),
    //     tokens: '$modelPath/tokens.txt',
    //   );

    default:
      throw Exception("不支持的模型类型: ${modelConfig.modelType}");
  }
}