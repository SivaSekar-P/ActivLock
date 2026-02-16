import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../models/locked_app.dart';
import '../providers/app_providers.dart';
import '../theme/wakanda_theme.dart';
import '../theme/wakanda_background.dart';
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
    final textColor = isDark ? WakandaTheme.vibranium : Colors.black87;
    final cardColor = isDark ? WakandaTheme.onyx : Colors.white;
    final borderColor = isDark ? WakandaTheme.herbPurple : Colors.deepPurple;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('TARGET SELECTION', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: WakandaBackground( // Use Wakanda Background
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: WakandaTheme.herbPurple))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 100, left: 8, right: 8, bottom: 8), // Padding for transparent appbar?
          itemCount: _installedApps.length,
          itemBuilder: (context, index) {
            final app = _installedApps[index];
            final isLocked = lockedApps.any((a) => a.packageName == app.packageName);
            final displayName = app.name;

            return Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: isLocked ? borderColor : Colors.transparent,
                    width: 0.5
                ),
              ),
              child: ListTile(
                leading: app.icon != null
                    ? Image.memory(app.icon!, width: 40, height: 40)
                    : const Icon(Icons.android, color: WakandaTheme.vibranium),
                title: Text(
                    displayName,
                    style: TextStyle(
                      color: isLocked ? borderColor : textColor,
                      fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                    )
                ),
                subtitle: Text(app.packageName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                trailing: Switch(
                  value: isLocked,
                  activeColor: WakandaTheme.herbPurple,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[800],
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
            );
          },
        ),
      ),
    );
  }
}