import 'dart:typed_data';

class WavHeader {
  static Uint8List create({
    required int sampleRate,
    required int numChannels,
    required int bitDepth,
    required int dataLength,
  }) {
    final byteData = ByteData(44);
    final size = 36 + dataLength;

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, size, Endian.little);
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'
    
    // fmt sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6d); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Sub-chunk size
    byteData.setUint16(20, 1, Endian.little); // Audio format (1 for PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * numChannels * (bitDepth ~/ 8), Endian.little); // Byte rate
    byteData.setUint16(32, numChannels * (bitDepth ~/ 8), Endian.little); // Block align
    byteData.setUint16(34, bitDepth, Endian.little);

    // data sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataLength, Endian.little);

    return byteData.buffer.asUint8List();
  }
}