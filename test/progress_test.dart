import 'package:flutter_test/flutter_test.dart';
import 'package:prism/services/progress.dart';
import 'package:prism/services/sfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progress.init();
  });

  test('fresh install: only level 0 unlocked, nothing completed', () {
    expect(Progress.completed, isEmpty);
    expect(Progress.isUnlocked(0), isTrue);
    expect(Progress.isUnlocked(1), isFalse);
  });

  test('completing a level unlocks the next and persists', () async {
    await Progress.markCompleted(0);
    expect(Progress.isCompleted(0), isTrue);
    expect(Progress.isUnlocked(1), isTrue);
    expect(Progress.isUnlocked(2), isFalse);

    // Same backing store on re-init.
    await Progress.init();
    expect(Progress.isCompleted(0), isTrue);
  });

  test('completion is idempotent', () async {
    await Progress.markCompleted(3);
    await Progress.markCompleted(3);
    expect(Progress.completed, {3});
  });

  test('stars persist and only improve', () async {
    expect(Progress.starsFor(2), 0);
    await Progress.setStars(2, 2);
    expect(Progress.starsFor(2), 2);
    await Progress.setStars(2, 1); // worse attempt doesn't downgrade
    expect(Progress.starsFor(2), 2);
    await Progress.setStars(2, 3);
    expect(Progress.starsFor(2), 3);
  });

  test('mute setting round-trips', () async {
    expect(Sfx.muted, isFalse);
    await Progress.setMuted(true);
    expect(Sfx.muted, isTrue);
    await Progress.init();
    expect(Sfx.muted, isTrue);
  });
}
