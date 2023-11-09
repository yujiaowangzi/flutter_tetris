import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/utils/log/logger.dart';

class BatteryStoreView extends StatelessWidget {
  BatteryStoreView({
    super.key,
    this.energyShowCount = 4,
    this.energyBarWidth = 6,
    this.energyEmptyColor = Colors.black12,
    this.energyColor = Colors.orange,
  });

  Color energyColor;
  Color energyEmptyColor;
  int energyShowCount;
  double energyBarWidth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _Painter(
          energyShowCount: energyShowCount,
          energyColor: energyColor,
          energyBarSize: energyBarWidth,
          energyEmptyColor: energyEmptyColor,
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({
    required this.energyColor,
    required this.energyEmptyColor,
    required this.energyShowCount,
    required this.energyBarSize,
  });

  final _paint = Paint();
  late int energyTotalCount;

  Color energyColor;
  Color energyEmptyColor;
  double energyBarSize;
  int energyShowCount;

  late double haftStorkWidth;

  @override
  void paint(Canvas canvas, Size size) {
    var height = size.height;
    var width = size.width;

    energyTotalCount = height ~/ energyBarSize;
    if (energyTotalCount&1==1) {//基数，变为偶数
      energyTotalCount++;
      energyBarSize=height/energyTotalCount;
    }

    var drawBarSize=energyBarSize*2/3;
    var y=energyBarSize/2;

    _paint
      ..strokeWidth = drawBarSize
      ..style = PaintingStyle.fill;

    for (int i = 0; i < energyTotalCount; i++) {
      _paint.color = i < energyTotalCount-energyShowCount ? energyEmptyColor : energyColor;
      canvas.drawLine(Offset(0, y),Offset(width, y), _paint);
      y += energyBarSize;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
