import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';
import 'ai_scanner_overlay.dart';

class LiveCameraViewfinder extends StatefulWidget {
  final bool isScanning;
  final bool? isMatched;
  final int? countdownSeconds;
  final String? instructionOverlay;
  final VoidCallback? onCameraInitialized;
  final VoidCallback? onRetake;
  final double height;
  final Uint8List? capturedImageBytes;

  const LiveCameraViewfinder({
    super.key,
    required this.isScanning,
    this.isMatched,
    this.countdownSeconds,
    this.instructionOverlay,
    this.onCameraInitialized,
    this.onRetake,
    this.height = 340,
    this.capturedImageBytes,
  });

  @override
  State<LiveCameraViewfinder> createState() => LiveCameraViewfinderState();
}

class LiveCameraViewfinderState extends State<LiveCameraViewfinder> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  String? _initError;
  bool _showShutterFlash = false;
  Uint8List? _internalCapturedBytes;

  bool get isCameraReady => _controller != null && _controller!.value.isInitialized;
  int get cameraCount => _availableCameras.length;
  bool get isFrontCamera =>
      _availableCameras.isNotEmpty &&
      _availableCameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  Uint8List? get effectiveImageBytes => widget.capturedImageBytes ?? _internalCapturedBytes;
  bool get hasCapturedPhoto => effectiveImageBytes != null;

  void clearCapturedPhoto() {
    if (mounted) {
      setState(() {
        _internalCapturedBytes = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    try {
      List<CameraDescription> cameras = appCameras;
      if (cameras.isEmpty) {
        cameras = await availableCameras();
        appCameras = cameras;
      }

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initError = 'No camera device found';
          });
        }
        return;
      }

      _availableCameras = cameras;

      // Prefer front camera for selfie biometric verification
      int frontIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;

      await _initControllerForCamera(_availableCameras[_selectedCameraIndex]);

      widget.onCameraInitialized?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Camera init failed: $e';
        });
      }
    }
  }

  Future<void> _initControllerForCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _initError = null;
    });
  }

  /// Switch between Front and Back camera smoothly
  Future<void> switchCamera() async {
    if (_availableCameras.length < 2) return;

    try {
      int nextIdx = (_selectedCameraIndex + 1) % _availableCameras.length;
      _selectedCameraIndex = nextIdx;

      final oldController = _controller;
      setState(() {
        _controller = null;
      });

      await oldController?.dispose();
      await _initControllerForCamera(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Takes a picture hands-free with shutter flash effect
  Future<XFile?> capturePicture() async {
    if (!isCameraReady) return null;

    try {
      // Trigger camera flash visual pulse
      if (mounted) {
        setState(() => _showShutterFlash = true);
        Timer(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _showShutterFlash = false);
        });
      }

      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Immediately freeze viewfinder with captured photo
      if (mounted) {
        setState(() {
          _internalCapturedBytes = bytes;
        });
      }

      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isMatched == true
              ? AppTheme.emerald
              : (widget.isMatched == false ? AppTheme.rose : AppTheme.borderLight),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isMatched == true ? AppTheme.emerald : AppTheme.cyan).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Captured Photo Preview (Frozen) OR Live Camera Preview Feed (Mirrored for Front Camera)
            if (hasCapturedPhoto)
              Transform.scale(
                scaleX: isFrontCamera ? -1 : 1,
                child: Image.memory(
                  effectiveImageBytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            else if (isCameraReady)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: Transform.scale(
                      scaleX: isFrontCamera ? -1 : 1,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              )
            else if (_initError != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: AppTheme.rose, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _initError!,
                      style: const TextStyle(color: AppTheme.rose, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.card,
                        side: const BorderSide(color: AppTheme.borderLight),
                      ),
                      onPressed: () {
                        setState(() {
                          _initError = null;
                        });
                        _setupCamera();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry Camera'),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.cyan),
                    SizedBox(height: 14),
                    Text(
                      'Starting High-Res AI Camera...',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // 2. Futuristic AI Hologram Overlay (HUD Brackets, Steady Lock, Status Ticker)
            AiScannerOverlay(
              isScanning: widget.isScanning,
              isMatched: widget.isMatched,
              isCaptured: hasCapturedPhoto,
              width: 260,
              height: widget.height - 20,
            ),

            // 3. Captured Photo Badge (Top-Left)
            if (hasCapturedPhoto)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isMatched == true
                          ? AppTheme.emerald
                          : (widget.isMatched == false ? AppTheme.rose : AppTheme.cyan),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isMatched == true
                            ? Icons.check_circle_rounded
                            : (widget.isMatched == false ? Icons.cancel_rounded : Icons.photo_camera_rounded),
                        color: widget.isMatched == true
                            ? AppTheme.emerald
                            : (widget.isMatched == false ? AppTheme.rose : AppTheme.cyan),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isMatched == true
                            ? 'VERIFIED'
                            : (widget.isMatched == false ? 'UNMATCHED' : 'LAST CAPTURE'),
                        style: TextStyle(
                          color: widget.isMatched == true
                              ? AppTheme.emerald
                              : (widget.isMatched == false ? AppTheme.rose : Colors.white),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Floating Switch Camera Button (HUD Top-Right Corner, only on live camera)
            if (!hasCapturedPhoto && _availableCameras.length > 1)
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: switchCamera,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cameraswitch_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFrontCamera ? 'FRONT' : 'BACK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 5. Floating Retake / Rescan Button (HUD Top-Right Corner, when photo is captured)
            if (hasCapturedPhoto && widget.onRetake != null)
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      clearCapturedPhoto();
                      widget.onRetake?.call();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: AppTheme.cyan, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'RETAKE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 6. Automated Countdown Overlay (Only on live camera feed, NEVER over captured photo!)
            if (!hasCapturedPhoto && widget.countdownSeconds != null && widget.countdownSeconds! > 0)
              Positioned(
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.cyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.rose,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AUTO-CAPTURE IN ${widget.countdownSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. White Flash Effect on Shutter Snap
            if (_showShutterFlash)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
