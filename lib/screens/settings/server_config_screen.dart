import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_dialogs.dart';
import '../../providers/settings_provider.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TtsService _tts = TtsService();

  String _currentPreset = 'female';
  String _currentLanguage = 'en-US';
  double _currentPitch = 1.15;
  double _currentRate = 0.48;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _urlController.text = settings.baseUrl;

    _currentPreset = _tts.preset;
    _currentLanguage = _tts.language;
    _currentPitch = _tts.pitch;
    _currentRate = _tts.rate;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _selectVoicePreset(String preset) async {
    await _tts.applyPreset(preset);
    setState(() {
      _currentPreset = _tts.preset;
      _currentLanguage = _tts.language;
      _currentPitch = _tts.pitch;
      _currentRate = _tts.rate;
    });
    await _tts.testCurrentVoice();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings & AI Voice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. AI VOICE ASSISTANT SETTINGS =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.08),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: AppTheme.cyan, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Voice Customization',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              'Select gender, accent, pitch & speech rate',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'Choose Voice Persona:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 10),

                  // Voice Persona Selector Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VoicePersonaChip(
                        icon: Icons.face_3_rounded,
                        label: '👩 Female Assistant',
                        subtitle: 'Sweet & Crisp',
                        isSelected: _currentPreset == 'female',
                        onTap: () => _selectVoicePreset('female'),
                      ),
                      _VoicePersonaChip(
                        icon: Icons.face_6_rounded,
                        label: '👨 Jarvis Male',
                        subtitle: 'Deep & Officer',
                        isSelected: _currentPreset == 'male',
                        onTap: () => _selectVoicePreset('male'),
                      ),
                      _VoicePersonaChip(
                        icon: Icons.smart_toy_rounded,
                        label: '🤖 Cyber Bot',
                        subtitle: 'Sci-Fi Robot',
                        isSelected: _currentPreset == 'robot',
                        onTap: () => _selectVoicePreset('robot'),
                      ),
                      _VoicePersonaChip(
                        icon: Icons.translate_rounded,
                        label: '🇮🇳 Hindi AI (हिंदी)',
                        subtitle: 'शुद्ध हिंदी आवाज़',
                        isSelected: _currentPreset == 'hindi',
                        onTap: () => _selectVoicePreset('hindi'),
                      ),
                      _VoicePersonaChip(
                        icon: Icons.language_rounded,
                        label: '🇮🇳 Indian English',
                        subtitle: 'Indian Accent',
                        isSelected: _currentPreset == 'indian_en',
                        onTap: () => _selectVoicePreset('indian_en'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Language Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voice Language:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: DropdownButton<String>(
                          value: _currentLanguage,
                          dropdownColor: AppTheme.surface,
                          underline: const SizedBox(),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'en-US', child: Text('English (US) 🇺🇸', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'en-IN', child: Text('English (India) 🇮🇳', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'hi-IN', child: Text('Hindi (हिंदी) 🇮🇳', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await _tts.updateConfig(language: val);
                              setState(() {
                                _currentLanguage = val;
                              });
                              await _tts.testCurrentVoice();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Voice Pitch Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voice Pitch (Awaaz):',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Text(
                        _currentPitch < 0.9 ? 'Deep / Heavy' : (_currentPitch > 1.2 ? 'High / Sweet' : 'Balanced'),
                        style: const TextStyle(fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _currentPitch,
                    min: 0.5,
                    max: 1.8,
                    divisions: 13,
                    activeColor: AppTheme.cyan,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() {
                        _currentPitch = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      await _tts.updateConfig(pitch: val);
                      await _tts.testCurrentVoice();
                    },
                  ),

                  // Speech Rate Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Speech Speed (Raftaar):',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Text(
                        _currentRate < 0.45 ? 'Slow & Calm' : (_currentRate > 0.55 ? 'Fast' : 'Normal'),
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _currentRate,
                    min: 0.3,
                    max: 0.8,
                    divisions: 10,
                    activeColor: AppTheme.primaryLight,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() {
                        _currentRate = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      await _tts.updateConfig(rate: val);
                      await _tts.testCurrentVoice();
                    },
                  ),

                  const SizedBox(height: 8),

                  // Test Audio Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyan.withValues(alpha: 0.15),
                        foregroundColor: AppTheme.cyan,
                        side: const BorderSide(color: AppTheme.cyan),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _tts.testCurrentVoice(),
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      label: const Text(
                        '🔊 Test AI Voice / Awaaz Sunein',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= 2. BACKEND SERVER SETTINGS =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dns_rounded, color: AppTheme.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Django REST Gateway',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              'Configure backend host & port',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Server Base URL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. http://192.168.0.237:8000',
                      prefixIcon: Icon(Icons.link_rounded, color: AppTheme.cyan),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Quick Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetChip(
                        label: '⚡ USB Direct (Recommended): 127.0.0.1:8000',
                        onTap: () => _urlController.text = ApiEndpoints.localhostBaseUrl,
                      ),
                      _PresetChip(
                        label: '📶 PC Wi-Fi: 192.168.0.237:8000',
                        onTap: () => _urlController.text = ApiEndpoints.lanBaseUrl,
                      ),
                      _PresetChip(
                        label: '📱 Android Emulator: 10.0.2.2:8000',
                        onTap: () => _urlController.text = ApiEndpoints.emulatorBaseUrl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: settings.isPinging
                              ? null
                              : () async {
                                  await settings.testConnection(_urlController.text);
                                },
                          icon: settings.isPinging
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check_rounded, color: AppTheme.cyan),
                          label: const Text('Test Ping', style: TextStyle(color: AppTheme.cyan)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.cyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await settings.setBaseUrl(_urlController.text);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Server URL updated!'),
                                  backgroundColor: AppTheme.emerald,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save URL'),
                        ),
                      ),
                    ],
                  ),
                  if (settings.pingSuccess != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: settings.pingSuccess!
                            ? AppTheme.emerald.withValues(alpha: 0.12)
                            : AppTheme.rose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: settings.pingSuccess! ? AppTheme.emerald : AppTheme.rose,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            settings.pingSuccess! ? Icons.check_circle_rounded : Icons.error_rounded,
                            color: settings.pingSuccess! ? AppTheme.emerald : AppTheme.rose,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.pingSuccess!
                                      ? 'Connected (${settings.pingLatency}ms latency)'
                                      : 'Connection Failed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: settings.pingSuccess! ? AppTheme.emerald : AppTheme.rose,
                                  ),
                                ),
                                if (settings.pingMessage != null)
                                  Text(
                                    settings.pingMessage!,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= 3. LOG OUT BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.rose.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.rose,
                  side: const BorderSide(color: AppTheme.rose),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => showLogoutConfirmationDialog(context),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.rose),
                label: const Text(
                  'Log Out of VisionAI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onTap,
    );
  }
}

class _VoicePersonaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoicePersonaChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyan.withValues(alpha: 0.18) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.cyan : AppTheme.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.cyan : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? AppTheme.cyan : AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
