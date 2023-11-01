import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/matrix_widget.dart';

class SettingState {
  SettingState._();

  static SettingState single = SettingState._();

  Color squareColor = Colors.blue;
  Color defaultColor = Colors.white;
  int row_count = 9;
  int colum_count = 16;

  List<GroupBrick> bricks = [
    GroupBrick([LineBrick1(), LineBrick2()]),
    GroupBrick([DingBrick1(), DingBrick2(), DingBrick3(), DingBrick4()]),
    GroupBrick([SquareBrick()]),
    GroupBrick([
      ConnerBrickR1(),
      ConnerBrickR2(),
      ConnerBrickR3(),
      ConnerBrickR4(),
    ]),
    GroupBrick([
      ConnerBrickL1(),
      ConnerBrickL2(),
      ConnerBrickL3(),
      ConnerBrickL4(),
    ])
  ];
}

class GroupBrick {
  GroupBrick(this.bricks){
    assert(bricks.isNotEmpty);
  }

  List<Brick> bricks;

  Brick get curBrick=>get();

  int _curIndex = 0;

  Brick get nextRandom {
    _curIndex = Random().nextInt(bricks.length);
    return get();
  }

  Brick? get next {
    if (bricks.length==1) {
      return null;
    }
    _curIndex++;
    return get();
  }

  Brick? get last {
    if (bricks.length==1) {
      return null;
    }
    _curIndex--;
    return get();
  }

  Brick get() {
    while(_curIndex<0||_curIndex>=bricks.length) {
      if (_curIndex >= bricks.length) {
        _curIndex -= bricks.length;
      } else if (_curIndex < 0) {
        _curIndex += bricks.length;
      }
    }
    var brick = bricks[_curIndex];
    return brick;
  }
}

abstract class Brick {
  Brick() {
    plist = _definePointList();
    for (var point in plist) {
      point.state.light = true;
    }
    _initSize();
    //移动到x轴上边
    _origin_anchor = anchor;
    centerFinal=_defineCenter();
  }

  late List<MatrixPoint> plist;

  late int left;
  late int top;
  late int right;
  late int bottom;

  MatrixPoint get anchor=>MatrixPoint((right+left)~/2, (top+bottom)~/2);

  MatrixPoint get moveSize => anchor-_origin_anchor;

  late final MatrixPoint _origin_anchor;
  late final MatrixPoint centerFinal;

  List<MatrixPoint> _definePointList();
  //指定中心点，旋转变换时以此为中心点，可能子类自定义
  MatrixPoint _defineCenter() => anchor;

  MatrixPoint get center => centerFinal+moveSize;

  set center(MatrixPoint center) {
    moveOffset(x:center.x - this.center.x, y:center.y - this.center.y);
  }

  _initSize() {
    var p = plist[0];
    left = p.x;
    top = p.y;
    right = p.x;
    bottom = p.y;
    for (var point in plist) {
      left = point.x < left ? point.x : left;
      top = point.y < top ? point.y : top;
      right = point.x > right ? point.x : right;
      bottom = point.y > bottom ? point.y : bottom;
    }
  }

  void moveOffset({int x=0, int y=0}) {
    if (x == 0 && y == 0) {
      return;
    }
    if (x!=0) {
      left+=x;
      right+=x;
    }
    if (y!=0) {
      top+=y;
      bottom+=y;
    }
    for (var element in plist) {
      if (y!=0) {
        element.y += y;
      }
      if (x!=0) {
        element.x += x;
      }
    }
  }

  void reset() {
    center = centerFinal;
  }
}

// 0
// 0
// 0
class LineBrick1 extends Brick {
  @override
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(1, 0),
        MatrixPoint(1, 1),
        MatrixPoint(1, 2),
      ];
}

// 0 0 0
class LineBrick2 extends Brick {
  @override
  List<MatrixPoint>  _definePointList() => [
        MatrixPoint(0, 1),
        MatrixPoint(1, 1),
        MatrixPoint(2, 1),
      ];
}

//   0
// 0 0 0
class DingBrick1 extends Brick {
  @override
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 1),
        MatrixPoint(1, 1),
        MatrixPoint(1, 0),
        MatrixPoint(2, 1),
      ];

  @override
  MatrixPoint _defineCenter() {
    return MatrixPoint(1, 1);
  }
}

// 0
// 0 0
// 0
class DingBrick2 extends Brick {
  @override
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 2),
        MatrixPoint(0, 1),
        MatrixPoint(0, 0),
        MatrixPoint(1, 1),
      ];

  @override
  MatrixPoint _defineCenter() {
    return MatrixPoint(0, 1);
  }
}

// 0 0 0
//   0
class DingBrick3 extends Brick {
  @override
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 0),
        MatrixPoint(1, 0),
        MatrixPoint(2, 0),
        MatrixPoint(1, 1),
      ];

  @override
  MatrixPoint _defineCenter() {
    return MatrixPoint(1, 0);
  }
}

//   0
// 0 0
//   0
class DingBrick4 extends Brick {
  @override
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 1),
        MatrixPoint(1, 1),
        MatrixPoint(1, 0),
        MatrixPoint(1, 2),
      ];

  @override
  MatrixPoint _defineCenter() {
    return MatrixPoint(1, 1);
  }
}

//0 0
//0 0
class SquareBrick extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 1),
        MatrixPoint(1, 1),
        MatrixPoint(0, 0),
        MatrixPoint(1, 0),
      ];
}

// 0 0
// 0
// 0
class ConnerBrickR1 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 2),
        MatrixPoint(0, 1),
        MatrixPoint(0, 0),
        MatrixPoint(1, 0),
      ];
}

// 0 0 0
//     0
class ConnerBrickR2 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 0),
        MatrixPoint(1, 0),
        MatrixPoint(2, 0),
        MatrixPoint(2, 1),
      ];
}

//   0
//   0
// 0 0
class ConnerBrickR3 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 2),
        MatrixPoint(1, 2),
        MatrixPoint(1, 1),
        MatrixPoint(1, 0),
      ];
}

// 0
// 0 0 0
class ConnerBrickR4 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
        MatrixPoint(0, 0),
        MatrixPoint(0, 1),
        MatrixPoint(1, 1),
        MatrixPoint(2, 1)
      ];
}


// 0 0
//   0
//   0
class ConnerBrickL1 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
    MatrixPoint(0, 0),
    MatrixPoint(1, 0),
    MatrixPoint(1, 1),
    MatrixPoint(1, 2),
  ];
}

//     0
// 0 0 0
class ConnerBrickL2 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
    MatrixPoint(0, 1),
    MatrixPoint(1, 1),
    MatrixPoint(2, 1),
    MatrixPoint(2, 0)
  ];
}

// 0
// 0
// 0 0
class ConnerBrickL3 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
    MatrixPoint(0, 0),
    MatrixPoint(0, 1),
    MatrixPoint(0, 2),
    MatrixPoint(1, 2),
  ];
}

// 0 0 0
// 0
class ConnerBrickL4 extends Brick {
  @override
  // TODO: implement _plist
  List<MatrixPoint> _definePointList() => [
    MatrixPoint(0, 0),
    MatrixPoint(1, 0),
    MatrixPoint(2, 0),
    MatrixPoint(0, 1),
  ];
}
