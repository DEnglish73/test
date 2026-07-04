import 'dart:ui';

import 'dir.dart';
import 'level.dart';
import 'light.dart';
import 'piece.dart';

/// A straight run of light between two points, in cell coordinates
/// (a cell's center is at x + 0.5, y + 0.5).
class BeamSegment {
  const BeamSegment(this.a, this.b, this.mask);

  final Offset a;
  final Offset b;
  final int mask;
}

class TraceResult {
  const TraceResult(this.segments, this.received, this.won);

  final List<BeamSegment> segments;

  /// Accumulated color mask per target piece.
  final Map<Piece, int> received;

  final bool won;
}

class _Ray {
  const _Ray(this.x, this.y, this.dir, this.mask);

  final int x;
  final int y;
  final Dir dir;
  final int mask;
}

/// Propagates light from every source across [board].
///
/// [ignore] is treated as absent from the board — used while the player is
/// dragging a piece, so the preview shows the board without it.
TraceResult trace(Board board, {Piece? ignore}) {
  final segments = <BeamSegment>[];
  final received = <Piece, int>{
    for (final p in board.pieces)
      if (p.type == PieceType.target && p != ignore) p: 0,
  };

  Piece? at(int x, int y) {
    final p = board.at(x, y);
    return p == ignore ? null : p;
  }

  Offset center(int x, int y) => Offset(x + 0.5, y + 0.5);

  final queue = <_Ray>[
    for (final p in board.pieces)
      if (p.type == PieceType.source && p != ignore)
        _Ray(p.x, p.y, p.dir, p.mask),
  ];
  // Guards against beam cycles: a ray is identified by its emission state.
  final visited = <String>{};

  while (queue.isNotEmpty) {
    final ray = queue.removeLast();
    if (ray.mask == 0) continue;
    if (!visited.add('${ray.x},${ray.y},${ray.dir},${ray.mask}')) continue;

    var cx = ray.x;
    var cy = ray.y;
    while (true) {
      final nx = cx + ray.dir.dx;
      final ny = cy + ray.dir.dy;
      if (!board.inBounds(nx, ny)) {
        // Run off the edge of the grid.
        final edge = center(cx, cy) +
            Offset(ray.dir.dx * 0.5, ray.dir.dy * 0.5);
        segments.add(BeamSegment(center(ray.x, ray.y), edge, ray.mask));
        break;
      }
      final piece = at(nx, ny);
      if (piece == null) {
        cx = nx;
        cy = ny;
        continue;
      }

      segments.add(
        BeamSegment(center(ray.x, ray.y), center(nx, ny), ray.mask),
      );
      switch (piece.type) {
        case PieceType.wall || PieceType.source:
          break; // Absorbed.
        case PieceType.target:
          received[piece] = received[piece]! | ray.mask;
        case PieceType.mirror:
          final out =
              piece.slash ? ray.dir.reflectSlash : ray.dir.reflectBackslash;
          queue.add(_Ray(nx, ny, out, ray.mask));
        case PieceType.filter:
          queue.add(_Ray(nx, ny, ray.dir, ray.mask & piece.mask));
        case PieceType.prism:
          if (ray.mask & Light.red != 0) {
            queue.add(_Ray(nx, ny, ray.dir, Light.red));
          }
          if (ray.mask & Light.green != 0) {
            queue.add(_Ray(nx, ny, ray.dir.turnLeft, Light.green));
          }
          if (ray.mask & Light.blue != 0) {
            queue.add(_Ray(nx, ny, ray.dir.turnRight, Light.blue));
          }
      }
      break;
    }
  }

  final won = received.isNotEmpty &&
      received.entries.every((e) => e.value == e.key.mask);
  return TraceResult(segments, received, won);
}
