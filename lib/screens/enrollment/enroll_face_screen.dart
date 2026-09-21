import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/face_provider.dart';
import '../../providers/settings_provider.dart';
import 'biometric_onboarding_wizard.dart';

class EnrollFaceScreen extends StatefulWidget {
  const EnrollFaceScreen({super.key});

  @override
  State<EnrollFaceScreen> createState() => _EnrollFaceScreenState();
}

class _EnrollFaceScreenState extends State<EnrollFaceScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String _selectedAngle = 'front';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      Provider.of<FaceProvider>(context, listen: false).fetchEnrolledFaces(currentUserId: user?.id);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 98,
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();

      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppTheme.rose),
        );
      }
    }
  }

  Future<void> _handleEnroll() async {
    if (_selectedImage == null && _imageBytes == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final faceProvider = Provider.of<FaceProvider>(context, listen: false);

    final success = await faceProvider.enrollFace(
      filePath: kIsWeb ? null : _selectedImage?.path,
      fileBytes: _imageBytes,
      fileName: _selectedImage?.name ?? 'enrolled_face.jpg',
      faceLabel: _selectedAngle,
      currentUserId: auth.currentUser?.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faceProvider.successMessage ?? 'Face vector enrolled!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faceProvider.errorMessage ?? 'Enrollment failed'),
          backgroundColor: AppTheme.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final faceProvider = context.watch<FaceProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Face Enrollment'),
      ),
      body: RefreshIndicator(
        onRefresh: () => faceProvider.fetchEnrolledFaces(currentUserId: user?.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.cyan),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload clear front and angled photos (30° left/right) to maximize recognition accuracy.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5-Angle AI Calibration Wizard Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '5-Angle Face Calibration',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Capture 5 diverse angles (Front, Left 30°, Right 30°, Chin Up 15°, Smile) with live AI HUD guidance for ~99.8% precision.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard()),
                          );
                          faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Start 5-Angle AI Calibration', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Upload / Capture Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enroll New Photo Sample', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 14),

                    // Preview Box
                    if (_imageBytes != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryLight),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.6)),
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                            }),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppTheme.borderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryLight),
                              label: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppTheme.borderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, color: AppTheme.cyan),
                              label: const Text('From Gallery', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Angle Selector
                    const Text('Pose / Angle View:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _AngleChip(
                          label: 'Front View',
                          value: 'front',
                          selected: _selectedAngle == 'front',
                          onTap: () => setState(() => _selectedAngle = 'front'),
                        ),
                        const SizedBox(width: 8),
                        _AngleChip(
                          label: 'Left (30°)',
                          value: 'left',
                          selected: _selectedAngle == 'left',
                          onTap: () => setState(() => _selectedAngle = 'left'),
                        ),
                        const SizedBox(width: 8),
                        _AngleChip(
                          label: 'Right (30°)',
                          value: 'right',
                          selected: _selectedAngle == 'right',
                          onTap: () => setState(() => _selectedAngle = 'right'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_imageBytes == null || faceProvider.isLoading) ? null : _handleEnroll,
                        child: faceProvider.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Extract & Enroll 512-D Vector'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Currently Enrolled Faces Header
              Text(
                'Enrolled Angles (${faceProvider.faces.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              if (faceProvider.faces.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text('No biometric faces enrolled yet.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ...faceProvider.faces.map(
                  (face) {
                    final fullImageUrl = face.imageUrl.startsWith('http')
                        ? face.imageUrl
                        : '${settings.baseUrl}${face.imageUrl}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              fullImageUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 54,
                                height: 54,
                                color: Colors.black,
                                child: const Icon(Icons.broken_image, color: AppTheme.textDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        face.faceLabel.toUpperCase(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('512-D ArcFace', style: TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(face.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.card,
                                  title: const Text('Delete Face Sample?'),
                                  content: Text('Are you sure you want to remove the ${face.faceLabel} face vector?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppTheme.rose)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                faceProvider.deleteFace(face.id);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AngleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _AngleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.cardHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
