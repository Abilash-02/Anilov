import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app animated splash screen displaying the ANIZEN branding splash image.
/// Determines whether to direct the user to Onboarding or directly to the Home tab.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _checkNextScreen();
  }

  Future<void> _checkNextScreen() async {
    // Ensure splash is visible for at least 1200ms for smooth user experience
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (!mounted) return;
      if (hasSeenOnboarding) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } catch (_) {
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/anizen_splash.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
