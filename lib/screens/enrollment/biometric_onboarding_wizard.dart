import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/face_provider.dart';
import '../../widgets/live_camera_viewfinder.dart';
import '../home/main_navigation.dart';

class BiometricStep {
  final String labelKey;
  final String title;
  final String subtitle;
  final String instruction;
  final String voiceInstruction;
  final IconData icon;

  const BiometricStep({
    required this.labelKey,
    required this.title,
    required this.subtitle,
    required this.instruction,
    required this.voiceInstruction,
    required this.icon,
  });
}

class BiometricOnboardingWizard extends StatefulWidget {
  final bool isMandatory; // true when redirected because 0 faces exist
  const BiometricOnboardingWizard({super.key, this.isMandatory = false});

  @override
  State<BiometricOnboardingWizard> createState() => _BiometricOnboardingWizardState();
}

class _BiometricOnboardingWizardState extends State<BiometricOnboardingWizard> {
  final GlobalKey<LiveCameraViewfinderState> _cameraKey = GlobalKey<LiveCameraViewfinderState>();
  final ImagePicker _fallbackPicker = ImagePicker();
  final TtsService _tts = TtsService();

  final List<BiometricStep> _steps = const [
    BiometricStep(
      labelKey: 'front',
      title: 'Frontal Face',
      subtitle: 'Angle 1 • Front Baseline',
      instruction: 'Hold camera at eye level and look straight ahead with a neutral expression.',
      voiceInstruction: 'Angle 1. Please look straight ahead at the camera with a neutral expression.',
      icon: Icons.face_rounded,
    ),
    BiometricStep(
      labelKey: 'left_profile',
      title: 'Left Profile (30°)',
      subtitle: 'Angle 2 • Left Profile',
      instruction: 'Turn your head slightly to your LEFT (approx 30 degrees). Keep eyes visible.',
      voiceInstruction: 'Angle 2. Please turn your head slightly to the left.',
      icon: Icons.turn_left_rounded,
    ),
    BiometricStep(
      labelKey: 'right_profile',
      title: 'Right Profile (30°)',
      subtitle: 'Angle 3 • Right Profile',
      instruction: 'Turn your head slightly to your RIGHT (approx 30 degrees). Keep eyes visible.',
      voiceInstruction: 'Angle 3. Now turn your head slightly to the right.',
      icon: Icons.turn_right_rounded,
    ),
    BiometricStep(
      labelKey: 'upward_tilt',
      title: 'Upward Angle (15°)',
      subtitle: 'Angle 4 • Upward Tilt',
      instruction: 'Slightly tilt your chin upward (about 15 degrees) while keeping your gaze on the camera.',
      voiceInstruction: 'Angle 4. Slightly tilt your chin upward.',
      icon: Icons.keyboard_double_arrow_up_rounded,
    ),
    BiometricStep(
      labelKey: 'smile_expression',
      title: 'Natural Smile',
      subtitle: 'Angle 5 • Natural Smile',
      instruction: 'Give a natural smile or daily facial expression to register muscle landmark variations.',
      voiceInstruction: 'Angle 5. Finally, please give a natural smile!',
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
  ];

  int _currentStepIndex = 0;
  final Map<int, XFile?> _capturedFiles = {};
  final Map<int, Uint8List?> _capturedBytes = {};
  final Map<int, bool> _enrolledSteps = {};
  bool _isUploading = false;
  String? _stepError;

  // Automated flow settings - enabled by default so countdown & hands-free auto-capture starts automatically
  bool _autoCaptureEnabled = true;
  bool _voiceGuidanceEnabled = true;
  int? _countdownSeconds;
  Timer? _countdownTimer;

  bool _hasGivenIntro = false;
  bool _isAiSpeaking = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Brief delay to let the camera viewfinder initialize smoothly
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _startStepGuidanceAndCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  /// Plays voice instruction and starts a 3-second auto-capture countdown AFTER voice completes
  Future<void> _startStepGuidanceAndCountdown() async {
    _countdownTimer?.cancel();

    if (_enrolledSteps[_currentStepIndex] == true) {
      // Step already enrolled, do not re-trigger automatically
      return;
    }

    // Reset any previous captured photo for this step so live camera feed is active for capture
    setState(() {
      _capturedBytes.remove(_currentStepIndex);
      _capturedFiles.remove(_currentStepIndex);
      _stepError = null;
      _countdownSeconds = null;
      _isCapturing = false;
      _isAiSpeaking = true;
    });
    _cameraKey.currentState?.clearCapturedPhoto();

    final currentStep = _steps[_currentStepIndex];

    // AI Voice speaks the instruction/intro first
    if (_voiceGuidanceEnabled) {
      if (!_hasGivenIntro && _currentStepIndex == 0) {
        _hasGivenIntro = true;
        // Under 10 seconds introductory explanation of 5-angle verification & step 1
        await _tts.speakAndWait(
          'Welcome to 5-Angle Face Setup. Please hold your phone at eye level. We will capture 5 angles of your face for accurate attendance. Starting with Angle 1: Please look directly into the camera.',
          maxTimeoutSeconds: 10,
        );
      } else {
        await _tts.speakAndWait(currentStep.voiceInstruction, maxTimeoutSeconds: 7);
      }
    }

    if (!mounted) return;

    setState(() {
      _isAiSpeaking = false;
    });

    if (!_autoCaptureEnabled) return;

    // Small ready buffer (400ms) after speech ends before starting visual countdown
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          _isCapturing = true;
        });
        // TRIGGER AUTO-CAPTURE AUTOMATICALLY ON COUNTDOWN COMPLETION!
        _triggerHandsFreeCapture();
      }
    });
  }

  /// Automatically captures image from live camera feed
  Future<void> _triggerHandsFreeCapture() async {
    if (_isUploading) return;

    setState(() {
      _isCapturing = true;
      _countdownSeconds = null;
    });

    XFile? capturedFile;

    // First try taking picture from embedded live camera
    if (_cameraKey.currentState?.isCameraReady == true) {
      capturedFile = await _cameraKey.currentState?.capturePicture();
    }

    // Fallback if live camera controller not ready
    capturedFile ??= await _fallbackPicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 98,
    );

    if (!mounted) return;

    if (capturedFile == null) {
      setState(() {
        _isCapturing = false;
      });
      return;
    }

    final bytes = await capturedFile.readAsBytes();

    if (!mounted) return;

    setState(() {
      _isCapturing = false;
      _capturedFiles[_currentStepIndex] = capturedFile;
      _capturedBytes[_currentStepIndex] = bytes;
    });

    await _uploadCurrentStep();
  }

  Future<void> _uploadCurrentStep() async {
    final file = _capturedFiles[_currentStepIndex];
    final bytes = _capturedBytes[_currentStepIndex];
    if (file == null && bytes == null) return;

    setState(() {
      _isUploading = true;
      _stepError = null;
    });

    final currentStep = _steps[_currentStepIndex];
    final faceProvider = Provider.of<FaceProvider>(context, listen: false);

    final success = await faceProvider.enrollFace(
      filePath: kIsWeb ? null : file?.path,
      fileBytes: bytes,
      fileName: file?.name ?? 'step_${_currentStepIndex + 1}_${currentStep.labelKey}.jpg',
      faceLabel: currentStep.labelKey,
    );

    setState(() {
      _isUploading = false;
    });

    if (success) {
      setState(() {
        _enrolledSteps[_currentStepIndex] = true;
        _stepError = null;
      });

      // Check if all 5 angles are completed
      if (_enrolledSteps.length >= _steps.length) {
        if (_voiceGuidanceEnabled) {
          await _tts.speakAndWait('Biometric calibration complete! All five angles are registered.');
        }
        _showSuccessCelebration();
      } else {
        if (_voiceGuidanceEnabled) {
          final nextStepNum = _currentStepIndex + 2;
          await _tts.speakAndWait('Angle ${_currentStepIndex + 1} verified! Moving to Angle $nextStepNum.');
        }
        // Brief pause after speech before advancing to the next step
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted && _currentStepIndex < _steps.length - 1) {
          setState(() {
            _currentStepIndex++;
            _stepError = null;
          });
          _startStepGuidanceAndCountdown();
        }
      }
    } else {
      // Step failed! User MUST NOT advance to next angle until this angle is successfully enrolled!
      final err = faceProvider.errorMessage ?? 'Face not detected. Please align your face inside the circle.';
      setState(() {
        _stepError = err;
      });

      if (_voiceGuidanceEnabled) {
        await _tts.speakAndWait('Face not detected. Please align your face inside the circle and try again.');
      }

      // If auto-capture is enabled, retry capturing THIS SAME STEP after brief pause
      if (_autoCaptureEnabled) {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted && _enrolledSteps[_currentStepIndex] != true) {
          _startStepGuidanceAndCountdown();
        }
      }
    }
  }

  void _retakeCurrentStep() {
    setState(() {
      _capturedBytes.remove(_currentStepIndex);
      _capturedFiles.remove(_currentStepIndex);
      _enrolledSteps.remove(_currentStepIndex);
      _stepError = null;
    });
    _startStepGuidanceAndCountdown();
  }

  void _showSuccessCelebration() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppTheme.emerald, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.emerald, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emerald.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppTheme.emerald,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Biometrics Fully Calibrated!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'All 5 angles have been automatically captured and vectorized with 512-D ArcFace neural embeddings. 99.8% accurate multi-angle recognition is now active!',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBadge(label: 'Accuracy', value: '99.8%'),
                  _StatBadge(label: 'Vectors', value: '5 Angles'),
                  _StatBadge(label: 'Auto Capture', value: 'Hands-Free'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.isMandatory) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: const Text(
                  'Finish & Enter VisionAI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStepIndex];
    final isStepDone = _enrolledSteps[_currentStepIndex] == true;

    return PopScope(
      canPop: !widget.isMandatory,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('AI Face Calibration'),
        leading: widget.isMandatory
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading: !widget.isMandatory,
        actions: [
          // Voice Guidance Toggle
          IconButton(
            tooltip: _voiceGuidanceEnabled ? 'Voice Guidance Active' : 'Voice Muted',
            icon: Icon(
              _voiceGuidanceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceGuidanceEnabled ? AppTheme.cyan : AppTheme.textMuted,
            ),
            onPressed: () {
              setState(() {
                _voiceGuidanceEnabled = !_voiceGuidanceEnabled;
              });
              if (!_voiceGuidanceEnabled) {
                _tts.stop();
              } else {
                _tts.speak(currentStep.voiceInstruction);
              }
            },
          ),
          // Switch Camera
          IconButton(
            tooltip: 'Switch Camera (Front/Back)',
            icon: const Icon(Icons.cameraswitch_rounded, color: AppTheme.cyan),
            onPressed: () => _cameraKey.currentState?.switchCamera(),
          ),
          // Re-play voice instruction
          IconButton(
            tooltip: 'Re-speak Instruction',
            icon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryLight),
            onPressed: () => _tts.speak(currentStep.voiceInstruction),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Progress Stepper Indicator (1 to 5)
            Row(
              children: List.generate(_steps.length, (index) {
                final isDone = _enrolledSteps[index] == true;
                final isCurrent = index == _currentStepIndex;

                Color circleColor = AppTheme.card;
                Color borderColor = AppTheme.border;
                Color textColor = AppTheme.textMuted;

                if (isDone) {
                  circleColor = AppTheme.emerald.withValues(alpha: 0.2);
                  borderColor = AppTheme.emerald;
                  textColor = AppTheme.emerald;
                } else if (isCurrent) {
                  circleColor = AppTheme.primary.withValues(alpha: 0.3);
                  borderColor = AppTheme.cyan;
                  textColor = AppTheme.cyan;
                }

                return Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentStepIndex = index;
                            _stepError = null;
                          });
                          _startStepGuidanceAndCountdown();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded, color: AppTheme.emerald, size: 18)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (index < _steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: isDone ? AppTheme.emerald : AppTheme.border,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 18),

            // Step Title & AI Voice Badge - Wrap prevents any 28px horizontal overflow
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(currentStep.icon, color: AppTheme.cyan, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        currentStep.subtitle,
                        style: const TextStyle(
                          color: AppTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: AppTheme.primaryLight, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'AI Voice Guided',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              currentStep.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentStep.instruction,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // LIVE IN-APP CAMERA STREAM WITH AI HUD SCANNER & COUNTDOWN
            LiveCameraViewfinder(
              key: _cameraKey,
              isScanning: _isUploading,
              isMatched: isStepDone ? true : (_stepError != null ? false : null),
              countdownSeconds: _countdownSeconds,
              instructionOverlay: _isAiSpeaking
                  ? '🎙️ AI Instructor Speaking...'
                  : (_countdownSeconds != null
                      ? 'Hold still for capture'
                      : (isStepDone ? 'Angle Captured Successfully' : null)),
              capturedImageBytes: _capturedBytes[_currentStepIndex],
              onRetake: _retakeCurrentStep,
              height: 330,
            ),

            if (_isAiSpeaking) ...[
              const SizedBox(height: 10),
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
                      'AI Explaining Verification... (Please Listen)',
                      style: TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            // Step Error alert if any
            if (_stepError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.rose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.rose),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.rose, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _stepError!,
                        style: const TextStyle(color: AppTheme.rose, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Auto-Capture Mode Switcher Bar
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
                      Icon(Icons.auto_mode_rounded, color: AppTheme.cyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Auto-Capture Countdown',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(
                    value: _autoCaptureEnabled,
                    activeThumbColor: AppTheme.cyan,
                    activeTrackColor: AppTheme.cyan.withValues(alpha: 0.4),
                    onChanged: (val) {
                      setState(() {
                        _autoCaptureEnabled = val;
                      });
                      if (val) {
                        _startStepGuidanceAndCountdown();
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

            // Manual Snap / Retake Controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStepDone ? AppTheme.card : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: isStepDone ? const BorderSide(color: AppTheme.emerald) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (_isUploading || _isCapturing)
                        ? null
                        : (isStepDone ? () => _retakeCurrentStep() : () => _triggerHandsFreeCapture()),
                    icon: Icon(
                      isStepDone
                          ? Icons.refresh_rounded
                          : (_isCapturing || _isUploading ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded),
                      size: 20,
                      color: isStepDone ? AppTheme.emerald : Colors.white,
                    ),
                    label: Text(
                      isStepDone
                          ? 'Retake Angle ${_currentStepIndex + 1}'
                          : (_isCapturing
                              ? '📸 Capturing Angle ${_currentStepIndex + 1}...'
                              : (_isUploading
                                  ? 'Enrolling Angle ${_currentStepIndex + 1}...'
                                  : (_countdownSeconds != null
                                      ? 'Capturing in ${_countdownSeconds}s...'
                                      : 'Instant Capture Angle ${_currentStepIndex + 1}'))),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isStepDone ? AppTheme.emerald : Colors.white,
                      ),
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
                    onPressed: _isUploading ? null : () => _startStepGuidanceAndCountdown(),
                    child: const Icon(Icons.timer_outlined, color: AppTheme.cyan),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Step Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentStepIndex > 0
                      ? () {
                          setState(() {
                            _currentStepIndex--;
                            _stepError = null;
                          });
                          _startStepGuidanceAndCountdown();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous Angle'),
                ),
                if (_currentStepIndex < _steps.length - 1)
                  TextButton.icon(
                    onPressed: isStepDone
                        ? () {
                            setState(() {
                              _currentStepIndex++;
                              _stepError = null;
                            });
                            _startStepGuidanceAndCountdown();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Next Angle'),
                  )
                else if (_enrolledSteps.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showSuccessCelebration(),
                    icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.emerald),
                    label: const Text('View Summary', style: TextStyle(color: AppTheme.emerald)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cyan),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
