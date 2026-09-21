import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AiScannerOverlay extends StatefulWidget {
  final bool isScanning;
  final bool? isMatched; // null = idle/scanning, true = verified, false = rejected
  final bool isCaptured; // true when showing static captured photo
  final double width;
  final double height;

  const AiScannerOverlay({
    super.key,
    required this.isScanning,
    this.isMatched,
    this.isCaptured = false,
    this.width = 240,
    this.height = 300,
  });

  @override
  State<AiScannerOverlay> createState() => _AiScannerOverlayState();
}

class _AiScannerOverlayState extends State<AiScannerOverlay> with TickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _scanStatusTexts = [
    'ALIGN FACE WITHIN TARGET',
    'DETECTING FACIAL CONTOURS...',
    'ANALYZING 5-POINT LANDMARKS...',
    'EXTRACTING 512-D VECTOR...',
    'CROSS-MATCHING BIOMETRIC DATABASE...',
  ];
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();

    // Laser Beam Animation (Traverses top to bottom smoothly)
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Rotating Radar Reticle Animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulse Animation for outer target glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Cycle status ticker when scanning
    _laserController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        if (mounted && widget.isScanning) {
          setState(() {
            _statusIndex = (_statusIndex + 1) % _scanStatusTexts.length;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _themeColor {
    if (widget.isMatched == true) return AppTheme.emerald;
    if (widget.isMatched == false) return AppTheme.rose;
    return AppTheme.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Concentric Rotating Cyber Reticle (Only when live feed before capture, NEVER when photo is captured)
          if (!widget.isCaptured)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _CyberReticlePainter(color: _themeColor.withValues(alpha: 0.25)),
                  ),
                );
              },
            ),

          // 2. Biometric Oval Boundary (Pulses on live camera; steady solid lock when photo is captured)
          widget.isCaptured
              ? Container(
                  width: widget.width * 0.85,
                  height: widget.height * 0.85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(widget.width * 0.85, widget.height * 0.85),
                    ),
                    border: Border.all(
                      color: _themeColor,
                      width: 2.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _themeColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
              : ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: widget.width * 0.85,
                    height: widget.height * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(widget.width * 0.85, widget.height * 0.85),
                      ),
                      border: Border.all(
                        color: _themeColor.withValues(alpha: 0.8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

          // 3. Four Futuristic Corner Target Brackets (HUD Lock)
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _TargetBracketsPainter(
              color: _themeColor,
              bracketLength: 26,
              strokeWidth: 3.5,
            ),
          ),

          // 4. Sweeping Holographic Laser Line (Only on live feed, completely disabled when photo is captured!)
          if (!widget.isCaptured && (widget.isScanning || widget.isMatched == null))
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                final topPos = widget.height * _laserAnimation.value;
                return Positioned(
                  top: topPos,
                  left: widget.width * 0.08,
                  right: widget.width * 0.08,
                  child: Column(
                    children: [
                      // Upper soft glow plume
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _themeColor.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                      // Core bright neon laser beam
                      Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: _themeColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: _themeColor,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Lower soft glow plume
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _themeColor.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 5. Simulated Facial Landmark Mesh Points (Only when live scanning, NOT when photo is captured)
          if (!widget.isCaptured && widget.isScanning)
            _FacialMeshPoints(
              color: _themeColor,
              width: widget.width * 0.8,
              height: widget.height * 0.8,
            ),

          // 6. Subtle Center AI Processing Badge (When photo is captured and uploading/vectorizing)
          if (widget.isCaptured && widget.isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyan, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ANALYZING 512-D VECTOR...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

          // 7. Bottom HUD Status Ticker
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _themeColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _themeColor, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isMatched == true
                        ? 'BIOMETRIC LOCK CONFIRMED ✓'
                        : widget.isMatched == false
                            ? 'MATCH FAILED / UNKNOWN'
                            : widget.isScanning
                                ? (widget.isCaptured ? 'PROCESSING EMBEDDING...' : _scanStatusTexts[_statusIndex])
                                : (widget.isCaptured ? 'PHOTO CAPTURED • LOCKED' : 'AI RECOGNITION ACTIVE'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: _themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Futuristic Corner Target Brackets
class _TargetBracketsPainter extends CustomPainter {
  final Color color;
  final double bracketLength;
  final double strokeWidth;

  _TargetBracketsPainter({
    required this.color,
    required this.bracketLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = bracketLength;

    // Top-Left Corner
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);

    // Top-Right Corner
    canvas.drawLine(Offset(w, 0), Offset(w - l, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), paint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(0, h), Offset(l, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - l), paint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(w, h), Offset(w - l, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), paint);
  }

  @override
  bool shouldRepaint(covariant _TargetBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// Custom Painter for Rotating Radar Ticks & Arcs
class _CyberReticlePainter extends CustomPainter {
  final Color color;

  _CyberReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;

    // Draw 4 cardinal tick marks
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final p1 = Offset(center.dx + (radius - 8) * math.cos(angle), center.dy + (radius - 8) * math.sin(angle));
      final p2 = Offset(center.dx + (radius + 8) * math.cos(angle), center.dy + (radius + 8) * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// 5-Point Biometric Nodes (Eyes, Nose, Mouth Landmarks)
class _FacialMeshPoints extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _FacialMeshPoints({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cx = width / 2;
    final cy = height / 2;

    return IgnorePointer(
      child: Stack(
        children: [
          // Left Eye Node
          Positioned(left: cx - 38, top: cy - 35, child: _NodeDot(color: color)),
          // Right Eye Node
          Positioned(left: cx + 38, top: cy - 35, child: _NodeDot(color: color)),
          // Nose Tip Node
          Positioned(left: cx, top: cy, child: _NodeDot(color: color)),
          // Left Mouth Node
          Positioned(left: cx - 28, top: cy + 42, child: _NodeDot(color: color)),
          // Right Mouth Node
          Positioned(left: cx + 28, top: cy + 42, child: _NodeDot(color: color)),
        ],
      ),
    );
  }
}

class _NodeDot extends StatelessWidget {
  final Color color;
  const _NodeDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}
