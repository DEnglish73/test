import 'dart:ui';

/// Light colors are bitmasks over the three additive primaries, so mixing two
/// beams at a target is a bitwise OR and filtering is a bitwise AND.
abstract final class Light {
  static const int red = 1;
  static const int green = 2;
  static const int blue = 4;
  static const int yellow = red | green;
  static const int magenta = red | blue;
  static const int cyan = green | blue;
  static const int white = red | green | blue;

  static const List<int> primaries = [red, green, blue];

  static Color colorOf(int mask) => switch (mask) {
        Light.red => const Color(0xFFFF4D5E),
        Light.green => const Color(0xFF4DF07A),
        Light.blue => const Color(0xFF4DA6FF),
        Light.yellow => const Color(0xFFFFE14D),
        Light.magenta => const Color(0xFFE85DFF),
        Light.cyan => const Color(0xFF4DFFF0),
        Light.white => const Color(0xFFF4F6FF),
        _ => const Color(0xFF222222),
      };

  static String nameOf(int mask) => switch (mask) {
        Light.red => 'red',
        Light.green => 'green',
        Light.blue => 'blue',
        Light.yellow => 'yellow',
        Light.magenta => 'magenta',
        Light.cyan => 'cyan',
        Light.white => 'white',
        _ => 'dark',
      };
}
