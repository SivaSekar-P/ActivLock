import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Logic Flags
  bool _isPinSet = false;
  bool _isLoading = true;

  // Controllers
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  // Visibility Toggles
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await ref.read(settingsServiceProvider).isPinSet();

    if (mounted) {
      setState(() {
        _isPinSet = hasPin;
        _isLoading = false;
      });
    }
  }

  void _handleSavePin() async {
    final settings = ref.read(settingsServiceProvider);

    // Validation
    if (_newPinController.text != _confirmPinController.text) {
      _showSnack("New PINs do not match", isError: true);
      return;
    }
    if (_newPinController.text.length < 4) {
      _showSnack("PIN must be at least 4 digits", isError: true);
      return;
    }
    if (_isPinSet) {
      final isOldCorrect = await settings.verifyPin(_oldPinController.text);
      if (!isOldCorrect) {
        _showSnack("Old PIN is incorrect", isError: true);
        return;
      }
    }

    // Save
    await settings.setPin(_newPinController.text);
    _showSnack("Security Protocol Updated Successfully");

    if (mounted) {
      setState(() {
        _isPinSet = true;
        _oldPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.mySystemRed : AppTheme.mySystemBlue,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final fillColor = isDark ? Colors.grey[900] : Colors.grey[200];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor, letterSpacing: 5),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.mySystemBlue)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: onToggle,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SETTINGS", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: APPEARANCE ---
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  "VISUAL INTERFACE",
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("App Theme", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text("System"), icon: Icon(Icons.brightness_auto)),
                        ButtonSegment(value: ThemeMode.light, label: Text("Light"), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text("Dark"), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref.read(themeProvider.notifier).setTheme(newSelection.first);
                        _showSnack("Theme updated to ${newSelection.first.name.toUpperCase()}");
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.mySystemBlue.withOpacity(0.2);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
