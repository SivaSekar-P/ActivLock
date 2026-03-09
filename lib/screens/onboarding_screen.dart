import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: "Welcome to ActivLock",
      description: "Secure your apps with a healthy twist. Unlock them through physical challenges.",
      icon: Icons.lock_person,
      color: AppTheme.mySystemBlue,
    ),
    OnboardingItem(
      title: "Choose Your Challenge",
      description: "Pick from Squats, Pushups, or Steps. Your body is the only key.",
      icon: Icons.fitness_center,
      color: AppTheme.mySystemPurple,
    ),
    OnboardingItem(
      title: "Usage Control",
      description: "Set strict usage timers. Once the 'Protocol' ends, the app locks again automatically.",
      icon: Icons.timer,
      color: AppTheme.mySystemRed,
    ),
    OnboardingItem(
      title: "Stay Accountable",
      description: "Track your daily activity progress directly on your dashboard.",
      icon: Icons.dashboard_customize,
      color: AppTheme.mySystemBlue,
    ),
  ];

  void _finish() async {
    await ref.read(settingsServiceProvider).setOnboardingCompleted(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 100, color: item.color),
                          const SizedBox(height: 48),
                          Text(
                            item.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Indicator
                    Row(
                      children: List.generate(
                        _items.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppTheme.mySystemBlue : Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Action Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mySystemBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                        ),
                        onPressed: () {
                          if (_currentPage < _items.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        child: Text(
                          _currentPage == _items.length - 1 ? "GET STARTED" : "NEXT",
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
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

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
