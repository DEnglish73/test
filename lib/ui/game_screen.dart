import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/piece.dart';
import '../game/tracer.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import 'board_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelIndex});

  final int levelIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final AnimationController _winFx = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late Board _board;
  late TraceResult _result;
  bool _won = false;
  bool _showOverlay = false;
  int _litCount = 0;

  Piece? _dragging;
  Offset? _dragPos;

  Level get _level => levels[widget.levelIndex];
  bool get _lastLevel => widget.levelIndex == levels.length - 1;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _winFx.dispose();
    super.dispose();
  }

  void _reset() {
    _board = Board.fromLevel(_level);
    _dragging = null;
    _dragPos = null;
    _won = false;
    _showOverlay = false;
    _winFx.reset();
    _result = trace(_board);
    _litCount = _countLit();
  }

  int _countLit() => _result.received.entries
      .where((e) => e.value == e.key.mask && e.key.mask != 0)
      .length;

  void _retrace() {
    _result = trace(_board, ignore: _dragging);
    final lit = _countLit();
    if (_result.won && !_won) {
      _won = true;
      Sfx.play('win');
      _winFx.forward(from: 0);
      Progress.markCompleted(widget.levelIndex);
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted && _won) setState(() => _showOverlay = true);
      });
    } else if (lit > _litCount && !_result.won) {
      Sfx.play('lit');
    }
    _litCount = lit;
  }

  void _onTapUp(TapUpDetails details, BoardGeometry g) {
    if (_won) return;
    final cell = g.cellAt(details.localPosition);
    if (cell == null) return;
    final piece = _board.at(cell.x, cell.y);
    if (piece == null || !piece.rotatable) return;
    Sfx.play('rotate');
    setState(() {
      piece.rotate();
      _retrace();
    });
  }

  void _onPanStart(DragStartDetails details, BoardGeometry g) {
    if (_won) return;
    final cell = g.cellAt(details.localPosition);
    if (cell == null) return;
    final piece = _board.at(cell.x, cell.y);
    if (piece == null || !piece.movable) return;
    Sfx.play('pickup');
    setState(() {
      _dragging = piece;
      _dragPos = details.localPosition;
      _retrace();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragging == null) return;
    setState(() => _dragPos = details.localPosition);
  }

  void _onPanEnd(BoardGeometry g) {
    final piece = _dragging;
    final pos = _dragPos;
    setState(() {
      _dragging = null;
      _dragPos = null;
      if (piece != null && pos != null) {
        final cell = g.cellAt(pos);
        if (cell != null) {
          final occupant = _board.at(cell.x, cell.y);
          if (occupant == null || occupant == piece) {
            if (piece.x != cell.x || piece.y != cell.y) Sfx.play('drop');
            piece.x = cell.x;
            piece.y = cell.y;
          }
        }
      }
      _retrace();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final g = BoardGeometry(
                      constraints.biggest,
                      _board.width,
                      _board.height,
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => _onTapUp(d, g),
                          onPanStart: (d) => _onPanStart(d, g),
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: (_) => _onPanEnd(g),
                          onPanCancel: () => _onPanEnd(g),
                          child: CustomPaint(
                            painter: BoardPainter(
                              board: _board,
                              result: _result,
                              pulse: _pulse,
                              winFx: _winFx,
                              dragging: _dragging,
                              dragPos: _dragPos,
                            ),
                          ),
                        ),
                        if (_showOverlay) _buildWinOverlay(),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Level select',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _level.name,
                  style: style.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Level ${widget.levelIndex + 1} of ${levels.length}',
                  style: style.bodySmall?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: Sfx.muted ? 'Unmute' : 'Mute',
            onPressed: () =>
                setState(() => Progress.setMuted(!Sfx.muted)),
            icon: Icon(Sfx.muted ? Icons.volume_off : Icons.volume_up),
          ),
          IconButton(
            tooltip: 'Reset level',
            onPressed: () => setState(_reset),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Column(
        children: [
          Text(
            _level.hint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drag glowing tiles to move them · Tap a mirror to rotate it',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Transform.scale(
          scale: 0.7 + 0.3 * t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF161C2B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C355A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 40, color: Color(0xFFFFE14D)),
              const SizedBox(height: 8),
              Text(
                _lastLevel ? 'All levels complete!' : 'Level complete!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Levels'),
                  ),
                  if (!_lastLevel) ...[
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              GameScreen(levelIndex: widget.levelIndex + 1),
                        ),
                      ),
                      child: const Text('Next level'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
