import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/auth/data/auth_storage.dart';
import 'package:anilov/features/auth/domain/models/anilist_user.dart';
import 'package:anilov/features/auth/presentation/providers/auth_provider.dart';
import 'package:anilov/features/auth/presentation/widgets/connect_anilist_dialog.dart';
import 'package:anilov/features/profile/presentation/profile_screen.dart';
import 'package:anilov/features/profile/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth & Sync UI Widget Tests', () {
    testWidgets('ProfileScreen renders authenticated state with user info and Sync Now',
        (tester) async {
      final fakeStorage = InMemoryAuthStorage();
      await fakeStorage.saveAccessToken('test_token');
      await fakeStorage.saveUser(
        const AniListUser(id: 1234, name: 'AnimeFanatic'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStorageProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AnimeFanatic'), findsOneWidget);
      expect(find.text('AniList Connected • Cloud Sync Active'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('ProfileScreen renders disconnected state with Connect AniList button',
        (tester) async {
      final fakeStorage = InMemoryAuthStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStorageProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anilov User'), findsOneWidget);
      expect(find.text('Local profile • Offline first'), findsOneWidget);
      expect(find.text('Connect AniList Account'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders AniList section with OAuth security notice',
        (tester) async {
      final fakeStorage = InMemoryAuthStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStorageProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AniList Account & Cloud Sync'), findsOneWidget);
      expect(find.text('Connect AniList Account'), findsOneWidget);
      expect(
        find.textContaining('official token authorization flow (anilov://auth)'),
        findsOneWidget,
      );
    });

    testWidgets('ConnectAniListDialog allows toggling between browser OAuth and direct token',
        (tester) async {
      final fakeStorage = InMemoryAuthStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStorageProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: ConnectAniListDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect AniList'), findsOneWidget);
      expect(find.text('AniList Client ID'), findsOneWidget);
      expect(find.text('Connect via Browser'), findsOneWidget);

      // Tap toggle to switch to manual token mode
      await tester.tap(find.text('Developer or Testing? Enter Token Directly'));
      await tester.pumpAndSettle();

      expect(find.text('OAuth Access Token'), findsOneWidget);
      expect(find.text('Submit Token'), findsOneWidget);
    });
  });
}
