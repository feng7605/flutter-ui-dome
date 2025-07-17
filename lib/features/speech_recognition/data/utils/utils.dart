import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig() async {
  const modelDir ='assets/res/onnx';
  return sherpa_onnx.OnlineModelConfig(
    transducer: sherpa_onnx.OnlineTransducerModelConfig(
      // encoder: await copyAssetFile('$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
      // decoder: await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
      // joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
      // encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx'),
      // decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-4-chunk-16-left-128.onnx'),
      // joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'),
      encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-2-chunk-16-left-256.int8.onnx'),
      decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-2-chunk-16-left-256.onnx'),
      joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-2-chunk-16-left-256.onnx'),
    ),
    tokens: await copyAssetFile('$modelDir/tokens.txt'),
    modelType: 'zipformer2',
  );
}

Future<String> copyAssetFile(String src, [String? dst]) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  if (dst == null) {
    dst = basename(src);
  }
  final target = join(directory.path, dst);
  bool exists = await new File(target).exists();

  final data = await rootBundle.load(src);

  if (!exists || File(target).lengthSync() != data.lengthInBytes) {
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(target).writeAsBytes(bytes);
  }

  return target;
}

Float32List convertBytesToFloat32(Uint8List bytes, [endian = Endian.little]) {
  final values = Float32List(bytes.length ~/ 2);

  final data = ByteData.view(bytes.buffer);

  for (var i = 0; i < bytes.length; i += 2) {
    int short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32768.0;
  }

  return values;
}