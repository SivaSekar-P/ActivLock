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

    if (!mounted) return;
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
        automaticallyImplyLeading: false,
        title: Text('ACTIVLOCK', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
            Padding(
               padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
               child: _buildDailySummaryCard(context, ref, textColor, subTextColor),
            ),

            if (!_isAccessibilityEnabled)
              InkWell(
                onTap: _openAccessibilitySettings,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

  Widget _buildDailySummaryCard(BuildContext context, WidgetRef ref, Color textColor, Color subTextColor) {
    final statsAsync = ref.watch(dailyStatsProvider);

    return GlassContainer(
      blur: 25,
      padding: const EdgeInsets.all(20),
      child: statsAsync.when(
        data: (stats) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("DAILY SUMMARY", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                const Icon(Icons.auto_graph, color: AppTheme.mySystemBlue, size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Unlocks", "${stats['unlocks']}", Icons.lock_open, AppTheme.mySystemBlue, textColor),
                _buildStatItem("Squats", "${stats['squats']}", Icons.accessibility_new, AppTheme.mySystemGreen, textColor),
                _buildStatItem("Pushups", "${stats['pushups']}", Icons.fitness_center, AppTheme.mySystemPurple, textColor),
                _buildStatItem("Steps", "${stats['steps']}", Icons.directions_walk, Colors.orange, textColor),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, r) => Text("Error loading stats", style: TextStyle(color: subTextColor)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}