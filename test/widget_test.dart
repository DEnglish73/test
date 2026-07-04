import 'package:flutter_test/flutter_test.dart';
import 'package:prism/main.dart';
import 'package:prism/services/progress.dart';
import 'package:prism/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progress.init();
  });

  testWidgets('level select shows all levels, only the first unlocked',
      (tester) async {
    await tester.pumpWidget(const PrismApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PRISM'), findsOneWidget);
    expect(find.text('First Light'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Locked'), findsNWidgets(11));
  });

  testWidgets('tapping a level opens the game screen', (tester) async {
    await tester.pumpWidget(const PrismApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('First Light'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 1 of 12'), findsOneWidget);
  });

  testWidgets('completed levels unlock their successors', (tester) async {
    SharedPreferences.setMockInitialValues({
      'completed': ['0', '1'],
    });
    await Progress.init();

    await tester.pumpWidget(const PrismApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Red Shift'), findsOneWidget); // level 3 unlocked
    expect(find.text('Locked'), findsNWidgets(9));
  });
}
