import 'package:flutter_test/flutter_test.dart';
import 'package:prism/main.dart';

void main() {
  testWidgets('app boots into the first level', (tester) async {
    await tester.pumpWidget(const PrismApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('First Light'), findsOneWidget);
    expect(find.text('Level 1 of 6'), findsOneWidget);
  });
}
