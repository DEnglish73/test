import 'level.dart';
import 'tracer.dart';

/// Exhaustively computes the minimum number of moves needed to solve
/// [level], where a move is one relocation of a movable piece or one
/// rotation — the same way the game counts them.
///
/// Iterative deepening over a total move budget: for each budget it
/// enumerates every assignment of (stay | rotate | relocate | both) to the
/// movable pieces whose costs sum within budget, and traces the resulting
/// board. Feasible because pars are small and pruning is aggressive; used
/// by tests to prove the declared pars are exactly optimal.
int minMoves(Level level, {int maxBudget = 8}) {
  final board = Board.fromLevel(level);
  final movables = board.pieces.where((p) => p.movable).toList(growable: false);
  final occupied = <int>{
    for (final p in board.pieces) p.y * board.width + p.x,
  };

  bool search(int i, int remaining) {
    if (i == movables.length) {
      return trace(board, collectSegments: false).won;
    }
    final piece = movables[i];
    final homeX = piece.x;
    final homeY = piece.y;
    final homeSlash = piece.slash;
    final homeKey = homeY * board.width + homeX;

    // Stay put (cost 0).
    if (search(i + 1, remaining)) return true;

    if (remaining >= 1) {
      // Rotate in place (cost 1).
      piece.slash = !homeSlash;
      if (search(i + 1, remaining - 1)) return true;
      piece.slash = homeSlash;

      // Relocate (cost 1), optionally also rotate (cost 2).
      occupied.remove(homeKey);
      for (var y = 0; y < board.height; y++) {
        for (var x = 0; x < board.width; x++) {
          final key = y * board.width + x;
          if (occupied.contains(key)) continue;
          occupied.add(key);
          piece.x = x;
          piece.y = y;
          if (search(i + 1, remaining - 1)) return true;
          if (remaining >= 2) {
            piece.slash = !homeSlash;
            if (search(i + 1, remaining - 2)) return true;
            piece.slash = homeSlash;
          }
          occupied.remove(key);
        }
      }
      piece.x = homeX;
      piece.y = homeY;
      occupied.add(homeKey);
    }
    return false;
  }

  for (var budget = 0; budget <= maxBudget; budget++) {
    if (search(0, budget)) return budget;
  }
  throw StateError('no solution for "${level.name}" within $maxBudget moves');
}
