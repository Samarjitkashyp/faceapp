import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/face_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../theme/app_theme.dart';

/// Shows a logout confirmation modal and seamlessly redirects to LoginScreen
Future<void> showLogoutConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: AppTheme.rose),
          SizedBox(width: 10),
          Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Are you sure you want to log out of VisionAI?',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.rose,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    DashboardScreen.hasShownOnboardingPopup = false;
    Provider.of<FaceProvider>(context, listen: false).clear();
    Provider.of<AttendanceProvider>(context, listen: false).clear();
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
