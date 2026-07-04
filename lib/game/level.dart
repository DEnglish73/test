import 'dir.dart';
import 'light.dart';
import 'piece.dart';

class Level {
  const Level({
    required this.name,
    required this.hint,
    required this.width,
    required this.height,
    required this.pieces,
  });

  final String name;
  final String hint;
  final int width;
  final int height;
  final List<Piece> Function() pieces;
}

/// A mutable, playable instance of a level.
class Board {
  Board(this.width, this.height, this.pieces);

  factory Board.fromLevel(Level level) =>
      Board(level.width, level.height, level.pieces());

  final int width;
  final int height;
  final List<Piece> pieces;

  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  Piece? at(int x, int y) {
    for (final p in pieces) {
      if (p.x == x && p.y == y) return p;
    }
    return null;
  }
}

Piece _source(int x, int y, Dir dir, int mask) =>
    Piece(type: PieceType.source, x: x, y: y, dir: dir, mask: mask);

Piece _mirror(int x, int y, {bool slash = true}) =>
    Piece(type: PieceType.mirror, x: x, y: y, movable: true, slash: slash);

Piece _prism(int x, int y) => Piece(type: PieceType.prism, x: x, y: y);

Piece _filter(int x, int y, int mask) =>
    Piece(type: PieceType.filter, x: x, y: y, mask: mask);

Piece _target(int x, int y, int mask) =>
    Piece(type: PieceType.target, x: x, y: y, mask: mask);

Piece _wall(int x, int y) => Piece(type: PieceType.wall, x: x, y: y);

final List<Level> levels = [
  Level(
    name: 'First Light',
    hint: 'Drag the mirror into the beam. Tap it to rotate.',
    width: 7,
    height: 7,
    pieces: () => [
      _source(0, 3, Dir.right, Light.red),
      _target(3, 0, Light.red),
      _mirror(5, 5, slash: false),
    ],
  ),
  Level(
    name: 'Double Bounce',
    hint: 'Two mirrors, one path.',
    width: 7,
    height: 7,
    pieces: () => [
      _source(0, 1, Dir.right, Light.white),
      _target(6, 5, Light.white),
      _mirror(1, 5),
      _mirror(5, 3),
    ],
  ),
  Level(
    name: 'Red Shift',
    hint: 'Filters strip a beam down to one color.',
    width: 7,
    height: 7,
    pieces: () => [
      _source(0, 3, Dir.right, Light.white),
      _filter(3, 3, Light.red),
      _target(5, 0, Light.red),
      _mirror(2, 5, slash: false),
    ],
  ),
  Level(
    name: 'Split Decision',
    hint: 'A prism splits white light: red goes straight, '
        'green turns left, blue turns right.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _prism(3, 4),
      _target(6, 4, Light.red),
      _target(6, 1, Light.green),
      _target(6, 7, Light.blue),
      _mirror(1, 8),
      _mirror(2, 8, slash: false),
    ],
  ),
  Level(
    name: 'Better Together',
    hint: 'Colors mix where beams meet. Red + blue = magenta.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 2, Dir.right, Light.red),
      _source(0, 6, Dir.right, Light.blue),
      _target(6, 4, Light.magenta),
      _mirror(2, 0),
      _mirror(4, 8),
    ],
  ),
  Level(
    name: 'Grand Finale',
    hint: 'Split it, steer it, mix it back together.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _prism(3, 4),
      _target(6, 0, Light.yellow),
      _target(6, 8, Light.blue),
      _wall(1, 1),
      _wall(5, 2),
      _wall(1, 7),
      _wall(5, 6),
      _mirror(1, 0),
      _mirror(1, 8),
      _mirror(5, 4, slash: false),
    ],
  ),
  Level(
    name: 'Crossfire',
    hint: 'Beams pass right through each other.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 1, Dir.right, Light.red),
      _source(0, 7, Dir.right, Light.green),
      _target(3, 8, Light.red),
      _target(5, 0, Light.green),
      _mirror(1, 4),
      _mirror(6, 4),
    ],
  ),
  Level(
    name: 'Cyan Lab',
    hint: 'Two whites, two filters, one cyan.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 2, Dir.right, Light.white),
      _source(0, 6, Dir.right, Light.white),
      _filter(2, 2, Light.green),
      _filter(2, 6, Light.blue),
      _target(5, 4, Light.cyan),
      _mirror(1, 0),
      _mirror(1, 8),
    ],
  ),
  Level(
    name: 'Detour',
    hint: 'No way through — go around.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _target(6, 4, Light.white),
      _wall(3, 2),
      _wall(3, 3),
      _wall(3, 4),
      _wall(3, 5),
      _wall(3, 6),
      _mirror(4, 7),
      _mirror(2, 7, slash: false),
      _mirror(0, 8),
    ],
  ),
  Level(
    name: 'Trichromatic',
    hint: 'Every color needs its own road.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _prism(2, 4),
      _wall(4, 4),
      _target(3, 0, Light.red),
      _target(6, 1, Light.green),
      _target(6, 7, Light.blue),
      _mirror(5, 3),
      _mirror(5, 5, slash: false),
      _mirror(0, 8),
    ],
  ),
  Level(
    name: 'Two of a Kind',
    hint: 'Split the light, then put two colors back together.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _prism(3, 4),
      _target(5, 4, Light.red),
      _target(6, 5, Light.cyan),
      _mirror(1, 2),
      _mirror(1, 6, slash: false),
      _mirror(5, 0, slash: false),
      _mirror(0, 8),
    ],
  ),
  Level(
    name: 'Prism Cascade',
    hint: 'Prisms bend single colors too: green turns left, blue turns right.',
    width: 7,
    height: 9,
    pieces: () => [
      _source(0, 4, Dir.right, Light.white),
      _prism(2, 4),
      _prism(5, 2),
      _wall(5, 4),
      _target(4, 0, Light.red),
      _target(5, 0, Light.green),
      _target(6, 6, Light.blue),
      _mirror(0, 0),
      _mirror(6, 8),
      _mirror(3, 7, slash: false),
    ],
  ),
];
