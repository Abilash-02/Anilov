import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/profile/presentation/about_screen.dart';

void main() {
  testWidgets('AboutScreen renders app version, legal boundaries, and source attributions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Version
    expect(find.text('About & Attribution'), findsOneWidget);
    expect(
      find.text('Version 1.0.0 (RUN 5 — Daily Updates & Polish)'),
      findsOneWidget,
    );

    // Legal Boundaries
    expect(find.text('Legal Boundaries & Policy'), findsOneWidget);
    expect(
      find.textContaining('Anilov strictly adheres to authorized sources only'),
      findsOneWidget,
    );

    // Data Sources & Attributions
    expect(find.text('Data Sources & Attribution'), findsOneWidget);
    expect(find.text('AniList GraphQL API'), findsOneWidget);
    expect(find.text('ani.zip Community Service'), findsOneWidget);
    expect(find.text('YouTube & Google'), findsOneWidget);

    // Open Source Technologies
    expect(find.text('Open Source Technologies'), findsOneWidget);
    expect(find.textContaining('flutter_riverpod'), findsOneWidget);
  });
}
