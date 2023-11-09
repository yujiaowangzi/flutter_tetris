import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tetris/global/setting_state.dart';
import 'package:flutter_tetris/utils/utils.dart';
import 'package:flutter_tetris/widgets/battery_view.dart';

import '../utils/log/logger.dart';

class MatrixView extends StatelessWidget {
  MatrixView({super.key, required this.controller});

  DisplayController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constrain) {
        var grid = GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          crossAxisCount: controller.row,
          children: controller.grdViews,
        );
        var mH = constrain.maxHeight;
        var mW = constrain.maxWidth;

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
                    border: Border.all(
                        color: SettingState.primaryTextColor3, width: 1)),
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

  _getEnergyBattery() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: BatteryView(
            energyShowCount: point.data.energyLevel,
            borderColor: Colors.grey));
  }

  _getBattery() {
    var image;
    if (point.data.state == PointState.FULL) {
      return _getEnergyBattery();
    } else if (point.data.state == PointState.MOVABLE) {
      image = 'battery_blue.png'.img;
    } else if(point.data.state==PointState.FIXED){
      image = 'battery_green.png'.img;
    }else{
      image = 'battery_grey.png'.img;
    }
    return Image.asset(image);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: ValueListenableBuilder(
        valueListenable: point,
        builder: (_, v, child) {
          if (!viewDebug) {
            return _getBattery();
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              color: point.data.light
                  ? point.data.color
                  : SettingState.single.defaultColor,
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Center(
              child: Text('${point.x},${point.y}'),
            ),
          );
        },
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
        var point = MatrixPoint(r, c, data: PointData(state: PointState.IDLE));
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

  Map<String, PointData> _pointMoveDestTemp = {};
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

  //状态改变并等待刷新的点
  Set<MatrixPoint> _wouldRereshPoint = {};

  //修改点状态的核心方法
  pushState(int x, int y, {required ChangePointState getState}) {
    var point = getPoint(x, y);
    if (point != null) {
      //获取最新state
      var state = getState.call(point.data);
      if (state != point.data) {
        //如果不是同一个state对象，则比较内容是否不一样
        if (!point.data.equal(state)) {
          // LogPrint('add refresh not save object x=$x y=$y');
          _wouldRereshPoint.add(point);
        }
        point.data = state;
        //检查状态是否改变
      } else if (point.checkAndPushDataChange()) {
        // LogPrint('add refresh x=$x y=$y');
        _wouldRereshPoint.add(point);
      }
    }
  }

  void pushStateList(List<MatrixPoint>? pointList,
      {required ChangePointState getState}) {
    if (pointList != null) {
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
    var dState = getPoint(dx, dy)?.data;
    if (dState == null) {
      return;
    }
    PointData? state = getPoint(x, y)?.data;
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

  MatrixPoint? getPoint(int x, int y, {int offsetX = 0, int offsetY = 0}) {
    x += offsetX;
    y += offsetY;
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

  List<int> lookupFullRowsIndex({List<int>? columIndexList}) {
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
        if (!cPoints[y].data.light) {
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
  bool checkOverlapList(List<MatrixPoint> pList,
      {int offsetX = 0, int offsetY = 0}) {
    if (pList.isEmpty) {
      return false;
    }
    //是否排除自己的点，只有偏移时才有作用
    var excludeSelf = offsetX!=0||offsetY!=0;
    //排除自身
    Set<String>? excludeKeySet;
    if (excludeSelf) {
      if (pList.length > 1) {
        excludeKeySet = {};
        for (var point in pList) {
          excludeKeySet.add(getPointKey(point.x, point.y));
        }
      }
    }

    for (var point in pList) {
      var x = point.x + offsetX;
      var y = point.y + offsetY;
      if (excludeKeySet == null || !excludeKeySet.contains(getPointKey(x, y))) {
        var bound = checkOverlap(x, y);
        if (bound == true) {
          return true;
        }
      }
    }
    return false;
  }

  //检查一个点是否已经被覆盖
  bool checkOverlap(int x, int y, {int offsetX = 0, int offsetY = 0}) {
    var ox = x + offsetX;
    var oy = y + offsetY;
    var matrixPoint = getPoint(ox, oy);
    return matrixPoint?.data.light ?? false;
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

  bool climbFlag = false;

  climb(
      {required int stepX,
      required int stepY,
      required ChangePointState getState}) async {
    if (stepX == 0 || stepY == 0) {
      return;
    }
    //当stepX > 0 表示从左到右增长
    var x = stepX > 0 ? 0 : lastRowIndex;
    //stepY>0表示从上到下
    var y = stepY > 0 ? 0 : lastColumIndex;
    climbFlag = true;
    while (climbFlag) {
      pushState(x, y, getState: getState);
      refresh();
      //下到上
      if (stepY < 0) {
        if (y == 0 && (x == lastRowIndex && stepX > 0 || x == 0 && stepX < 0)) {
          return;
        }
        //上到下
      } else if (y == lastColumIndex &&
          (x == lastRowIndex && stepX > 0 || x == 0 && stepX < 0)) {
        return;
      }
      if (x == 0) {
        if (stepX < 0) {
          //刚到左边
          y += stepY;
          stepX = 0;
        } else {
          stepX = 1;
        }
      } else if (x == lastRowIndex) {
        if (stepX > 0) {
          //刚到达右边
          y += stepY;
          stepX = 0;
        } else {
          stepX = -1;
        }
      }
      x += stepX;
      await Future.delayed(const Duration(milliseconds: 3));
    }
  }

  void dispose() {
    climbFlag = false;
  }
}

ChangePointState setLightOff = setStateIdle;
ChangePointState setLightOn = setStateMovable;
ChangePointState setStateMovable = (s) => s..state = PointState.MOVABLE;
ChangePointState setStateFixed = (s) => s..state = PointState.FIXED;
ChangePointState setStateFull = (s) => s..state = PointState.FULL;
ChangePointState setStateIdle = (s) => s..state = PointState.IDLE;

typedef ChangePointState = PointData Function(PointData);

class MatrixPoint extends ValueNotifier {
  MatrixPoint(this.x, this.y, {PointData? data}) : super(Void) {
    _data = data ?? PointData();
    _oldState=_dataFinal = _data.clone();
  }

  int x;
  int y;

  late PointData _data;
  late PointData _oldState;
  late final PointData _dataFinal;

  PointData get data => _data;

  set data(PointData data) {
    _data = data;
    _oldState = _data.clone();
  }

  //检查是否给变状态，一次改变只能调用一次
  bool checkAndPushDataChange() {
    var change = !_data.equal(_oldState);
    if (change) {
      _oldState = _data.clone();
    }
    return change;
  }

  void refresh() {
    // LogPrint('refresh ($x,$y)');
    notifyListeners();
  }

  void reset() {
    _data = _dataFinal.clone();
  }

  operator -(MatrixPoint point) {
    return MatrixPoint(x - point.x, y - point.y);
  }

  operator +(MatrixPoint point) {
    return MatrixPoint(x + point.x, y + point.y);
  }

  @override
  String toString() {
    return '${super.toString()} x=$x y=$y';
  }

  MatrixPoint clone() {
    return MatrixPoint(x, y, data: data);
  }
}

class PointData {
  PointData({
    this.color = Colors.blue,
    this.state = PointState.MOVABLE,
    this.energyLevel = BatteryView.energyTotalCount,
  });

  Color color;
  PointState state;
  int energyLevel;

  bool get light => state!=PointState.IDLE;

  set light(bool light)=> state=PointState.MOVABLE;

  PointData clone() {
    return PointData(color: color,state: state,energyLevel: energyLevel);
  }

  bool equal(PointData? other) {
    return color == other?.color &&
        state == other?.state &&
        energyLevel == other?.energyLevel;
  }
}

enum PointState {IDLE,MOVABLE, FIXED, FULL }
