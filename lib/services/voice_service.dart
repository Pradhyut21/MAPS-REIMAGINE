import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      if (_isInitialized) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.05);

        // Prefer a female English voice when available
        try {
          final voices = await _flutterTts.getVoices;
          if (voices is List) {
            Map<dynamic, dynamic>? chosen;
            // Filter english voices first
            final english = voices.where((v) {
              final locale = (v['locale'] ?? '').toString().toLowerCase();
              return locale.startsWith('en');
            }).toList();

            // Try to find explicit female voices
            for (final v in english) {
              final name = (v['name'] ?? '').toString().toLowerCase();
              final gender = (v['gender'] ?? '').toString().toLowerCase();
              if (gender.contains('female') || name.contains('female') || name.contains('-f') || name.contains('woman')) {
                chosen = Map<dynamic, dynamic>.from(v);
                break;
              }
            }

            // Fallback: first english voice
            chosen ??= english.isNotEmpty ? Map<dynamic, dynamic>.from(english.first) : null;

            if (chosen != null) {
              await _flutterTts.setVoice({
                'name': chosen['name'],
                'locale': chosen['locale'],
              });
              debugPrint('TTS voice set to: ${chosen['name']} (${chosen['locale']})');
            }
          }
        } catch (e) {
          debugPrint('Unable to set preferred female voice: $e');
        }
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  bool get isListening => _speechToText.isListening;

  bool get isInitialized => _isInitialized;

  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
