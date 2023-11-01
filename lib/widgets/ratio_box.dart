import 'dart:math';

import 'package:flutter/material.dart';

class RatioSizeBox extends StatelessWidget {
  RatioSizeBox({
    super.key,
    this.widthRadio = 1,
    this.heightRadio = 1,
    required this.child,
  });

  Widget child;
  double widthRadio;
  double heightRadio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth.isFinite || c.maxHeight.isFinite) {
        var radio1=widthRadio/heightRadio;
        var radio2=c.maxWidth/c.maxHeight;
        var width;
        var height;
        if (radio1>radio2) {
          width=c.maxWidth;
          height=width/radio1;
        }else{
          height=c.maxHeight;
          width=height*radio1;
        }
        return UnconstrainedBox(
          child: SizedBox(
            width: width,
            height: height,
            child: child,
          ),
        );
      }
      return child;
    });
  }
}
