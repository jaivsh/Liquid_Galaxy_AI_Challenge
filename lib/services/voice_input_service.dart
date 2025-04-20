import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
    }
    return _isInitialized;
  }

  Future<String?> startListening({
    required Function(String text) onResult,
    required Function() onListeningComplete,
    required BuildContext context,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
        return null;
      }
    }

    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return null;
    }

    await _speech.listen(
      onResult: (result) {
        final recognizedWords = result.recognizedWords;
        onResult(recognizedWords);
        if (result.finalResult) {
          onListeningComplete();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );

    return null;
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}