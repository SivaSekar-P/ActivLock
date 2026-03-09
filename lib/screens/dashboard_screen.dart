import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'app_details_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAllPermissions();
      });
    }
  }

  Future<void> _checkAllPermissions() async {
    final statusOverlay = await Permission.systemAlertWindow.status;
    if (!statusOverlay.isGranted) {
      await Permission.systemAlertWindow.request();
    }

    final isEnabled = await ref.read(appLockServiceProvider).isAccessibilityServiceEnabled();

    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = isEnabled;
      });
    }
  }

  void _openAccessibilitySettings() async {
    await ref.read(appLockServiceProvider).openAccessibilitySettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please find 'ActivLock' and turn it ON")),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockedApps = ref.watch(lockedAppsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ACTIVLOCK PROTOCOL', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.mySystemBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/app_selection');
        },
      ),
      body: AppBackground(
        child: Column(
          children: [
            if (!_isAccessibilityEnabled)
              InkWell(
                onTap: _openAccessibilitySettings,
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  child: GlassContainer(
                    blur: 20,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    borderColor: AppTheme.mySystemRed.withOpacity(0.5),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.mySystemRed, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Protection Inactive!\nTap here to enable Accessibility Service.",
                            style: TextStyle(color: AppTheme.mySystemRed, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppTheme.mySystemRed, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

            Expanded(
              child: lockedApps.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: textColor.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.lock_outline, size: 64, color: textColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Locked Apps',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap the + button to lock an app', style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, _isAccessibilityEnabled ? 100 : 20, 16, 16),
                itemCount: lockedApps.length,
                itemBuilder: (context, index) {
                  final app = lockedApps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      blur: 15,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.mySystemBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock, color: AppTheme.mySystemBlue, size: 20),
                        ),
                        title: Text(
                          app.appName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                        ),
                        subtitle: Text(app.packageName, style: TextStyle(fontSize: 12, color: subTextColor)),
                        trailing: Icon(Icons.chevron_right, color: subTextColor),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => AppDetailsSheet(app: app),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}