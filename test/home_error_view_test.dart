import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/screens/home_screen.dart';
import 'package:mendaki/widgets/home/home_error_view.dart';
import 'package:mendaki/widgets/home/home_filter_chips.dart';

void main() {
  group('HomeErrorView Widget Tests', () {
    testWidgets('renders offline title, message, and action buttons', (
      WidgetTester tester,
    ) async {
      bool libraryTapped = false;
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeErrorView(
              isOffline: true,
              downloadedCount: 3,
              onOpenLibrary: () => libraryTapped = true,
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      // Verify offline content
      expect(find.text('Tidak Ada Sinyal'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Buka Library Offline (3)'), findsOneWidget);
      expect(find.text('Coba Muat Ulang'), findsOneWidget);

      // Verify no snackbar
      expect(find.byType(SnackBar), findsNothing);

      // Test library tap
      await tester.tap(find.byKey(const Key('home_error_library_button')));
      expect(libraryTapped, isTrue);

      // Test retry tap
      await tester.tap(find.byKey(const Key('home_error_retry_button')));
      expect(retryTapped, isTrue);
    });

    testWidgets(
      'renders server failure state when device is online but query fails',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeErrorView(
                isOffline: false,
                downloadedCount: 0,
                onOpenLibrary: () {},
                onRetry: () {},
              ),
            ),
          ),
        );

        expect(find.text('Gagal Memuat Data'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
        expect(find.text('Buka Library Offline'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });

  group('HomeScreen Offline Integration Tests', () {
    tearDown(() {
      NetworkService.mockIsOnline = null;
    });

    testWidgets(
      'HomeScreen directly renders Global Error UI when device is offline without snackbar',
      (WidgetTester tester) async {
        NetworkService.mockIsOnline = false;

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should render filter chips at the top and error view below them
        expect(find.byType(HomeFilterChips), findsOneWidget);
        expect(find.byType(HomeErrorView), findsOneWidget);
        expect(find.text('Tidak Ada Sinyal'), findsOneWidget);
        expect(find.byKey(const Key('home_error_library_button')), findsOneWidget);

        final filterChipTop = tester.getTopLeft(find.byType(HomeFilterChips)).dy;
        final errorViewTop = tester.getTopLeft(find.byType(HomeErrorView)).dy;
        expect(errorViewTop, greaterThan(filterChipTop));

        // Verify that NO snackbar is shown anywhere
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'HomeScreen opens LibraryScreen when clicking Buka Library Offline in error view',
      (WidgetTester tester) async {
        NetworkService.mockIsOnline = false;

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(HomeErrorView), findsOneWidget);

        // Tap on library button
        final btnFinder = find.byKey(const Key('home_error_library_button'));
        final btn = tester.widget<FilledButton>(btnFinder);
        btn.onPressed?.call();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Should navigate to LibraryScreen
        expect(find.text('Library'), findsOneWidget);
      },
    );
  });
}
