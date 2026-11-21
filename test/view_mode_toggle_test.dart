import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:mendaki/widgets/home/view_mode_toggle.dart';

void main() {
  group('ViewModeToggle Widget Tests', () {
    testWidgets('renders detail and simple toggle buttons with correct selection state',
        (WidgetTester tester) async {
      String selectedMode = ViewPreferenceService.viewModeDetail;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ViewModeToggle(
                  currentMode: selectedMode,
                  onModeChanged: (mode) {
                    setState(() {
                      selectedMode = mode;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify both icons exist
      expect(find.byKey(const Key('toggle_mode_detail')), findsOneWidget);
      expect(find.byKey(const Key('toggle_mode_simple')), findsOneWidget);
      expect(find.byIcon(Icons.web), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);

      // Tap simple mode
      await tester.tap(find.byKey(const Key('toggle_mode_simple')));
      await tester.pumpAndSettle();

      expect(selectedMode, ViewPreferenceService.viewModeCompact);

      // Tap detail mode
      await tester.tap(find.byKey(const Key('toggle_mode_detail')));
      await tester.pumpAndSettle();

      expect(selectedMode, ViewPreferenceService.viewModeDetail);
    });
  });
}

