import 'package:flutter/foundation.dart';

@immutable
class AsrResult {
  final String text;
  /// 是否是最终结果（用于流式识别）
  final bool isFinal;

  const AsrResult({required this.text, this.isFinal = true});
}