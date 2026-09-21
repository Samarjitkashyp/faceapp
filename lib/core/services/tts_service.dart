import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../storage/local_storage.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  String _preset = 'female';
  String _language = 'en-US';
  double _pitch = 1.15;
  double _rate = 0.48;

  bool get isSpeaking => _isSpeaking;
  String get preset => _preset;
  String get language => _language;
  double get pitch => _pitch;
  double get rate => _rate;

  // Dictionary for translating app speech to natural Hindi if Hindi voice is selected
  static final Map<String, String> _hindiPhrases = {
    'Starting AI face detection. Please look directly into the camera for verification.':
        'एआई फेस डिटेक्शन शुरू हो रहा है। कृपया सीधे कैमरे में देखें।',
    'Please look directly into the camera for verification.':
        'कृपया सत्यापन के लिए सीधे कैमरे में देखें।',
    'Angle 1. Look directly at the camera with a neutral face.':
        'एंगल 1: कृपया सीधे कैमरे की तरफ सामान्य चेहरे के साथ देखें।',
    'Angle 1. Please look straight ahead at the camera with a neutral expression.':
        'एंगल 1: कृपया सीधे कैमरे की तरफ सामान्य चेहरे के साथ देखें।',
    'Angle 2. Please turn your head slightly to the left.':
        'एंगल 2: कृपया अपना चेहरा थोड़ा सा बाईं तरफ घुमाएं।',
    'Angle 3. Now turn your head slightly to the right.':
        'एंगल 3: अब अपना चेहरा थोड़ा सा दाईं तरफ घुमाएं।',
    'Angle 4. Tilt your chin slightly upward.':
        'एंगल 4: अपनी ठुड्डी को थोड़ा सा ऊपर उठाएं।',
    'Angle 4. Slightly tilt your chin upward.':
        'एंगल 4: अपनी ठुड्डी को थोड़ा सा ऊपर उठाएं।',
    'Angle 5. Finally, please give a natural smile!':
        'एंगल 5: अंत में, कृपया चेहरे पर एक हल्की मुस्कान लाएं!',
    'Welcome to 5-Angle Face Setup. Please hold your phone at eye level. We will capture 5 angles of your face for accurate attendance. Starting with Angle 1: Please look directly into the camera.':
        '5-एंगल फेस वेरिफिकेशन में आपका स्वागत है। कृपया कैमरे को आंखों के सामने सीधा रखें। हम आपके चेहरे के 5 एंगल कैप्चर करेंगे। चलिए एंगल 1 से शुरू करते हैं: सीधे कैमरे में देखें।',
    'Angle 1 verified! Moving to Angle 2.':
        'एंगल 1 सत्यापित हो गया! एंगल 2 की तरफ बढ़ते हैं।',
    'Angle 2 verified! Moving to Angle 3.':
        'एंगल 2 सत्यापित हो गया! एंगल 3 की तरफ बढ़ते हैं।',
    'Angle 3 verified! Moving to Angle 4.':
        'एंगल 3 सत्यापित हो गया! एंगल 4 की तरफ बढ़ते हैं।',
    'Angle 4 verified! Moving to Angle 5.':
        'एंगल 4 सत्यापित हो गया! एंगल 5 की तरफ बढ़ते हैं।',
    'Angle verified! Moving to next angle.':
        'एंगल सत्यापित हो गया! अगले एंगल की तरफ बढ़ते हैं।',
    'Biometric calibration complete! All five angles are registered.':
        'बायोमेट्रिक कैलिब्रेशन पूरा हुआ! सभी पाँच एंगल रजिस्टर हो चुके हैं।',
    'Please face the camera clearly and try again.':
        'कृपया कैमरे के सामने स्पष्ट रूप से आएं और पुनः प्रयास करें।',
    'Face not detected. Please align your face inside the circle and try again.':
        'चेहरा पहचाना नहीं गया। कृपया चेहरे को वृत्त के अंदर रखें और पुनः प्रयास करें।',
    'Face not recognized. Please ensure good lighting or calibrate face angles.':
        'चेहरा पहचाना नहीं गया। कृपया अच्छी रोशनी में देखें या अपने चेहरे के एंगल कैलिब्रेट करें।',
    'Check in recorded.': 'आपका चेक इन दर्ज कर लिया गया है।',
    'Check out recorded.': 'आपका चेक आउट दर्ज कर लिया गया है।',
  };

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();

      // Load saved voice configurations
      _preset = await LocalStorage.getTtsPreset();
      _language = await LocalStorage.getTtsLanguage();
      _pitch = await LocalStorage.getTtsPitch();
      _rate = await LocalStorage.getTtsRate();

      await _applyTtsConfig();

      _flutterTts?.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts?.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS Init failed: $e');
    }
  }

  Future<void> _applyTtsConfig() async {
    try {
      await _flutterTts?.setSpeechRate(_rate);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(_pitch);
      await _flutterTts?.setLanguage(_language);
    } catch (e) {
      debugPrint('TTS apply config error: $e');
    }
  }

  /// Selects a predefined voice profile
  Future<void> applyPreset(String newPreset) async {
    _preset = newPreset;
    switch (newPreset) {
      case 'female':
        _pitch = 1.25;
        _rate = 0.48;
        _language = 'en-US';
        break;
      case 'male':
        _pitch = 0.78;
        _rate = 0.46;
        _language = 'en-US';
        break;
      case 'robot':
        _pitch = 0.55;
        _rate = 0.42;
        _language = 'en-US';
        break;
      case 'hindi':
        _pitch = 1.05;
        _rate = 0.46;
        _language = 'hi-IN';
        break;
      case 'indian_en':
        _pitch = 1.15;
        _rate = 0.48;
        _language = 'en-IN';
        break;
      default:
        _pitch = 1.15;
        _rate = 0.48;
        _language = 'en-US';
    }

    await LocalStorage.saveTtsPreset(_preset);
    await LocalStorage.saveTtsLanguage(_language);
    await LocalStorage.saveTtsPitch(_pitch);
    await LocalStorage.saveTtsRate(_rate);

    await _applyTtsConfig();
  }

  /// Custom fine-tuning of voice pitch, speech rate, and language
  Future<void> updateConfig({
    String? preset,
    String? language,
    double? pitch,
    double? rate,
  }) async {
    if (preset != null) _preset = preset;
    if (language != null) _language = language;
    if (pitch != null) _pitch = pitch;
    if (rate != null) _rate = rate;

    await LocalStorage.saveTtsPreset(_preset);
    await LocalStorage.saveTtsLanguage(_language);
    await LocalStorage.saveTtsPitch(_pitch);
    await LocalStorage.saveTtsRate(_rate);

    await _applyTtsConfig();
  }

  /// Plays a test sample using the current voice settings
  Future<void> testCurrentVoice() async {
    if (_language.startsWith('hi')) {
      await speak('नमस्ते! मैं आपका विज़न एआई बायोमेट्रिक सुरक्षा सहायक हूँ।');
    } else {
      await speak('Hello! I am your VisionAI biometric security assistant.');
    }
  }

  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await stop();

      String spokenText = text;
      // If language is Hindi, translate known prompts or dynamic name announcements
      if (_language.startsWith('hi')) {
        if (_hindiPhrases.containsKey(text)) {
          spokenText = _hindiPhrases[text]!;
        } else if (text.startsWith('Identity verified! Welcome, ')) {
          final name = text.replaceFirst('Identity verified! Welcome, ', '').replaceAll('.', '');
          spokenText = 'पहचान सत्यापित हुई! स्वागत है, $name।';
        }
      }

      await _flutterTts?.speak(spokenText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Speaks text and awaits until playback is completely finished or safely timed out
  Future<void> speakAndWait(String text, {int maxTimeoutSeconds = 12}) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await stop();

      String spokenText = text;
      if (_language.startsWith('hi')) {
        if (_hindiPhrases.containsKey(text)) {
          spokenText = _hindiPhrases[text]!;
        } else if (text.startsWith('Identity verified! Welcome, ')) {
          final name = text.replaceFirst('Identity verified! Welcome, ', '').replaceAll('.', '');
          spokenText = 'पहचान सत्यापित हुई! स्वागत है, $name।';
        }
      }

      final completer = Completer<void>();
      Timer? safetyTimer;

      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
        if (!completer.isCompleted) {
          safetyTimer?.cancel();
          completer.complete();
        }
      });

      _flutterTts?.setErrorHandler((msg) {
        _isSpeaking = false;
        if (!completer.isCompleted) {
          safetyTimer?.cancel();
          completer.complete();
        }
      });

      // Calculate approximate speech duration (rate is ~2.8 words/sec plus 1.2s padding)
      final wordCount = spokenText.split(' ').where((w) => w.isNotEmpty).length;
      final estimatedSeconds = ((wordCount / 2.8) + 1.2).ceil();
      final timeoutSeconds = estimatedSeconds.clamp(3, maxTimeoutSeconds);

      safetyTimer = Timer(Duration(seconds: timeoutSeconds), () {
        _isSpeaking = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _isSpeaking = true;
      await _flutterTts?.speak(spokenText);
      await completer.future;
    } catch (e) {
      debugPrint('TTS speakAndWait error: $e');
    }
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
