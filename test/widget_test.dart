import 'package:flutter_test/flutter_test.dart';
import 'package:dream_achiever/main.dart';

void main() {
  testWidgets('Dream Achiever smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DreamAchieverApp());
    expect(find.byType(DreamAchieverApp), findsOneWidget);
  });
}
