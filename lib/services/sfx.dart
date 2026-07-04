import 'package:audioplayers/audioplayers.dart';

/// Fire-and-forget sound effects.
///
/// Failures are swallowed: audio is nonessential and platform support varies
/// (widget tests have no audio backend at all).
abstract final class Sfx {
  static bool muted = false;

  static final List<AudioPlayer> _pool = [];
  static int _next = 0;

  static void play(String name) {
    if (muted) return;
    Future(() async {
      if (_pool.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer());
        }
      }
      final player = _pool[_next++ % _pool.length];
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'));
    }).catchError((_) {});
  }
}
