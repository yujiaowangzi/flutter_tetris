import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/utils/log/logger.dart';

class BatteryView extends StatelessWidget {
  BatteryView(
      {super.key,
      this.energyShowCount = 4,
      this.borderColor = Colors.blue,
      this.energyColor = Colors.orange});

  Color borderColor;
  Color energyColor;
  static const int energyTotalCount=4;
  int energyShowCount;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _Painter(
            energyTotalCount: energyTotalCount,
            energyShowCount: energyShowCount,
            borderColor: borderColor,
            energyColor: energyColor),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({
    required this.borderColor,
    required this.energyColor,
    required this.energyTotalCount,
    required this.energyShowCount,
  });

  final strokeWidth = 1.1;
  final headHeightRatio = 1 / 3;
  final headWidthRatio = 0.11;
  final bodyPaddingSize = 1.5;
  final _paint = Paint();

  Color borderColor;
  Color energyColor;
  int energyTotalCount;
  int energyShowCount;

  late double haftStorkWidth;

  @override
  void paint(Canvas canvas, Size size) {
    haftStorkWidth = strokeWidth / 2;
    var height = size.height - strokeWidth;
    var width = size.width - strokeWidth;
    var bodyWidth = (1 - headWidthRatio) * width;
    var headHeight = headHeightRatio * height;
    var headWidth = width - bodyWidth;

    _paint.color = borderColor;
    _paint.strokeWidth = strokeWidth;
    _paint.style = PaintingStyle.stroke;

    var rect = Rect.fromLTWH(haftStorkWidth, haftStorkWidth, bodyWidth, height);
    canvas.drawRect(rect, _paint);

    var headY1 = (height - headHeight) / 2 + haftStorkWidth;
    var headY2 = headY1 + headHeight;
    var headX1 = bodyWidth + haftStorkWidth;
    var headX2 = headX1 + headWidth;
    var path = Path()
      ..moveTo(headX1, headY1)
      ..lineTo(headX2, headY1)
      ..lineTo(headX2, headY2)
      ..lineTo(headX1, headY2);
    canvas.drawPath(path, _paint);

    var energyInterval = bodyWidth / (energyTotalCount + 1);
    _paint
      ..color = energyColor
      ..strokeWidth = energyInterval*2/3;

    var x = haftStorkWidth + energyInterval;
    var y1 = strokeWidth + bodyPaddingSize;
    var y2 = height - bodyPaddingSize;

    path.reset();
    for (int i = 0; i < energyShowCount; i++) {
      path.moveTo(x, y1);
      path.lineTo(x, y2);
      x += energyInterval;
    }
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
