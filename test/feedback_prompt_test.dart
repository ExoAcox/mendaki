import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/widgets/home/feedback_modal.dart';
import 'package:mendaki/widgets/home/feedback_prompt.dart';

void main() {
  group('FeedbackPrompt Widget Tests', () {
    testWidgets('renders default title and button label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackPrompt(),
          ),
        ),
      );

      expect(find.text('Gunung belum tersedia?'), findsOneWidget);
      expect(find.text('Request di sini'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    testWidgets('renders custom title and button label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackPrompt(
              title: 'Jalur belum tersedia?',
              buttonLabel: 'Kirim Request',
            ),
          ),
        ),
      );

      expect(find.text('Jalur belum tersedia?'), findsOneWidget);
      expect(find.text('Kirim Request'), findsOneWidget);
    });

    testWidgets('tapping button opens FeedbackModal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackPrompt(),
          ),
        ),
      );

      await tester.tap(find.text('Request di sini'));
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackModal), findsOneWidget);
    });
  });
}

