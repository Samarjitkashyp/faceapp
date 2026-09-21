import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recognition_result.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/face_provider.dart';
import '../../widgets/live_camera_viewfinder.dart';
import '../enrollment/biometric_onboarding_wizard.dart';

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  final GlobalKey<LiveCameraViewfinderState> _cameraKey = GlobalKey<LiveCameraViewfinderState>();
  final ImagePicker _fallbackPicker = ImagePicker();
  final TtsService _tts = TtsService();

  XFile? _capturedImage;
  Uint8List? _imageBytes;
  RecognitionResult? _result;

  bool _autoScanEnabled = true;
  bool _hasAutoScannedOnOpen = false;
  bool _voiceEnabled = true;
  bool _isAiSpeaking = false;
  int? _countdownSeconds;
  Timer? _countdownTimer;

  String? _attendanceLoggedMessage;

  @override
  void initState() {
    super.initState();
    // Automatically trigger AI face detection countdown once camera is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _autoScanEnabled && !_hasAutoScannedOnOpen) {
          if (_cameraKey.currentState?.isCameraReady == true) {
            _hasAutoScannedOnOpen = true;
            _startAutoScanCountdown();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  /// Starts step-by-step verification:
  /// Step 1: AI voice speaks complete instructions first (countdown is paused)
  /// Step 2: Visual countdown (3.. 2.. 1..) begins only AFTER speech finishes
  /// Step 3: Automatically captures hands-free image and runs AI recognition
  Future<void> _startAutoScanCountdown() async {
    _countdownTimer?.cancel();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _result = null;
      _imageBytes = null;
      _capturedImage = null;
      _attendanceLoggedMessage = null;
      _countdownSeconds = null;
      _isAiSpeaking = true;
    });
    _cameraKey.currentState?.clearCapturedPhoto();

    // Step 1: AI instruction must finish completely before visual countdown
    if (_voiceEnabled) {
      await _tts.speakAndWait(
        'Starting AI face detection. Please look directly into the camera for verification.',
        maxTimeoutSeconds: 8,
      );
    }

    if (!mounted) return;

    setState(() {
      _isAiSpeaking = false;
    });

    if (!_autoScanEnabled) return;

    // Small ready buffer (400ms) after speech ends before visual countdown starts
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Step 2: 3-Second visual countdown (3.. 2.. 1..)
    setState(() {
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds != null && _countdownSeconds! > 1) {
        setState(() {
          _countdownSeconds = _countdownSeconds! - 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownSeconds = null;
        });
        // Step 3: Trigger hands-free capture & recognition
        await _performHandsFreeScan();
      }
    });
  }

  Future<void> _performHandsFreeScan() async {
    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    if (attProvider.isRecognizing) return;

    XFile? capturedFile;

    // Capture from embedded live camera
    if (_cameraKey.currentState?.isCameraReady == true) {
      capturedFile = await _cameraKey.currentState?.capturePicture();
    }

    // Fallback if camera controller not available
    capturedFile ??= await _fallbackPicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 98,
    );

    if (capturedFile == null) return;

    final bytes = await capturedFile.readAsBytes();

    setState(() {
      _capturedImage = capturedFile;
      _imageBytes = bytes;
      _result = null;
      _attendanceLoggedMessage = null;
    });

    await _processRecognition();
  }

  Future<void> _processRecognition() async {
    if (_capturedImage == null && _imageBytes == null) return;

    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);

    final res = await attProvider.recognizeFace(
      filePath: kIsWeb ? null : _capturedImage?.path,
      fileBytes: _imageBytes,
      fileName: _capturedImage?.name ?? 'captured_face.jpg',
    );

    if (!mounted) return;

    setState(() {
      _result = res;
    });

    if (res != null && res.matched) {
      final name = res.person?.fullName ?? res.person?.username ?? 'Employee';
      if (_voiceEnabled) {
        await _tts.speakAndWait('Identity verified! Welcome, $name.', maxTimeoutSeconds: 6);
      }
    } else {
      if (_voiceEnabled) {
        await _tts.speakAndWait('Face not recognized. Please ensure good lighting or calibrate face angles.', maxTimeoutSeconds: 6);
      }
    }
  }

  Future<void> _recordCheckIn(String logType) async {
    if (_result == null || !_result!.matched) return;

    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final success = await attProvider.recordAttendance(
      logType: logType,
      confidence: _result!.confidence,
    );

    if (!mounted) return;

    if (success) {
      if (_voiceEnabled) {
        _tts.speak(logType == 'check_in' ? 'Check in recorded.' : 'Check out recorded.');
      }

      final msg = logType == 'check_in' ? 'Check-In Recorded Successfully!' : 'Check-Out Recorded Successfully!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attProvider.successMessage ?? msg),
          backgroundColor: AppTheme.emerald,
        ),
      );
      // Keep last captured photo displayed on screen; do NOT erase it automatically
      setState(() {
        _attendanceLoggedMessage = msg;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attProvider.errorMessage ?? 'Failed to record attendance'),
          backgroundColor: AppTheme.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = context.watch<AttendanceProvider>();
    final faceProvider = context.watch<FaceProvider>();

    if (!faceProvider.isFullyCalibrated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Biometric Check-In'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppTheme.rose.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.rose.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.rose.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppTheme.rose, size: 44),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Biometric Check-In Locked',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  faceProvider.faces.isEmpty
                      ? 'You have not registered your face biometrics yet. To enable facial recognition and attendance check-in, please complete 5-Angle Face Setup.'
                      : 'You have only registered ${faceProvider.faces.length} of 5 required face angles. Please calibrate all 5 angles to unlock biometric check-in.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard(isMandatory: true)),
                      );
                      if (context.mounted) {
                        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                        faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                    label: Text(
                      faceProvider.faces.isEmpty
                          ? 'Start 5-Angle Setup Now'
                          : 'Complete 5-Angle Setup (${faceProvider.faces.length}/5)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Facial Recognition'),
        actions: [
          IconButton(
            tooltip: _voiceEnabled ? 'Voice Active' : 'Voice Muted',
            icon: Icon(
              _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceEnabled ? AppTheme.cyan : AppTheme.textMuted,
            ),
            onPressed: () {
              setState(() {
                _voiceEnabled = !_voiceEnabled;
              });
              if (!_voiceEnabled) _tts.stop();
            },
          ),
          IconButton(
            tooltip: 'Switch Camera (Front/Back)',
            icon: const Icon(Icons.cameraswitch_rounded, color: AppTheme.primaryLight),
            onPressed: () => _cameraKey.currentState?.switchCamera(),
          ),
          IconButton(
            tooltip: 'Rescan Face',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.cyan),
            onPressed: () => _startAutoScanCountdown(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Live Camera Viewfinder with HUD Scanner and Auto-Scan Countdown
            LiveCameraViewfinder(
              key: _cameraKey,
              isScanning: attProvider.isRecognizing,
              isMatched: _result?.matched,
              countdownSeconds: _countdownSeconds,
              instructionOverlay: _isAiSpeaking
                  ? '🎙️ AI Speaking... Please Listen'
                  : (_countdownSeconds != null
                      ? 'Hold still: Scanning in ${_countdownSeconds}s'
                      : null),
              capturedImageBytes: _imageBytes,
              onRetake: () => _startAutoScanCountdown(),
              onCameraInitialized: () {
                if (mounted && _autoScanEnabled && !_hasAutoScannedOnOpen) {
                  _hasAutoScannedOnOpen = true;
                  _startAutoScanCountdown();
                }
              },
              height: 330,
            ),

            // AI Speaking Banner Indicator
            if (_isAiSpeaking) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.record_voice_over_rounded, color: AppTheme.cyan, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'AI Explaining Face Detection... (Please Listen)',
                      style: TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            // Persistent Attendance Logged Celebration Card (keeps photo visible)
            if (_attendanceLoggedMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.emerald),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attendanceLoggedMessage!,
                            style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Text(
                            'Last photo displayed above. Tap below to scan next.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Auto-Scan Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flash_auto_rounded, color: AppTheme.cyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Auto-Scan on Open',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(
                    value: _autoScanEnabled,
                    activeThumbColor: AppTheme.cyan,
                    activeTrackColor: AppTheme.cyan.withValues(alpha: 0.4),
                    onChanged: (val) {
                      setState(() {
                        _autoScanEnabled = val;
                      });
                      if (val) {
                        _startAutoScanCountdown();
                      } else {
                        _countdownTimer?.cancel();
                        setState(() {
                          _countdownSeconds = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Capture Controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _imageBytes != null ? AppTheme.card : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: _imageBytes != null ? const BorderSide(color: AppTheme.cyan) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (attProvider.isRecognizing || _isAiSpeaking)
                        ? null
                        : (_imageBytes != null ? () => _startAutoScanCountdown() : () => _startAutoScanCountdown()),
                    icon: Icon(
                      _isAiSpeaking
                          ? Icons.record_voice_over_rounded
                          : (_imageBytes != null ? Icons.refresh_rounded : Icons.camera_alt_rounded),
                      size: 20,
                    ),
                    label: Text(
                      _isAiSpeaking
                          ? '🎙️ AI Instructing...'
                          : (_imageBytes != null
                              ? (_attendanceLoggedMessage != null ? 'Scan Next Employee' : 'Scan Again (Rescan)')
                              : (_countdownSeconds != null
                                  ? 'Scanning in ${_countdownSeconds}s...'
                                  : 'Scan & Verify Face')),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: AppTheme.card,
                    ),
                    onPressed: (attProvider.isRecognizing || _isAiSpeaking) ? null : () => _startAutoScanCountdown(),
                    child: const Icon(Icons.timer_outlined, color: AppTheme.cyan),
                  ),
                ),
              ],
            ),

            // Recognition Result Card
            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _result!.matched ? AppTheme.emerald : AppTheme.rose,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_result!.matched ? AppTheme.emerald : AppTheme.rose).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _result!.matched ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                            color: _result!.matched ? AppTheme.emerald : AppTheme.rose,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.matched ? 'Identity Verified' : 'Unknown / Unmatched Face',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _result!.matched ? AppTheme.emerald : AppTheme.rose,
                                ),
                              ),
                              Text(
                                _result!.matched
                                    ? '${(_result!.confidence * 100).toStringAsFixed(1)}% Biometric Confidence'
                                    : 'Similarity: ${_result!.similarity.toStringAsFixed(3)} (Required threshold: 0.363)',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (!_result!.matched) ...[
                      const Divider(color: AppTheme.border, height: 20),
                      const Text(
                        '💡 Tip: Camera angle or lighting differs? Calibrating 5 angles ensures ~99.8% precision.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.cyan),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard()),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 18),
                          label: const Text('Calibrate 5 Face Angles Now', style: TextStyle(color: AppTheme.cyan)),
                        ),
                      ),
                    ],

                    if (_result!.matched && _result!.person != null) ...[
                      const Divider(color: AppTheme.border, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subject Name:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text(_result!.person!.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Employee / Roll ID:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text(_result!.person!.employeeId ?? 'N/A', style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cosine Similarity:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text('${_result!.similarity.toStringAsFixed(4)} (ArcFace 512-D)', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emerald,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _recordCheckIn('check_in'),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Record Check-In'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppTheme.amber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _recordCheckIn('check_out'),
                              icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.amber),
                              label: const Text('Check-Out', style: TextStyle(color: AppTheme.amber)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
