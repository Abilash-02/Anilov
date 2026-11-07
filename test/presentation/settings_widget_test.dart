import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/profile/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen renders appearance, notifications, disclaimer, and content options',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // App Bar
    expect(find.text('Settings'), findsOneWidget);

    // Appearance & Theme Mode SegmentedButton
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    // Daily Updates & Notifications
    expect(find.text('Daily Updates & Notifications'), findsOneWidget);
    expect(find.text('Daily Broadcast Reminders'), findsOneWidget);
    expect(find.text('Reminder Time'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);

    // WorkManager Timing Disclaimer Note
    expect(
      find.textContaining('Daily background checks run via Android WorkManager'),
      findsOneWidget,
    );

    // Adult Content Filter (isAdult: false by default)
    expect(find.text('Adult Content Filter'), findsOneWidget);
    expect(
      find.textContaining('isAdult: false by default'),
      findsOneWidget,
    );

    // Storage & Cache
    expect(find.text('Clear Image & Data Cache'), findsOneWidget);
  });
}
