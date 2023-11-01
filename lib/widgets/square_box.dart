import 'dart:math';

import 'package:flutter/material.dart';

class SquareBox extends StatelessWidget{
  SquareBox({super.key,required this.child});

  Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_,constrain){
      var size=min(constrain.maxWidth, constrain.maxHeight);
      if (size.isFinite) {
        return SizedBox.fromSize(size: Size.square(size),child: child,);
      }
      return child;
    });
  }

}