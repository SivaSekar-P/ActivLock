import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../models/locked_app.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'app_configuration_screen.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    // UPDATED: Using named arguments for installed_apps 2.0+
    List<AppInfo> apps = [];
    try {
      apps = await InstalledApps.getInstalledApps(
        withIcon: true,
        excludeSystemApps: false, // We include system apps so we can filter them manually if needed, or lock them
        excludeNonLaunchableApps: true, // Only show apps that can be opened
      );
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }

    final myPackage = 'com.activlock.activ_lock';

    if (mounted) {
      setState(() {
        _installedApps = apps.where((app) => app.packageName != myPackage).toList();
        // Sorting by name (safely handling potential nulls though 2.0+ usually returns non-null strings)
        _installedApps.sort((a, b) => (a.name).compareTo(b.name));
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final lockedApps = ref.watch(lockedAppsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = AppTheme.mySystemBlue;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('TARGET SELECTION', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: AppBackground( // Use App Background
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.mySystemBlue))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16), 
          itemCount: _installedApps.length,
          itemBuilder: (context, index) {
            final app = _installedApps[index];
            final isLocked = lockedApps.any((a) => a.packageName == app.packageName);
            final displayName = app.name;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GlassContainer(
                blur: 15,
                padding: const EdgeInsets.all(4),
                borderColor: isLocked ? borderColor : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                child: ListTile(
                  leading: app.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(app.icon!, width: 44, height: 44),
                        )
                      : const Icon(Icons.android, color: AppTheme.mySystemBlue, size: 44),
                  title: Text(
                      displayName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
                      )
                  ),
                  subtitle: Text(app.packageName, style: TextStyle(fontSize: 12, color: subTextColor)),
                  trailing: Switch(
                    value: isLocked,
                    activeColor: AppTheme.mySystemBlue,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  onChanged: (val) {
                    if (val) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppConfigurationScreen(
                            packageName: app.packageName,
                            appName: displayName,
                          ),
                        ),
                      );
                    } else {
                      ref.read(lockedAppsProvider.notifier).removeApp(app.packageName);
                    }
                  },
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}