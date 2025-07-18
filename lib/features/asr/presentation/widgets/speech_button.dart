import 'package:flutter/material.dart';
class SpeechButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isRecognizing;
  final bool isLoading;

  const SpeechButton({
    Key? key,
    required this.onPressed,
    this.isRecognizing = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FloatingActionButton.large(
      onPressed: onPressed,
      backgroundColor: isRecognizing ? Colors.red.shade400 : Theme.of(context).primaryColor,
      child: Icon(
        isRecognizing ? Icons.stop : Icons.mic,
        color: Colors.white,
      ),
    );
  }
}