import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/piece.dart';
import '../game/tracer.dart';
import 'board_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  int _levelIndex = 0;
  late Board _board;
  late TraceResult _result;

  Piece? _dragging;
  Offset? _dragPos;

  Level get _level => levels[_levelIndex];
  bool get _lastLevel => _levelIndex == levels.length - 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _loadLevel(int index) {
    _levelIndex = index;
    _board = Board.fromLevel(levels[index]);
    _dragging = null;
    _dragPos = null;
    _retrace();
  }

  void _retrace() {
    _result = trace(_board, ignore: _dragging);
  }

  void _onTapUp(TapUpDetails details, BoardGeometry g) {
    if (_result.won) return;
    final cell = g.cellAt(details.localPosition);
    if (cell == null) return;
    final piece = _board.at(cell.x, cell.y);
    if (piece == null || !piece.rotatable) return;
    setState(() {
      piece.rotate();
      _retrace();
    });
  }

  void _onPanStart(DragStartDetails details, BoardGeometry g) {
    if (_result.won) return;
    final cell = g.cellAt(details.localPosition);
    if (cell == null) return;
    final piece = _board.at(cell.x, cell.y);
    if (piece == null || !piece.movable) return;
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
                              dragging: _dragging,
                              dragPos: _dragPos,
                            ),
                          ),
                        ),
                        if (_result.won) _buildWinOverlay(),
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
            tooltip: 'Previous level',
            onPressed: _levelIndex > 0
                ? () => setState(() => _loadLevel(_levelIndex - 1))
                : null,
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
                  'Level ${_levelIndex + 1} of ${levels.length}',
                  style: style.bodySmall?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reset level',
            onPressed: () => setState(() => _loadLevel(_levelIndex)),
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
            const Text('✨', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              _lastLevel ? 'All levels complete!' : 'Level complete!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => setState(
                () => _loadLevel(_lastLevel ? 0 : _levelIndex + 1),
              ),
              child: Text(_lastLevel ? 'Play again' : 'Next level'),
            ),
          ],
        ),
      ),
    );
  }
}
