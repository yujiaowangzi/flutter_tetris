import 'dart:math';
import 'dart:ui';

Color getRandomColor() {
  return Color.fromARGB(
      200, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
}

extension ImagePath on String{
  String get img=>'images/$this';
}
