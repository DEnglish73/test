import 'package:flutter/material.dart';

import '../game/level.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _open(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(levelIndex: index)),
    );
    // Refresh completion/lock states after playing.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final done = Progress.completed.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRISM',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 10,
                            color: Color(0xFFF4F6FF),
                          ),
                        ),
                        Text(
                          done == levels.length
                              ? 'every beam has found its home'
                              : 'bend light · $done of ${levels.length} solved',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: Sfx.muted ? 'Unmute' : 'Mute',
                    onPressed: () =>
                        setState(() => Progress.setMuted(!Sfx.muted)),
                    icon:
                        Icon(Sfx.muted ? Icons.volume_off : Icons.volume_up),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: levels.length,
                itemBuilder: (context, i) => _LevelCard(
                  index: i,
                  name: levels[i].name,
                  completed: Progress.isCompleted(i),
                  unlocked: Progress.isUnlocked(i),
                  stars: Progress.starsFor(i),
                  onTap: () => _open(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.index,
    required this.name,
    required this.completed,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final int index;
  final String name;
  final bool completed;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  static const _accent = Color(0xFF57E6C0);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF141927) : const Color(0xFF0F131D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? _accent.withValues(alpha: 0.55)
              : const Color(0xFF232B3D),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: unlocked ? const Color(0xFFF4F6FF) : Colors.white24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked ? name : 'Locked',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: unlocked ? Colors.white70 : Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          if (completed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color:
                        i < stars ? const Color(0xFFFFE14D) : Colors.white24,
                  ),
              ],
            )
          else
            Icon(
              unlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
              size: 20,
              color: unlocked ? Colors.white54 : Colors.white24,
            ),
        ],
      ),
    );

    if (!unlocked) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
