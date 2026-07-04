import 'dir.dart';

enum PieceType { source, mirror, prism, filter, target, wall }

class Piece {
  Piece({
    required this.type,
    required this.x,
    required this.y,
    this.movable = false,
    this.dir = Dir.right,
    this.slash = true,
    this.mask = 0,
  });

  final PieceType type;
  int x;
  int y;

  /// Whether the player can drag this piece to another cell.
  final bool movable;

  /// Emission direction (sources only).
  final Dir dir;

  /// Mirror orientation: true for `/`, false for `\`.
  bool slash;

  /// Meaning depends on [type]: emitted color for sources, passed color for
  /// filters, required color for targets. Unused otherwise.
  final int mask;

  bool get rotatable => type == PieceType.mirror;

  void rotate() {
    if (rotatable) slash = !slash;
  }

  Piece clone() => Piece(
        type: type,
        x: x,
        y: y,
        movable: movable,
        dir: dir,
        slash: slash,
        mask: mask,
      );
}
