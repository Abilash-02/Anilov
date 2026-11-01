import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/anilov_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      icon: Icons.movie_filter_outlined,
      title: 'Discover Anime',
      description:
          'Explore trending, seasonal, and top-rated anime backed by official AniList metadata and official trailers.',
    ),
    _OnboardingItem(
      icon: Icons.bookmark_added_outlined,
      title: 'Track Every Episode',
      description:
          'Keep your watchlist organized with episode tracking, statuses, and offline-first storage. No account required.',
    ),
    _OnboardingItem(
      icon: Icons.calendar_month_outlined,
      title: 'Stay on Schedule',
      description:
          'Check daily broadcast releases converted automatically to your device\'s local time zone so you never miss a premiere.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {
      // Degrade gracefully if storage fails
    }
    if (mounted) {
      context.go('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar with Logo and Skip Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AnilovLogo(size: 32, fontSize: 18),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkOnSurfaceMuted
                            : AppTheme.lightOnSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.deepIndigo.withValues(alpha: 0.25),
                            border: Border.all(
                              color: AppTheme.violet.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 56,
                            color: AppTheme.violetLight,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppTheme.darkOnSurfaceMuted
                                : AppTheme.lightOnSurfaceMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicators & Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: isActive ? 28.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.violet
                          : (isDark
                              ? const Color(0xFF2E2E38)
                              : const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
