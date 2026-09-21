import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/tts_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/face_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

List<CameraDescription> appCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    appCameras = await availableCameras();
  } catch (e) {
    debugPrint('Warning: availableCameras failed: $e');
  }

  // Pre-initialize TTS voice engine
  try {
    await TtsService().init();
  } catch (_) {}

  runApp(const VisionAIFaceApp());
}

class VisionAIFaceApp extends StatelessWidget {
  const VisionAIFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FaceProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: 'VisionAI Face App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
