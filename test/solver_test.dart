import 'package:flutter_test/flutter_test.dart';
import 'package:prism/game/level.dart';
import 'package:prism/game/solver.dart';

void main() {
  group('declared pars are exactly optimal', () {
    for (final level in levels) {
      test('${level.name} (par ${level.par})', () {
        expect(minMoves(level), level.par);
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });
}
