import 'package:flutter_test/flutter_test.dart';
import 'package:prism/game/dir.dart';
import 'package:prism/game/level.dart';
import 'package:prism/game/light.dart';
import 'package:prism/game/piece.dart';
import 'package:prism/game/tracer.dart';

Piece source(int x, int y, Dir dir, int mask) =>
    Piece(type: PieceType.source, x: x, y: y, dir: dir, mask: mask);

Piece mirror(int x, int y, {required bool slash}) =>
    Piece(type: PieceType.mirror, x: x, y: y, movable: true, slash: slash);

Piece target(int x, int y, int mask) =>
    Piece(type: PieceType.target, x: x, y: y, mask: mask);

void main() {
  group('Dir', () {
    test('slash mirror reflections', () {
      expect(Dir.right.reflectSlash, Dir.up);
      expect(Dir.up.reflectSlash, Dir.right);
      expect(Dir.left.reflectSlash, Dir.down);
      expect(Dir.down.reflectSlash, Dir.left);
    });

    test('backslash mirror reflections', () {
      expect(Dir.right.reflectBackslash, Dir.down);
      expect(Dir.down.reflectBackslash, Dir.right);
      expect(Dir.left.reflectBackslash, Dir.up);
      expect(Dir.up.reflectBackslash, Dir.left);
    });

    test('turns', () {
      expect(Dir.right.turnLeft, Dir.up);
      expect(Dir.right.turnRight, Dir.down);
      expect(Dir.up.turnLeft, Dir.left);
      expect(Dir.up.turnRight, Dir.right);
    });
  });

  group('tracer', () {
    test('beam reaches a target in a straight line', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        target(4, 2, Light.red),
      ]);
      final result = trace(board);
      expect(result.won, isTrue);
    });

    test('mirror redirects the beam', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        mirror(2, 2, slash: true),
        target(2, 0, Light.red),
      ]);
      expect(trace(board).won, isTrue);
    });

    test('filter strips a white beam to one primary', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.white),
        Piece(type: PieceType.filter, x: 2, y: 2, mask: Light.green),
        target(4, 2, Light.green),
      ]);
      expect(trace(board).won, isTrue);
    });

    test('filter kills a beam with no matching component', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        Piece(type: PieceType.filter, x: 2, y: 2, mask: Light.blue),
        target(4, 2, Light.red),
      ]);
      final result = trace(board);
      expect(result.won, isFalse);
      expect(result.received.values.single, 0);
    });

    test('prism splits white into three primaries', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.white),
        Piece(type: PieceType.prism, x: 2, y: 2),
        target(4, 2, Light.red), // straight through
        target(2, 0, Light.green), // left of travel
        target(2, 4, Light.blue), // right of travel
      ]);
      final result = trace(board);
      expect(result.won, isTrue);
    });

    test('two beams mix additively at a target', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        source(2, 0, Dir.down, Light.blue),
        target(2, 2, Light.magenta),
      ]);
      expect(trace(board).won, isTrue);
    });

    test('a target lit with the wrong color does not win', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.white),
        target(4, 2, Light.red),
      ]);
      final result = trace(board);
      expect(result.won, isFalse);
      expect(result.received.values.single, Light.white);
    });

    test('walls absorb beams', () {
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        Piece(type: PieceType.wall, x: 2, y: 2),
        target(4, 2, Light.red),
      ]);
      expect(trace(board).won, isFalse);
    });

    test('ignored piece is treated as absent', () {
      final blocker = mirror(2, 2, slash: true);
      final board = Board(5, 5, [
        source(0, 2, Dir.right, Light.red),
        blocker,
        target(4, 2, Light.red),
      ]);
      expect(trace(board).won, isFalse);
      expect(trace(board, ignore: blocker).won, isTrue);
    });
  });

  group('levels are solvable', () {
    // Placements (x, y, slash) for each level's movable mirrors, in the order
    // the mirrors appear in the level definition.
    final solutions = <String, List<(int, int, bool)>>{
      'First Light': [(3, 3, true)],
      'Double Bounce': [(4, 1, false), (4, 5, false)],
      'Red Shift': [(5, 3, true)],
      'Split Decision': [(3, 1, true), (3, 7, false)],
      'Better Together': [(6, 2, false), (6, 6, true)],
      'Grand Finale': [(3, 0, true), (3, 8, false), (6, 4, true)],
    };

    for (final level in levels) {
      test(level.name, () {
        final solution = solutions[level.name];
        expect(solution, isNotNull,
            reason: 'missing solution for ${level.name}');

        final board = Board.fromLevel(level);
        final movable =
            board.pieces.where((p) => p.movable).toList(growable: false);
        expect(movable.length, solution!.length);

        expect(trace(board).won, isFalse,
            reason: 'level must not start solved');

        for (final (i, placement) in solution.indexed) {
          final (x, y, slash) = placement;
          final occupant = board.at(x, y);
          expect(occupant == null || occupant == movable[i], isTrue,
              reason: 'solution cell ($x,$y) is occupied');
          movable[i]
            ..x = x
            ..y = y
            ..slash = slash;
        }
        expect(trace(board).won, isTrue);
      });
    }
  });
}
