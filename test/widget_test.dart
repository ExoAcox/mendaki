import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/main.dart';

void main() {
  testWidgets('MendakiApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MendakiApp());
    expect(find.text('Mendaki'), findsWidgets);
  });
}
