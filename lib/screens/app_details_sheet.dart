import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../providers/app_providers.dart';
import '../theme/wakanda_theme.dart';
import 'app_configuration_screen.dart';

class AppDetailsSheet extends ConsumerWidget {
  final LockedApp app;

  const AppDetailsSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final cardColor = isDark ? WakandaTheme.onyx : Colors.grey.shade200;
    final sheetColor = isDark ? WakandaTheme.blackMetal : Colors.white;

    final remainingUnlocks = app.dailyUnlockLimit - app.usedUnlocks;
    final remainingExceptions = app.dailyExceptions - app.usedExceptions; // Optional to show?

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: WakandaTheme.herbPurple, width: 2)),
      ),
      child: SafeArea(
        child: SingleChildScrollView( // Changed to ScrollView in case of small screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   // ... (Header content remains same, just ensuring context)
                   const Icon(Icons.security, color: WakandaTheme.herbLight, size: 30),
                   const SizedBox(width: 15),
                   Expanded(
                     child: Text(
                       app.appName.toUpperCase(),
                       style: TextStyle(
                         color: textColor,
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.2,
                       ),
                     ),
                   ),
                   IconButton(
                     icon: Icon(Icons.close, color: subTextColor),
                     onPressed: () => Navigator.pop(context),
                   )
                ],
              ),
              const SizedBox(height: 20),
              
              // STATS GRID
              Row(
                children: [
                  _StatCard(
                    label: "UNLOCKS LEFT", 
                    value: "$remainingUnlocks / ${app.dailyUnlockLimit}", 
                    icon: Icons.lock_open, 
                    bgColor: cardColor, 
                    textColor: textColor
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: "WORKOUT", 
                    value: "${app.targetReps} ${app.exerciseType.name.toUpperCase()}S", 
                    icon: Icons.fitness_center, 
                    bgColor: cardColor, 
                    textColor: textColor
                  ),
                ],
              ),
              
              // Optional: Show Emergency Stat separately or small text?
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Emergency Bypasses Remaining: $remainingExceptions / ${app.dailyExceptions}",
                  style: TextStyle(color: subTextColor, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),

              const SizedBox(height: 20),

              // ACTIONS
              Text("CONFIGURE PROTOCOLS", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              _buildActionTile(
                context,
                icon: Icons.pin,
                title: "Change PIN",
                subtitle: "Update access code",
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () => _openConfig(context, 0),
              ),
              
              _buildActionTile(
                context,
                icon: Icons.directions_run,
                title: "Edit Workout",
                subtitle: "Change exercise or reps",
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () => _openConfig(context, 1),
              ),

              _buildActionTile(
                context,
                icon: Icons.timer,
                title: "Usage & Limits",
                subtitle: "Daily opens & emergency",
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () => _openConfig(context, 2),
              ),
              
              Divider(color: isDark ? Colors.white10 : Colors.black12, height: 30),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_forever, color: Colors.redAccent),
                ),
                title: const Text("Remove Lock", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: Text("Disable protection for this app", style: TextStyle(color: subTextColor)),
                onTap: () {
                  ref.read(lockedAppsProvider.notifier).removeApp(app.packageName);
                  Navigator.pop(context);
                },
              ),
              
              const SizedBox(height: 40), // Extra bottom padding for safety
            ],
          ),
        ),
      ),
    );
  }

  void _openConfig(BuildContext context, int step) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppConfigurationScreen(
          packageName: app.packageName,
          appName: app.appName,
          initialStep: step,
          isEditing: true, // Enable Single Step Edit
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color textColor, required Color subTextColor, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: WakandaTheme.herbPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: WakandaTheme.herbPurple, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color textColor;

  const _StatCard({
    required this.label, 
    required this.value, 
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: WakandaTheme.herbPurple, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
