import 'dart:async';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tetris/home_page.dart';
import 'package:flutter_tetris/setting_state.dart';
import 'package:flutter_tetris/utils/layout_print_widget.dart';
import 'package:flutter_tetris/utils/log/logger.dart';
import 'package:flutter_tetris/utils/utils.dart';

class MatrixView extends StatelessWidget {
  MatrixView({super.key, required this.controller});

  DisplayController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constrain) {
        var grid = GridView.count(
          shrinkWrap: true,
          crossAxisCount: controller.row,
          children: controller.grdViews,
        );
        var mW = constrain.maxWidth;
        var mH = constrain.maxHeight;

        var r1 = mH / mW;
        var r2 = controller.colum / controller.row;

        var width;
        var height;

        if (r1 > r2) {
          width = constrain.maxWidth;
          height = width * r2;
        } else {
          height = constrain.maxHeight;
          width = height / r2;
        }
        return UnconstrainedBox(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 1)),
                child: grid),
          ),
        );
      },
    );
  }
}

class APointView extends StatelessWidget {
  APointView({super.key, required this.point, this.viewDebug = kDebugMode});

  MatrixPoint point;
  bool viewDebug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: ValueListenableBuilder(
          valueListenable: point,
          builder: (_, v, child) {
            if (!viewDebug) {
              return point.state.light
                  ? Image.asset(
                      'images/square1.png',
                      fit: BoxFit.fill,
                    )
                  : const SizedBox();
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: point.state.light
                    ? point.state.color
                    : SettingState.single.defaultColor,
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Center(
                child: Text('${point.x},${point.y}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

///显示控制
class DisplayController {
  DisplayController(this.row, this.colum, {this.viewDebug = kDebugMode}) {
    for (int r = 0; r < row; r++) {
      //一列
      List<MatrixPoint> cs = [];
      List<APointView> vs = [];
      for (int c = 0; c < colum; c++) {
        var point = MatrixPoint(r, c, state: PointState(light: false));
        cs.add(point);
        vs.add(APointView(point: point, viewDebug: viewDebug));
      }
      point_matrix.add(cs);
      point_views.add(vs);
    }
  }

  bool viewDebug;

  int row;
  int colum;

  int get lastRowIndex => row - 1;

  int get lastColumIndex => colum - 1;

  List<List<MatrixPoint>> point_matrix = [];
  List<List<APointView>> point_views = [];

  List<APointView> _gridViews = [];

  Map<String, PointState> _pointMoveDestTemp = {};
  Set<String> _pointMoveAfterTemp = {};

  List<APointView> get grdViews {
    if (_gridViews.isEmpty) {
      for (int c = 0; c < colum; c++) {
        for (int r = 0; r < point_views.length; r++) {
          var cs = point_views[r];
          _gridViews.add(cs[c]);
        }
      }
    }
    return _gridViews;
  }

  Set<MatrixPoint> _wouldRereshPoint = {};

  pushState(int x, int y, {required ChangePointState getState}) {
    var point = getPoint(x, y);
    if (point != null) {
      var state = getState.call(point.state);
      if (state != point.state) {
        if (!point.state.equal(state)) {
          // LogPrint('add x=$x y=$y');
          _wouldRereshPoint.add(point);
        }
        point.state = state;
      } else if (!state.equal(point.oldState)) {
        point.state = state;
        // LogPrint('add x=$x y=$y');
        _wouldRereshPoint.add(point);
      }
    }
  }

  void pushStateList(List<MatrixPoint>? pointList,
      {ChangePointState? getState}) {
    if (pointList != null) {
      getState ??= setLightOn;
      for (var point in pointList) {
        pushState(point.x, point.y, getState: getState);
      }
    }
  }

  pushStateRow(List<int> ys, {required ChangePointState getState}) {
    for (var y in ys) {
      if (y < 0 || y > lastColumIndex) {
        continue;
      }
      for (var cPoints in point_matrix) {
        var point = cPoints[y];
        pushState(point.x, point.y, getState: getState);
      }
    }
  }

  pushStateColum(List<int> xs, {required ChangePointState getState}) {
    for (var x in xs) {
      if (x < 0 || x > lastRowIndex) {
        continue;
      }
      var cs = point_matrix[x];
      pushStateList(cs, getState: getState);
    }
  }

  pushOffset(int x, int y, {int offsetX = 0, int offsetY = 0}) {
    if (offsetX == 0 && offsetY == 0) {
      return;
    }
    var dx = x + offsetX;
    var dy = y + offsetY;
    var dState = getPoint(dx, dy)?.state;
    if (dState == null) {
      return;
    }
    PointState? state = getPoint(x, y)?.state;
    if (state != null) {
      var key = getPointKey(x, y);
      var matrixState = state;
      state = _pointMoveDestTemp[key];
      if (state == null) {
        state = matrixState.clone();
        _pointMoveDestTemp[key] = state;
        // print('save x=$x y=$y l=${state.light}');
      }
      if (!_pointMoveAfterTemp.contains(key)) {
        pushState(x, y, getState: setLightOff);
        // print('push x=$x y=$y l= ${matrixState.light}');
      }
    }

    var destKey = getPointKey(dx, dy);
    if (!_pointMoveDestTemp.containsKey(destKey)) {
      _pointMoveDestTemp[destKey] = dState.clone();
      // print('save next x=$dx y=$dy l=${dState.light}');
    }
    //stateCache==null时，light==true
    pushState(dx, dy, getState: (s) => state ?? (s..light = true));

    if (!_pointMoveAfterTemp.contains(destKey)) {
      _pointMoveAfterTemp.add(destKey);
    }
    // print('push next x=$dx y=$dy l=${state?.light ?? true}');
  }

  pushOffsetList(List<MatrixPoint> points, {int offsetX = 0, int offsetY = 0}) {
    if (offsetX == 0 && offsetY == 0) {
      return;
    }
    for (var point in points) {
      pushOffset(point.x, point.y, offsetX: offsetX, offsetY: offsetY);
    }
  }

  bool validAxis(int x, int y) {
    return x >= 0 && x < row && y >= 0 && y < colum;
  }

  pushOffsetRows(List<int> ys, {int offsetX = 0, int offsetY = 0}) {
    if (offsetX == 0 && offsetY == 0) {
      return;
    }
    for (var y in ys) {
      var row = getRowMatrixPointList(y);
      if (row != null) {
        pushOffsetList(row, offsetX: offsetX, offsetY: offsetY);
      }
    }
  }

  MatrixPoint? getPoint(int x, int y) {
    if (validAxis(x, y)) {
      return point_matrix[x][y];
    }
    return null;
  }

  List<MatrixPoint>? getRowMatrixPointList(int y) {
    List<MatrixPoint>? matrixList;
    if (y >= 0 && y < colum) {
      matrixList = [];
      for (var cp in point_matrix) {
        matrixList.add(cp[y]);
      }
    }
    return matrixList;
  }

  List<int> getFullRowsIndex({List<int>? columIndexList}) {
    Set<int> fullRows = {};
    if (columIndexList == null) {
      columIndexList = [];
      for (int i = 0; i < colum; i++) {
        columIndexList.add(i);
      }
    }
    for (var y in columIndexList) {
      var full = true;
      for (var cPoints in point_matrix) {
        if (!cPoints[y].state.light) {
          full = false;
          break;
        }
      }
      if (full) {
        fullRows.add(y);
      }
    }
    return fullRows.toList();
  }

  static getPointKey(int x, int y) {
    return '${x}_$y';
  }

  //检查是否与已经显示的部分有重叠
  bool checkOverlap(List<MatrixPoint> pList,
      {int offsetX = 0, int offsetY = 0}) {
    Set<String>? excludeKeySet;
    if (offsetX != 0 || offsetY != 0) {
      excludeKeySet = {};
      for (var point in pList) {
        excludeKeySet.add(getPointKey(point.x, point.y));
      }
    }
    for (var point in pList) {
      var x = point.x + offsetX;
      var y = point.y + offsetY;
      var matrixPoint = getPoint(x, y);
      if (excludeKeySet == null || !excludeKeySet.contains(getPointKey(x, y))) {
        var bound = matrixPoint?.state.light;
        if (bound == true) {
          return true;
        }
      }
    }
    return false;
  }

  refreshStateAll({required ChangePointState getState}) {
    for (var colum in point_matrix) {
      pushStateList(colum, getState: getState);
    }
    refresh();
  }

  void refresh() {
    for (var element in _wouldRereshPoint) {
      element.refresh();
    }
    _wouldRereshPoint.clear();
    _pointMoveDestTemp.clear();
    _pointMoveAfterTemp.clear();
  }

  Timer? timer;

  climb({required int stepX,required int stepY,required ChangePointState getState})async{
    if (stepX==0||stepY==0) {
      return;
    }
    //当stepX > 0 表示从左到右增长
    var x=stepX>0?0:lastRowIndex;
    //stepY>0表示从上到下
    var y=stepY>0?0:lastColumIndex;
    while (true) {
      pushState(x, y, getState: getState);
      refresh();
      LogPrint('clim');
      //下到上
      if (stepY<0) {
        if (y==0&&(x==lastRowIndex&&stepX>0||x==0&&stepX<0)) {
          return;
        }
        //上到下
      }else if (y==lastColumIndex&&(x==lastRowIndex&&stepX>0||x==0&&stepX<0)) {
        return;
      }
      if (x==0) {
        if (stepX<0) {//刚到左边
          y+=stepY;
          stepX=0;
        }else{
          stepX=1;
        }
      }else if (x==lastRowIndex) {
        if (stepX>0) {//刚到达右边
          y+=stepY;
          stepX=0;
        }else{
          stepX=-1;
        }
      }
      x+=stepX;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  void dispose(){
    timer?.cancel();

  }

}

ChangePointState setLightOff = (s) => s..light = false;
ChangePointState setLightOn = (s) => s..light = true;

typedef ChangePointState = PointState Function(PointState);

class MatrixPoint extends ValueNotifier {
  MatrixPoint(this.x, this.y, {PointState? state}) : super(Void) {
    _state = state ?? PointState();
    oldState = _stateFinal = _state.clone();
  }

  int x;
  int y;
  late PointState _state;
  late PointState oldState;
  late final PointState _stateFinal;

  PointState get state => _state;

  set state(PointState state) {
    _state = state;
    oldState = _state.clone();
  }

  void refresh() {
    // LogPrint('refresh ($x,$y)');
    notifyListeners();
  }

  void reset() {
    _state = _stateFinal.clone();
  }

  operator -(MatrixPoint point) {
    return MatrixPoint(x - point.x, y - point.y);
  }

  operator +(MatrixPoint point) {
    return MatrixPoint(x + point.x, y + point.y);
  }

  @override
  String toString() {
    return '${super.toString()} x=$x y=$y}';
  }

  MatrixPoint clone() {
    return MatrixPoint(x, y, state: state);
  }
}

class PointState {
  PointState({this.light = true, this.color = Colors.blue});

  bool light; //预设的状态
  Color color;

  PointState clone() {
    return PointState(light: light, color: color);
  }

  bool equal(PointState? other) {
    return light == other?.light && color == other?.color;
  }
}
