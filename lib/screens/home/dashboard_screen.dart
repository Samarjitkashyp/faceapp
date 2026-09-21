import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_dialogs.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/face_provider.dart';
import '../enrollment/biometric_onboarding_wizard.dart';

class DashboardScreen extends StatefulWidget {
  static bool hasShownOnboardingPopup = false;
  final Function(int) onNavigateTab;
  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      await Provider.of<FaceProvider>(context, listen: false).fetchEnrolledFaces(currentUserId: user?.id);
      if (!mounted) return;
      await Provider.of<AttendanceProvider>(context, listen: false).fetchLogs(currentUserId: user?.id);

      if (!mounted) return;
      final faceProv = Provider.of<FaceProvider>(context, listen: false);
      if (!faceProv.isFullyCalibrated && !DashboardScreen.hasShownOnboardingPopup) {
        DashboardScreen.hasShownOnboardingPopup = true;
        _showBiometricSetupPopup(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final faceProvider = context.watch<FaceProvider>();
    final attProvider = context.watch<AttendanceProvider>();

    final hasCheckedIn = attProvider.hasCheckedInToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionAI Command'),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.cyan),
            onPressed: () {
              faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
              attProvider.fetchLogs(currentUserId: user?.id);
            },
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.rose),
            onPressed: () => showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
          await attProvider.fetchLogs(currentUserId: user?.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                      child: Text(
                        (user?.username.isNotEmpty ?? false)
                            ? user!.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? user?.username ?? 'Employee',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.employeeId != null && user!.employeeId!.isNotEmpty
                                ? 'ID: ${user.employeeId} • ${user.role.toUpperCase()}'
                                : user?.email ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.cyan),
                          ),
                          if (user?.address != null && user!.address!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '📍 ${user.address}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KPI Grid
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: "Today's Status",
                      value: hasCheckedIn ? 'Checked In' : 'Pending',
                      icon: hasCheckedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      color: hasCheckedIn ? AppTheme.emerald : AppTheme.amber,
                      subtitle: hasCheckedIn ? 'Verified via Face AI' : 'Scan to check-in',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _KpiCard(
                      title: 'Face Biometrics',
                      value: '${faceProvider.faces.length} Vector(s)',
                      icon: Icons.fingerprint_rounded,
                      color: faceProvider.isFullyCalibrated
                          ? AppTheme.emerald
                          : (faceProvider.hasFaceEnrolled ? AppTheme.amber : AppTheme.rose),
                      subtitle: faceProvider.isFullyCalibrated
                          ? '5 Angles Calibrated (99.8%)'
                          : '5-Angle Setup Required',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // CONDITIONAL HERO CARD:
              // - If 5 angles are calibrated: Show "Biometric Check-In"
              // - If NOT calibrated: Biometric Check-In is LOCKED/HIDDEN, showing "5-Angle Setup Required"
              if (faceProvider.isFullyCalibrated) ...[
                // Active Biometric Check-In Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
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
                              color: AppTheme.emerald.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppTheme.emerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Biometric Check-In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.4)),
                            ),
                            child: const Text('READY', style: TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Align your face in front of the camera to verify identity and record instant timestamped attendance.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primary,
                          ),
                          onPressed: () => widget.onNavigateTab(1), // Tab 1: Live Scan
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Biometric Check In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Locked Biometric Check-In Banner (5-Angle Setup Required)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: faceProvider.faces.isEmpty
                          ? const [Color(0xFF4C0519), Color(0xFF1E0B14)]
                          : const [Color(0xFF451A03), Color(0xFF1E1208)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: faceProvider.faces.isEmpty
                          ? AppTheme.rose.withValues(alpha: 0.7)
                          : AppTheme.amber.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
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
                              color: (faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber).withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Biometric Check-In Locked',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  faceProvider.faces.isEmpty
                                      ? '5-Angle Setup Required'
                                      : 'Calibration Incomplete (${faceProvider.faces.length}/5 Angles)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'LOCKED',
                              style: TextStyle(
                                color: faceProvider.faces.isEmpty ? AppTheme.rose : AppTheme.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        faceProvider.faces.isEmpty
                            ? 'Biometric check-in is not accessible yet. Please complete your 5-Angle Face Calibration to unlock automatic facial recognition and attendance.'
                            : 'You have calibrated ${faceProvider.faces.length} of 5 angles. Please register the remaining ${5 - faceProvider.faces.length} angle(s) to unlock facial check-in.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: faceProvider.faces.isEmpty ? const Color(0xFF881337) : const Color(0xFF78350F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard(isMandatory: true)),
                            );
                            faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                          label: Text(
                            faceProvider.faces.isEmpty
                                ? 'Start 5-Angle Setup Now'
                                : 'Complete 5-Angle Setup (${faceProvider.faces.length}/5)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Secondary Action Buttons:
              // - If calibrated: Do NOT show 5-Angle Setup! Show "Face Vectors (5/5)" and "Logs History".
              // - If NOT calibrated: Show "5-Angle Setup" and "Logs History".
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: faceProvider.isFullyCalibrated ? AppTheme.borderLight : AppTheme.cyan,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppTheme.card,
                      ),
                      onPressed: () async {
                        if (faceProvider.isFullyCalibrated) {
                          // Navigate to Face Vectors Tab (Tab 2)
                          widget.onNavigateTab(2);
                        } else {
                          // Open Wizard for Calibration
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard(isMandatory: true)),
                          );
                          faceProvider.fetchEnrolledFaces(currentUserId: user?.id);
                        }
                      },
                      icon: Icon(
                        faceProvider.isFullyCalibrated ? Icons.fingerprint_rounded : Icons.auto_awesome_rounded,
                        size: 18,
                        color: faceProvider.isFullyCalibrated ? AppTheme.primaryLight : AppTheme.cyan,
                      ),
                      label: Text(
                        faceProvider.isFullyCalibrated
                            ? 'Face Vectors (5/5)'
                            : '5-Angle Setup (${faceProvider.faces.length}/5)',
                        style: TextStyle(
                          color: faceProvider.isFullyCalibrated ? Colors.white : AppTheme.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppTheme.card,
                      ),
                      onPressed: () => widget.onNavigateTab(3), // Tab 3: History
                      icon: const Icon(Icons.history_rounded, size: 18, color: AppTheme.emerald),
                      label: const Text('Logs History', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Logs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Attendance Logs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab(3),
                    child: const Text('View All', style: TextStyle(color: AppTheme.primaryLight, fontSize: 13)),
                  ),
                ],
              ),

              if (attProvider.isLoadingLogs)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (attProvider.logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_note_rounded, size: 40, color: AppTheme.textDark),
                      SizedBox(height: 8),
                      Text('No attendance records logged yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...attProvider.logs.take(3).map(
                  (log) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: (log.isCheckIn ? AppTheme.emerald : AppTheme.amber).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            log.isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                            color: log.isCheckIn ? AppTheme.emerald : AppTheme.amber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.isCheckIn ? 'Verified Check-In' : 'Check-Out',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(log.confidence * 100).toStringAsFixed(0)}% Match',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricSetupPopup(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final faceProvider = Provider.of<FaceProvider>(context, listen: false);
    final count = faceProvider.faces.length;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Biometric Header Icon
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),

                // Top Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        count == 0 ? 'FIRST-TIME SETUP' : 'CALIBRATION ($count/5 ANGLES)',
                        style: const TextStyle(
                          color: AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                const Text(
                  'Face Verification Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Body Description
                Text(
                  count == 0
                      ? 'Welcome to VisionAI! To mark attendance and verify your identity, please complete your 5-Angle Face Setup.'
                      : 'You have calibrated $count of 5 angles. Complete all 5 angles to activate 99.8% accurate face recognition.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 5 Angles preview chips
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '5 Required Angles (Takes 30 seconds):',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: const [
                          _AngleTag(label: '1. Front View'),
                          _AngleTag(label: '2. Left 30°'),
                          _AngleTag(label: '3. Right 30°'),
                          _AngleTag(label: '4. Upward 15°'),
                          _AngleTag(label: '5. Smile'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard(isMandatory: true)),
                      );
                      faceProvider.fetchEnrolledFaces(currentUserId: auth.currentUser?.id);
                    },
                    icon: const Icon(Icons.camera_front_rounded, size: 20, color: Colors.white),
                    label: Text(
                      count == 0 ? 'Start 5-Angle Setup Now' : 'Complete Setup ($count/5)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Setup Later',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AngleTag extends StatelessWidget {
  final String label;
  const _AngleTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
