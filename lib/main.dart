import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/wakanda_theme.dart';
import 'theme/wakanda_theme.dart';
import 'models/exercise_type.dart';
import 'services/pose_detection_service.dart';
import 'screens/dashboard_screen.dart';
import 'providers/app_providers.dart'; // Import providers
import 'screens/app_selection_screen.dart';
import 'screens/lock_overlay_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ActivLockApp()));
}

class ActivLockApp extends ConsumerStatefulWidget {
  const ActivLockApp({super.key});

  @override
  ConsumerState<ActivLockApp> createState() => _ActivLockAppState();
}

class _ActivLockAppState extends ConsumerState<ActivLockApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _channel = MethodChannel('com.activlock/native');

  @override
  void initState() {
    super.initState();
    _configureMethodChannel();
  }

  void _configureMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "navigateToLockScreen") {
        final packageName = call.arguments as String?;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/lock_screen',
                (route) => false,
            arguments: packageName
        );
      }
    });

    // Check if we missed a lock request during startup
    _checkPendingLockRequest();
  }

  Future<void> _checkPendingLockRequest() async {
    try {
      final String? pendingPackage = await _channel.invokeMethod('getPendingLockedPackage');
      if (pendingPackage != null && pendingPackage.isNotEmpty) {
        debugPrint("Found pending lock request for: $pendingPackage");
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/lock_screen',
                (route) => false,
            arguments: pendingPackage
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to check pending lock: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'ActivLock',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: WakandaTheme.lightTheme,
      darkTheme: WakandaTheme.themeData, // Original Wakanda Dark
      navigatorKey: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const DashboardScreen());
        }
        else if (settings.name == '/app_selection') {
          return MaterialPageRoute(builder: (_) => const AppSelectionScreen());
        }
        else if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
        else if (settings.name == '/lock_screen') {
          final args = settings.arguments;
          final packageName = args is String ? args : null;
          return MaterialPageRoute(builder: (_) => LockOverlayScreen(lockedPackageName: packageName));
        }
        else if (settings.name == '/workout') {
          final args = settings.arguments;
          String? packageName;
          ExerciseType type = ExerciseType.squat;

          if (args is Map<String, dynamic>) {
            packageName = args['package'];
            if (args['type'] is ExerciseType) {
              type = args['type'];
            }
          } else if (args is String) {
            packageName = args;
          }

          return MaterialPageRoute(builder: (_) => WorkoutScreen(
              lockedPackageName: packageName,
              exerciseType: type
          ));
        }
        return null;
      },
    );
  }
}
