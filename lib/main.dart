import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/notification_service.dart';
import 'features/notifications/workmanager_service.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

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

class AnilovApp extends ConsumerWidget {
  const AnilovApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
