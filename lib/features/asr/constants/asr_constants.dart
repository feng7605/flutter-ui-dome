class AsrConstants {
  // Private constructor to prevent instantiation
  AsrConstants._();

  // --- Model Types from Config ---
  static const String modelTypeZipformer2 = 'zipformer2';
  static const String modelTypeTransducer = 'transducer';

  // --- Default File Names (if needed as fallback) ---
  static const String fileEncoder = 'encoder.onnx';
  static const String fileDecoder = 'decoder.onnx';
  static const String fileJoiner = 'joiner.onnx';
  static const String fileTokens = 'tokens.txt';

  // --- Supplier Names ---
  static const String supplierSherpa = 'sherpa';
  static const String supplierIflytek = 'iflytek';
}