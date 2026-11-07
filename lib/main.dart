import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anilov/core/router/app_router.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/auth/presentation/providers/auth_provider.dart';
import 'package:anilov/features/notifications/notification_service.dart';
import 'package:anilov/features/notifications/workmanager_service.dart';
import 'package:anilov/features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications and background workers safely
  try {
    await NotificationService.instance.init();
    await WorkmanagerService.instance.init();
  } catch (e) {
    debugPrint('Background service initialization: $e');
  }

  runApp(
    const ProviderScope(
      child: AnilovApp(),
    ),
  );
}

class AnilovApp extends ConsumerStatefulWidget {
  const AnilovApp({super.key});

  @override
  ConsumerState<AnilovApp> createState() => _AnilovAppState();
}

class _AnilovAppState extends ConsumerState<AnilovApp> {
  @override
  void initState() {
    super.initState();
    try {
      ref.read(oauthServiceProvider).listenForRedirects(
        onTokenReceived: (token) {
          ref.read(authNotifierProvider.notifier).loginWithToken(token);
        },
        onError: (err) {
          debugPrint('OAuth redirect: $err');
        },
      );
    } catch (e) {
      debugPrint('Deep link listener initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Anilov',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
