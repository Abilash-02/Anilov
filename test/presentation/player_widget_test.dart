import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/player/presentation/local_player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LocalPlayerScreen renders empty state, instructions, and picker button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LocalPlayerScreen(),
        ),
      ),
    );

    // Header & Empty State Title
    expect(find.text('Local Media Player'), findsWidgets);
    expect(find.byIcon(Icons.video_collection_outlined), findsOneWidget);

    // Descriptive explanation
    expect(
      find.textContaining('Play your own legally acquired video files'),
      findsOneWidget,
    );

    // Primary action button
    expect(find.text('Select Video File'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open_rounded), findsWidgets);

    // Supported formats note
    expect(
      find.textContaining('Supports MP4, MKV, WebM'),
      findsOneWidget,
    );
  });
}
