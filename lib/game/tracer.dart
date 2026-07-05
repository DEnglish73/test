import 'dart:ui';

import 'dir.dart';
import 'level.dart';
import 'light.dart';
import 'piece.dart';

/// A straight run of light between two points, in cell coordinates
/// (a cell's center is at x + 0.5, y + 0.5).
class BeamSegment {
  const BeamSegment(this.a, this.b, this.mask, this.t0);

  final Offset a;
  final Offset b;
  final int mask;

  /// Distance (in cells) the light has traveled from its source when it
  /// reaches [a]. Lets the painter sweep beams outward over time.
  final double t0;

  double get length => (b - a).distance;
}

class TraceResult {
  const TraceResult(this.segments, this.received, this.won, this.maxDistance);

  final List<BeamSegment> segments;

  /// Accumulated color mask per target piece.
  final Map<Piece, int> received;

  final bool won;

  /// The longest source-to-endpoint distance, for normalizing sweeps.
  final double maxDistance;
}

class _Ray {
  const _Ray(this.x, this.y, this.dir, this.mask, this.dist);

  final int x;
  final int y;
  final Dir dir;
  final int mask;
  final double dist;
}

/// Propagates light from every source across [board].
///
/// [ignore] is treated as absent from the board — used while the player is
/// dragging a piece, so the preview shows the board without it.
/// [collectSegments] can be disabled by callers that only need the outcome
/// (the solver traces thousands of boards).
TraceResult trace(Board board, {Piece? ignore, bool collectSegments = true}) {
  final segments = <BeamSegment>[];
  var maxDistance = 0.0;
  final received = <Piece, int>{
    for (final p in board.pieces)
      if (p.type == PieceType.target && p != ignore) p: 0,
  };

  Piece? at(int x, int y) {
    final p = board.at(x, y);
    return p == ignore ? null : p;
  }

  Offset center(int x, int y) => Offset(x + 0.5, y + 0.5);

  void emit(_Ray ray, int ex, int ey, double extra) {
    final length = (ex - ray.x).abs() + (ey - ray.y).abs() + extra;
    final end = length;
    if (ray.dist + end > maxDistance) maxDistance = ray.dist + end;
    if (collectSegments) {
      final b = extra == 0
          ? center(ex, ey)
          : center(ex, ey) + Offset(ray.dir.dx * extra, ray.dir.dy * extra);
      segments.add(BeamSegment(center(ray.x, ray.y), b, ray.mask, ray.dist));
    }
  }

  final queue = <_Ray>[
    for (final p in board.pieces)
      if (p.type == PieceType.source && p != ignore)
        _Ray(p.x, p.y, p.dir, p.mask, 0),
  ];
  // Guards against beam cycles: a ray is identified by its emission state.
  final visited = <int>{};

  while (queue.isNotEmpty) {
    final ray = queue.removeLast();
    if (ray.mask == 0) continue;
    final key =
        ((ray.y * board.width + ray.x) * 4 + ray.dir.index) * 8 + ray.mask;
    if (!visited.add(key)) continue;

    var cx = ray.x;
    var cy = ray.y;
    while (true) {
      final nx = cx + ray.dir.dx;
      final ny = cy + ray.dir.dy;
      if (!board.inBounds(nx, ny)) {
        // Run off the edge of the grid.
        emit(ray, cx, cy, 0.5);
        break;
      }
      final piece = at(nx, ny);
      if (piece == null) {
        cx = nx;
        cy = ny;
        continue;
      }

      emit(ray, nx, ny, 0);
      final travelled = ray.dist +
          (nx - ray.x).abs().toDouble() +
          (ny - ray.y).abs().toDouble();
      switch (piece.type) {
        case PieceType.wall || PieceType.source:
          break; // Absorbed.
        case PieceType.target:
          received[piece] = received[piece]! | ray.mask;
        case PieceType.mirror:
          final out =
              piece.slash ? ray.dir.reflectSlash : ray.dir.reflectBackslash;
          queue.add(_Ray(nx, ny, out, ray.mask, travelled));
        case PieceType.filter:
          queue.add(_Ray(nx, ny, ray.dir, ray.mask & piece.mask, travelled));
        case PieceType.prism:
          if (ray.mask & Light.red != 0) {
            queue.add(_Ray(nx, ny, ray.dir, Light.red, travelled));
          }
          if (ray.mask & Light.green != 0) {
            queue.add(_Ray(nx, ny, ray.dir.turnLeft, Light.green, travelled));
          }
          if (ray.mask & Light.blue != 0) {
            queue.add(_Ray(nx, ny, ray.dir.turnRight, Light.blue, travelled));
          }
      }
      break;
    }
  }

  final won = received.isNotEmpty &&
      received.entries.every((e) => e.value == e.key.mask);
  return TraceResult(segments, received, won, maxDistance);
}
