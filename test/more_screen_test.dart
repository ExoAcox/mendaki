import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/config/app_config.dart';
import 'package:mendaki/screens/more_screen.dart';

void main() {
  group('MoreScreen Widget Tests', () {
    testWidgets('renders GitHub link, description, and Feedback button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );

      // Verify app header info
      expect(find.text('Mendaki'), findsOneWidget);
      expect(find.text('v${AppConfig.currentVersion}'), findsOneWidget);

      // Verify GitHub card and description
      expect(find.text('GitHub Repository'), findsOneWidget);
      expect(find.text('https://github.com/ExoAcox/mendaki'), findsOneWidget);
      expect(
        find.textContaining('Aplikasi panduan dan navigasi jalur pendakian gunung'),
        findsOneWidget,
      );

      // Verify Feedback section and button
      expect(find.text('Kirim Masukan & Request'), findsWidgets);
      expect(find.byKey(const Key('more_feedback_button')), findsOneWidget);

      // Verify Attribution section
      expect(find.text('Data & Atribusi'), findsOneWidget);
    });
  });
}
