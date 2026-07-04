/// The four grid directions a beam can travel. Screen coordinates: y grows
/// downward, so [up] is (0, -1).
enum Dir {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const Dir(this.dx, this.dy);

  final int dx;
  final int dy;

  Dir get turnLeft => Dir.values[(index + 3) % 4];
  Dir get turnRight => Dir.values[(index + 1) % 4];

  /// Reflection off a `/` mirror (bottom-left to top-right diagonal).
  Dir get reflectSlash => switch (this) {
        Dir.right => Dir.up,
        Dir.up => Dir.right,
        Dir.left => Dir.down,
        Dir.down => Dir.left,
      };

  /// Reflection off a `\` mirror (top-left to bottom-right diagonal).
  Dir get reflectBackslash => switch (this) {
        Dir.right => Dir.down,
        Dir.down => Dir.right,
        Dir.left => Dir.up,
        Dir.up => Dir.left,
      };
}
