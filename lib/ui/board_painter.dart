import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/light.dart';
import '../game/piece.dart';
import '../game/tracer.dart';

/// Maps between grid cells and screen coordinates. Shared by the painter and
/// the gesture handlers so hit-testing always agrees with rendering.
class BoardGeometry {
  BoardGeometry(Size size, this.cols, this.rows) {
    cell = math.min(size.width / cols, size.height / rows);
    origin = Offset(
      (size.width - cell * cols) / 2,
      (size.height - cell * rows) / 2,
    );
  }

  final int cols;
  final int rows;
  late final double cell;
  late final Offset origin;

  Rect get bounds =>
      Rect.fromLTWH(origin.dx, origin.dy, cell * cols, cell * rows);

  Offset cellCenter(int x, int y) =>
      origin + Offset((x + 0.5) * cell, (y + 0.5) * cell);

  Rect cellRect(int x, int y) =>
      Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);

  ({int x, int y})? cellAt(Offset local) {
    final x = ((local.dx - origin.dx) / cell).floor();
    final y = ((local.dy - origin.dy) / cell).floor();
    if (x < 0 || x >= cols || y < 0 || y >= rows) return null;
    return (x: x, y: y);
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.board,
    required this.result,
    required Animation<double> pulse,
    this.dragging,
    this.dragPos,
  })  : _pulse = pulse,
        super(repaint: pulse);

  final Board board;
  final TraceResult result;
  final Animation<double> _pulse;
  final Piece? dragging;
  final Offset? dragPos;

  /// 0..1 breathing value derived from the repeating controller.
  double get _breath =>
      0.5 + 0.5 * math.sin(_pulse.value * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(size, board.width, board.height);
    _paintBackdrop(canvas, g);
    _paintBeams(canvas, g);
    for (final p in board.pieces) {
      if (p == dragging) continue;
      _paintPiece(canvas, g, p, g.cellRect(p.x, p.y));
    }
    _paintDrag(canvas, g);
  }

  void _paintBackdrop(Canvas canvas, BoardGeometry g) {
    final panel = RRect.fromRectAndRadius(
      g.bounds.inflate(g.cell * 0.15),
      Radius.circular(g.cell * 0.3),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xFF10141E));
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF232B3D),
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var x = 1; x < g.cols; x++) {
      final dx = g.origin.dx + x * g.cell;
      canvas.drawLine(
        Offset(dx, g.bounds.top),
        Offset(dx, g.bounds.bottom),
        line,
      );
    }
    for (var y = 1; y < g.rows; y++) {
      final dy = g.origin.dy + y * g.cell;
      canvas.drawLine(
        Offset(g.bounds.left, dy),
        Offset(g.bounds.right, dy),
        line,
      );
    }
  }

  void _paintBeams(Canvas canvas, BoardGeometry g) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      g.bounds.inflate(g.cell * 0.15),
      Radius.circular(g.cell * 0.3),
    ));
    for (final s in result.segments) {
      final a = g.origin + s.a * g.cell;
      final b = g.origin + s.b * g.cell;
      final color = Light.colorOf(s.mask);

      final halo = Paint()
        ..color = color.withValues(alpha: 0.30 + 0.15 * _breath)
        ..strokeWidth = g.cell * 0.30
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.12);
      canvas.drawLine(a, b, halo);

      final core = Paint()
        ..color = color
        ..strokeWidth = g.cell * 0.085
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;
      canvas.drawLine(a, b, core);

      final hot = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = g.cell * 0.028
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;
      canvas.drawLine(a, b, hot);
    }
    canvas.restore();
  }

  void _paintPiece(Canvas canvas, BoardGeometry g, Piece p, Rect r) {
    if (p.movable) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.deflate(g.cell * 0.06),
          Radius.circular(g.cell * 0.16),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.05),
      );
    }
    switch (p.type) {
      case PieceType.source:
        _paintSource(canvas, g, p, r);
      case PieceType.mirror:
        _paintMirror(canvas, g, p, r);
      case PieceType.prism:
        _paintPrism(canvas, g, r);
      case PieceType.filter:
        _paintFilter(canvas, g, p, r);
      case PieceType.target:
        _paintTarget(canvas, g, p, r);
      case PieceType.wall:
        _paintWall(canvas, g, r);
    }
  }

  void _paintSource(Canvas canvas, BoardGeometry g, Piece p, Rect r) {
    final color = Light.colorOf(p.mask);
    final c = r.center;
    canvas.drawCircle(
      c,
      g.cell * 0.36,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.15),
    );
    canvas.drawCircle(c, g.cell * 0.27, Paint()..color = const Color(0xFF1B2130));
    canvas.drawCircle(
      c,
      g.cell * 0.27,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.06
        ..color = color,
    );
    canvas.drawCircle(c, g.cell * 0.12, Paint()..color = color);

    // Emission notch pointing along the beam direction.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.atan2(p.dir.dy.toDouble(), p.dir.dx.toDouble()));
    final notch = Path()
      ..moveTo(g.cell * 0.30, -g.cell * 0.10)
      ..lineTo(g.cell * 0.44, 0)
      ..lineTo(g.cell * 0.30, g.cell * 0.10)
      ..close();
    canvas.drawPath(notch, Paint()..color = color);
    canvas.restore();
  }

  void _paintMirror(Canvas canvas, BoardGeometry g, Piece p, Rect r) {
    final inset = g.cell * 0.20;
    final Offset a;
    final Offset b;
    if (p.slash) {
      a = Offset(r.left + inset, r.bottom - inset);
      b = Offset(r.right - inset, r.top + inset);
    } else {
      a = Offset(r.left + inset, r.top + inset);
      b = Offset(r.right - inset, r.bottom - inset);
    }
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFFAEBEE0)
        ..strokeWidth = g.cell * 0.11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = g.cell * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintPrism(Canvas canvas, BoardGeometry g, Rect r) {
    final c = r.center;
    final h = g.cell * 0.30;
    final path = Path()
      ..moveTo(c.dx, c.dy - h)
      ..lineTo(c.dx - h, c.dy + h * 0.85)
      ..lineTo(c.dx + h, c.dy + h * 0.85)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.05
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // A hint of the spectrum inside.
    final base = c.dy + h * 0.55;
    for (final (i, mask) in Light.primaries.indexed) {
      canvas.drawLine(
        Offset(c.dx - h * 0.35 + i * h * 0.35, base - h * 0.25),
        Offset(c.dx - h * 0.45 + i * h * 0.35, base),
        Paint()
          ..color = Light.colorOf(mask)
          ..strokeWidth = g.cell * 0.04
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintFilter(Canvas canvas, BoardGeometry g, Piece p, Rect r) {
    final color = Light.colorOf(p.mask);
    final rr = RRect.fromRectAndRadius(
      r.deflate(g.cell * 0.24),
      Radius.circular(g.cell * 0.12),
    );
    canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.22));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.05
        ..color = color,
    );
  }

  void _paintTarget(Canvas canvas, BoardGeometry g, Piece p, Rect r) {
    final want = Light.colorOf(p.mask);
    final got = result.received[p] ?? 0;
    final lit = got == p.mask;
    final c = r.center;

    if (lit) {
      canvas.drawCircle(
        c,
        g.cell * (0.38 + 0.06 * _breath),
        Paint()
          ..color = want.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.18),
      );
    }
    canvas.drawCircle(c, g.cell * 0.30, Paint()..color = const Color(0xFF161B28));
    canvas.drawCircle(
      c,
      g.cell * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.cell * 0.065
        ..color = lit ? want : want.withValues(alpha: 0.55),
    );
    if (got != 0) {
      canvas.drawCircle(
        c,
        g.cell * 0.16,
        Paint()..color = Light.colorOf(got).withValues(alpha: lit ? 1 : 0.45),
      );
    } else {
      canvas.drawCircle(
        c,
        g.cell * 0.16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = want.withValues(alpha: 0.35),
      );
    }
  }

  void _paintWall(Canvas canvas, BoardGeometry g, Rect r) {
    final rr = RRect.fromRectAndRadius(
      r.deflate(g.cell * 0.10),
      Radius.circular(g.cell * 0.14),
    );
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF242B3B));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF3B4560),
    );
  }

  void _paintDrag(Canvas canvas, BoardGeometry g) {
    final p = dragging;
    final pos = dragPos;
    if (p == null || pos == null) return;

    final hover = g.cellAt(pos);
    if (hover != null) {
      final occupied = board.at(hover.x, hover.y) != null &&
          board.at(hover.x, hover.y) != p;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          g.cellRect(hover.x, hover.y).deflate(g.cell * 0.04),
          Radius.circular(g.cell * 0.16),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = occupied
              ? const Color(0xFFFF5D6E)
              : const Color(0xFF57E6C0),
      );
    }

    final r = Rect.fromCenter(
      center: pos,
      width: g.cell,
      height: g.cell,
    );
    canvas.drawCircle(
      pos,
      g.cell * 0.5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.15),
    );
    _paintPiece(canvas, g, p, r);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.result != result ||
      oldDelegate.dragging != dragging ||
      oldDelegate.dragPos != dragPos;
}
