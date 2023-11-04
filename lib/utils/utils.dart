import 'dart:math';
import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';

Color getRandomColor() {
  return Color.fromARGB(
      200, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
}

extension AverageWidthHeightSize on int{
  double get c=>(h+w)/2;
}
