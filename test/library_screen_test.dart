import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/library/offline_storage_bar.dart';

void main() {
  group('LibraryScreen UI Tests', () {
    testWidgets(
      'LibraryScreen renders App Bar with title Library, back button, search bar, offline text, and storage bar',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));

        // Verify App Bar with title 'Mendaki' and back button
        expect(find.text('Mendaki'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

        // Verify search bar without province filter
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.text('Semua'), findsNothing);
        expect(find.text('Jawa Tengah'), findsNothing);

        // Verify offline description text
        expect(
          find.textContaining('tersimpan offline di perangkat'),
          findsOneWidget,
        );

        // Verify offline storage bar below description text
        expect(find.byType(OfflineStorageBar), findsOneWidget);
        expect(find.text('Penyimpanan Offline'), findsOneWidget);

        // Allow initial build
        await tester.pump();
      },
    );

    testWidgets(
      'tapping delete button shows modal with all checkboxes unchecked by default and selecting category shows confirmation dialog on delete',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Temukan tombol delete di OfflineStorageBar
        final deleteBtnFinder = find.byTooltip('Hapus data offline');
        expect(deleteBtnFinder, findsOneWidget);

        // 2. Klik tombol delete untuk membuka modal checkbox
        await tester.tap(deleteBtnFinder);
        await tester.pump(const Duration(milliseconds: 300));

        // Verifikasi modal pemilihan kategori terbuka
        expect(find.text('Hapus Penyimpanan'), findsOneWidget);
        expect(find.text('GPX'), findsOneWidget);
        expect(find.text('Maps'), findsOneWidget);
        expect(find.text('Images'), findsOneWidget);

        // 3. Verifikasi semua checkbox bernilai false secara default (kosong semua)
        final checkboxFinders = find.byType(Checkbox);
        expect(checkboxFinders, findsNWidgets(3));
        for (int i = 0; i < 3; i++) {
          final checkboxWidget = tester.widget<Checkbox>(checkboxFinders.at(i));
          expect(checkboxWidget.value, isFalse);
        }

        // 4. Centang semua kategori sebelum menekan tombol Hapus
        for (int i = 0; i < 3; i++) {
          await tester.tap(checkboxFinders.at(i));
          await tester.pump();
        }

        for (int i = 0; i < 3; i++) {
          final checkboxWidget = tester.widget<Checkbox>(checkboxFinders.at(i));
          expect(checkboxWidget.value, isTrue);
        }

        // 5. Klik tombol "Hapus" pada modal pilihan kategori
        final hapusBtn = find.widgetWithText(InkWell, 'Hapus');
        expect(hapusBtn, findsOneWidget);
        await tester.tap(hapusBtn);
        await tester.pump(const Duration(milliseconds: 300));

        // 6. Verifikasi dialog konfirmasi muncul
        expect(find.text('Konfirmasi Hapus'), findsOneWidget);
        expect(
          find.textContaining('Apakah Anda yakin ingin menghapus'),
          findsOneWidget,
        );
        expect(find.text('Ya, Hapus'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);

        // 6. Klik Batal untuk menutup konfirmasi dialog
        await tester.tap(find.widgetWithText(OutlinedButton, 'Batal'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Konfirmasi Hapus'), findsNothing);
      },
    );
  });
}
