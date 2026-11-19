import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/widgets/home/feedback_modal.dart';

void main() {
  testWidgets(
      'FeedbackModal displays dropdown, email, textarea, and captcha correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedbackModal(initialType: 'request'),
        ),
      ),
    );

    // Verify header and description
    expect(find.text('Kirim Masukan & Request'), findsOneWidget);
    expect(find.text('Tipe Masukan'), findsOneWidget);
    expect(find.text('Email (Opsional)'), findsOneWidget);
    expect(find.text('Pesan / Keterangan'), findsOneWidget);

    // Verify initial dropdown selection
    expect(find.text('Request Gunung / Rute'), findsOneWidget);

    // Verify textarea placeholder
    expect(
      find.text(
        'Tuliskan nama gunung, jalur pendakian, atau koordinat yang ingin ditambahkan...',
      ),
      findsOneWidget,
    );

    // Verify captcha elements
    expect(find.text('Verifikasi'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Hasil'), findsOneWidget);

    // Verify submit button
    expect(find.widgetWithText(ElevatedButton, 'Kirim'), findsOneWidget);
  });

  testWidgets('FeedbackModal validates empty and wrong captcha',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedbackModal(initialType: 'request'),
        ),
      ),
    );

    // Enter message
    await tester.enterText(
      find.byType(TextFormField).at(1), // comment field (0 is email, 1 is comment, 2 is captcha)
      'Gunung Lawu via Singolangu',
    );

    // Attempt submit with empty captcha
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim'));
    await tester.pump();
    expect(find.text('Isi jawaban'), findsOneWidget);

    // Enter wrong answer
    await tester.enterText(
      find.byType(TextFormField).at(2), // captcha field
      '99999',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim'));
    await tester.pump();
    expect(find.text('Jawaban salah'), findsOneWidget);
  });
}
