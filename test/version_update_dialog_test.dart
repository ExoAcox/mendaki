import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/config/app_config.dart';
import 'package:mendaki/models/app_version.dart';
import 'package:mendaki/widgets/home/version_update_dialog.dart';

void main() {
  group('AppVersion Model & Comparison Tests', () {
    test('fromJson parses full data correctly', () {
      final json = {
        'id': '1.1',
        'title': 'Mendaki v1.1',
        'desc': '<p><strong>Updates</strong><ul><li>Fitur baru</li></ul></p>',
        'update_link': 'https://example.com/app.apk',
        'force_update': true,
        'created_at': '2026-11-13T06:47:34.951130Z',
      };

      final version = AppVersion.fromJson(json);
      expect(version.id, '1.1');
      expect(version.title, 'Mendaki v1.1');
      expect(version.desc, contains('Fitur baru'));
      expect(version.updateLink, 'https://example.com/app.apk');
      expect(version.forceUpdate, isTrue);
      expect(version.createdAt, isNotNull);
    });

    test('version comparison identifies difference', () {
      const currentVersion = AppConfig.currentVersion; // '1.0'
      const newVersionId = '1.1';

      expect(newVersionId != currentVersion, isTrue);
      expect('1.0' != currentVersion, isFalse);
    });
  });

  group('VersionUpdateDialog Widget Tests', () {
    testWidgets('renders dialog with title, version badge, and parsed HTML changelog',
        (tester) async {
      const version = AppVersion(
        id: '1.1',
        title: 'Mendaki v1.1',
        desc: '<p><strong>Updates</strong><ul><li><strong>GPX Route:</strong> Support route.</li><li>Tap marker to hide.</li></ul></p>',
        forceUpdate: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionUpdateDialog(version: version),
          ),
        ),
      );

      expect(find.text('Mendaki v1.1'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
      expect(find.textContaining('Support route.'), findsOneWidget);
      expect(find.textContaining('Tap marker to hide.'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('forceUpdate hides dismiss button and close icon',
        (tester) async {
      const version = AppVersion(
        id: '1.1',
        title: 'Update Wajib',
        desc: '<p>Update penting diperlukan.</p>',
        forceUpdate: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionUpdateDialog(version: version),
          ),
        ),
      );

      expect(find.text('Update Wajib'), findsOneWidget);
      expect(find.text('Update Sekarang'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('renders all li elements even when some li tags lack closing </li> tag',
        (tester) async {
      const version = AppVersion(
        id: '1.1',
        title: 'Mendaki v1.1',
        desc: '<p><ul>'
            '<li>Item 1</li>'
            '<li>Item 2 unclosed'
            '<li>Item 3</li>'
            '</ul></p>',
        forceUpdate: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionUpdateDialog(version: version),
          ),
        ),
      );

      expect(find.textContaining('Item 1'), findsOneWidget);
      expect(find.textContaining('Item 2 unclosed'), findsOneWidget);
      expect(find.textContaining('Item 3'), findsOneWidget);
    });

    testWidgets('renders line break and vertical spacing for <br> tags',
        (tester) async {
      const version = AppVersion(
        id: '1.1',
        title: 'Mendaki v1.1',
        desc: '<p><span>Updates</span><ul><li>Fitur A</li></ul><br><span>Fixes</span><ul><li>Bug B</li></ul></p>',
        forceUpdate: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionUpdateDialog(version: version),
          ),
        ),
      );

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Fixes'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 12.0,
        ),
        findsOneWidget,
      );
    });
  });
}

