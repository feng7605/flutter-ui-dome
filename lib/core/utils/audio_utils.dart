import 'dart:typed_data';

/// 一个包含音频处理相关静态工具方法的类。
class AudioUtils {
  // 私有构造函数，防止被实例化。
  AudioUtils._();

  /// 将 16-bit PCM (小端) 字节列表转换为 32-bit 浮点数列表。
  ///
  /// PCM 16-bit 的范围是 -32768 到 32767。
  /// 转换后的浮点数范围是 -1.0 到 1.0。
  ///
  /// [bytes] - 输入的 Uint8List 字节数据。
  static Float32List bytesToFloat32(Uint8List bytes) {
    // 确保字节长度是偶数
    if (bytes.lengthInBytes % 2 != 0) {
      // 或者可以截断，但这通常表示数据有问题
      throw ArgumentError("输入字节长度必须是偶数");
    }

    final byteData = ByteData.view(bytes.buffer);
    final float32List = Float32List(bytes.lengthInBytes ~/ 2);

    for (var i = 0; i < float32List.length; i++) {
      // 从字节数据中读取一个小端16位有符号整数，然后归一化到 [-1.0, 1.0]
      float32List[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return float32List;
  }

  /// 将 32-bit 浮点数列表转换为 16-bit PCM (小端) 字节列表。
  ///
  /// 输入的浮点数范围应为 -1.0 到 1.0。
  /// 转换后的 PCM 16-bit 范围是 -32768 到 32767。
  ///
  /// [float32List] - 输入的 Float32List 浮点数数据。
  static Uint8List float32ToBytes(Float32List float32List) {
    // 每个浮点数将转换为2个字节
    final byteData = ByteData(float32List.length * 2);
    
    for (var i = 0; i < float32List.length; i++) {
      // 将浮点数乘以32768.0，然后四舍五入并钳制在16位整数范围内
      final sample = (float32List[i] * 32768.0).round().clamp(-32768, 32767);
      // 将16位整数以小端模式写入字节数据
      byteData.setInt16(i * 2, sample, Endian.little);
    }
    
    return byteData.buffer.asUint8List();
  }
}