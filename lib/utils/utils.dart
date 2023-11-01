import 'dart:math';
import 'dart:ui';

Color getRandomColor() {
  return Color.fromARGB(
      200, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
}
