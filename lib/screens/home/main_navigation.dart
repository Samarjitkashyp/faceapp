import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/face_provider.dart';
import '../attendance/attendance_history_screen.dart';
import '../enrollment/biometric_onboarding_wizard.dart';
import '../enrollment/enroll_face_screen.dart';
import '../recognition/live_scan_screen.dart';
import '../settings/server_config_screen.dart';
import 'dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    if (index == 1) {
      final faceProv = Provider.of<FaceProvider>(context, listen: false);
      if (!faceProv.isFullyCalibrated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              faceProv.faces.isEmpty
                  ? 'Biometric Check-In is locked! Please calibrate 5 face angles first.'
                  : 'Biometric Check-In is locked! Please complete all 5 angles (${faceProv.faces.length}/5).',
            ),
            backgroundColor: AppTheme.rose,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BiometricOnboardingWizard(isMandatory: true)),
        ).then((_) {
          if (mounted) {
            final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
            Provider.of<FaceProvider>(context, listen: false).fetchEnrolledFaces(currentUserId: user?.id);
          }
        });
        return;
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigateTab: _switchTab);
      case 1:
        return const LiveScanScreen();
      case 2:
        return const EnrollFaceScreen();
      case 3:
        return const AttendanceHistoryScreen();
      case 4:
        return const ServerConfigScreen();
      default:
        return DashboardScreen(onNavigateTab: _switchTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1220),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.face_outlined),
              activeIcon: Icon(Icons.face_retouching_natural_rounded),
              label: 'Live Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint_outlined),
              activeIcon: Icon(Icons.fingerprint_rounded),
              label: 'Face Vectors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
