import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/wakanda_theme.dart';
import '../theme/wakanda_background.dart';
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
    
    final textColor = isDark ? WakandaTheme.vibranium : Colors.black87;
    final cardColor = isDark ? WakandaTheme.blackMetal : Colors.white;
    final subTextColor = isDark ? Colors.white54 : Colors.grey[700];

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
        backgroundColor: WakandaTheme.herbPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.shield),
        onPressed: () {
          Navigator.pushNamed(context, '/app_selection');
        },
      ),
      body: WakandaBackground(
        child: Column(
          children: [
            if (!_isAccessibilityEnabled)
              InkWell(
                onTap: _openAccessibilitySettings,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: WakandaTheme.beadRed.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Protection Inactive!\nTap here to enable Accessibility Service.",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
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
                      child: Icon(Icons.shield_outlined, size: 64, color: textColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NO ACTIVE PROTOCOLS',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          letterSpacing: 2.0,
                          color: textColor.withOpacity(0.7)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Initiate app lockdown via +', style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, _isAccessibilityEnabled ? 100 : 20, 16, 16),
                itemCount: lockedApps.length,
                itemBuilder: (context, index) {
                  final app = lockedApps[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: BeveledRectangleBorder(
                      side: BorderSide(color: isDark ? WakandaTheme.vibranium.withOpacity(0.2) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.lock, color: WakandaTheme.herbPurple),
                      title: Text(
                        app.appName.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textColor),
                      ),
                      subtitle: Text(app.packageName, style: TextStyle(fontSize: 10, color: subTextColor)),
                      trailing: Icon(Icons.more_vert, color: subTextColor),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AppDetailsSheet(app: app),
                        );
                      },
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