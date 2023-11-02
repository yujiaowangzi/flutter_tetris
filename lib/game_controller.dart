import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tetris/home_page.dart';
import 'package:flutter_tetris/main.dart';
import 'package:flutter_tetris/setting_state.dart';
import 'package:flutter_tetris/utils/log/logger.dart';
import 'package:flutter_tetris/utils/periodic_task.dart';

import 'matrix_widget.dart';

class GameController {
  GameController() {
    top = displayController.colum;
  }

  DisplayController displayController = DisplayController(
      SettingState.single.row_count, SettingState.single.colum_count,
      viewDebug: false);
  DisplayController nextDisplayCtrl = DisplayController(3, 3, viewDebug: false);

  late Brick curBrick;

  late GroupBrick groupBrick;
  GroupBrick? nextGroupBrick;
  PanelController panelController = PanelController();

  bool get isStart => _startFlag;

  bool _startFlag = false;

  bool _completelyStopFlag = true;

  late int top;
  Function(bool running)? _runningListener;

  setRunningListener(Function(bool running)? runningListener) {
    _runningListener = runningListener;
  }

  void completelyStop() async {
    _completelyStopFlag = true;
    stopGame();

    await displayController.climb(stepX: 1, stepY: -1, getState: setLightOn);
    displayController.climb(stepX: 1, stepY: 1, getState: setLightOff);

    nextDisplayCtrl.refreshStateAll(getState: setLightOff);
    nextDisplayCtrl.refresh();
    panelController.score = 0;
    nextGroupBrick = null;
  }

  //开始游戏
  void startGame() {
    if (_startFlag) {
      return;
    }
    _completelyStopFlag = false;
    _startFlag = true;
    setMainRunning();
    _runningListener?.call(true);
    _task.start();
  }

  void _tickFrame() {
    LogPrint('tick is fast = $_fastSpeedFlag');
    //刚开始
    if (nextGroupBrick == null) {
      _resetBrick();
      return;
    }

    if (_wouldMoveDownBricks.isNotEmpty) {
      for (int i = 0; i < _wouldMoveDownBricks.length; i++) {
        var brick = _wouldMoveDownBricks[i];
        if (_canMoveDown(brick)) {
          displayController.pushOffsetList(brick.plist, offsetY: 1);
          displayController.refresh();
          brick.moveOffset(y: 1);
        } else {
          _wouldMoveDownBricks.removeAt(i);
        }
      }

      if (_wouldMoveDownBricks.isNotEmpty) {
        return;
      }
    }

    var down = moveDown();
    if (!down) {
      _onOneBrickFinished();
    }
  }

  late final PeriodicTask _task = PeriodicTask(() => _tickFrame());

  final Duration _normalSpeed = const Duration(milliseconds: 1000);
  final Duration _fastSpeed = const Duration(milliseconds: 50);

  bool _fastSpeedFlag = false;

  void setMainRunning() {
    if (!_startFlag) {
      return;
    }
    _fastSpeedFlag = false;
    _startFlag = true;
    _task.setInterval(_normalSpeed);
  }

  void setFastRunning() {
    if (!_startFlag) {
      return;
    }
    _fastSpeedFlag = true;
    _task.setInterval(_fastSpeed);
  }

  //关闭游戏
  void stopGame() {
    _startFlag = false;
    _task.stop();
    _runningListener?.call(false);
    top = displayController.colum;
  }

  void startOrStop() {
    if (_startFlag) {
      stopGame();
    } else {
      startGame();
    }
  }

  //当方块到达并结束时
  _onOneBrickFinished() {
    _refreshBound(curBrick);
    if (_checkGameOver()) {
      stopGame();
      LogPrint('Game over');
      return;
    }
    if (_checkRowFull()) {
      return;
    }
    _resetBrick();
    if (_fastSpeedFlag) {
      setMainRunning();
    }
  }

  _resetBrick() {
    if (nextGroupBrick != null) {
      groupBrick = nextGroupBrick!;
      curBrick = groupBrick.curBrick;
    } else {
      groupBrick = _getRandomGroupBrick();
      curBrick = groupBrick.nextRandom;
    }

    nextGroupBrick = _getRandomGroupBrick();
    var ps = (nextGroupBrick!.nextRandom..reset())
        .plist
        .map<MatrixPoint>((e) => e.clone())
        .toList();
    nextDisplayCtrl.refreshStateAll(getState: setLightOff);
    nextDisplayCtrl.pushStateList(ps, getState: setLightOn);
    nextDisplayCtrl.refresh();

    //移动到顶部看不见的位置
    curBrick
      ..reset()
      ..center = MatrixPoint(displayController.lastRowIndex ~/ 2,
          curBrick.center.y - curBrick.bottom - 1);
  }

  //检查游戏是否结束
  _checkGameOver() {
    return top < 0;
  }

  List<Brick> _wouldMoveDownBricks = [];
  List<int> checkFullRowList=[];

  //检查是否有满行
  bool _checkRowFull() {
    Set<int> rows = {};
    for (var element in curBrick.plist) {
      if (element.y < displayController.colum) {
        rows.add(element.y);
      }
    }
    var fullRows =
        displayController.getFullRowsIndex(columIndexList: checkFullRowList);
    if (fullRows.isNotEmpty) {
      LogPrint('吃 rows=$fullRows');
      displayController.pushStateRow(fullRows, getState: setLightOff);
      displayController.refresh();
      panelController.score += fullRows.length;

      var bottom = displayController.lastColumIndex;
      for (var i in fullRows) {
        bottom = i < bottom ? i : bottom;
      }
      _lookupAroundTemp.clear();
      for (int x = 0; x < displayController.row; x++) {
        for (int y = top; y < bottom; y++) {
          var matrixPoint = displayController.getPoint(x, y);
          if (matrixPoint != null &&
              matrixPoint.state.light &&
              !_lookupAroundTemp.contains(matrixPoint)) {
            var aroundPoints = _getAroundLightPoints(matrixPoint);
            LogPrint('待下落', '${matrixPoint.x},${matrixPoint.y} size=${aroundPoints.length}');
            if (aroundPoints.isNotEmpty) {
              _wouldMoveDownBricks.add(
                  CustomBrick(aroundPoints.map((e) => e.clone()).toList()));
            }
          }
        }
      }
    }
    return _wouldMoveDownBricks.isNotEmpty;
  }

  Set<MatrixPoint> _lookupAroundTemp = {};

  List<MatrixPoint> _getAroundLightPoints(MatrixPoint point) {
    if (!_lookupAroundTemp.add(point)) {
      return [];
    }
    List<MatrixPoint> global = [point];
    var ls = [
      displayController.getPoint(point.x - 1, point.y),
      displayController.getPoint(point.x + 1, point.y),
      displayController.getPoint(point.x, point.y - 1),
      displayController.getPoint(point.x, point.y + 1),
    ];
    List<MatrixPoint> ps = [];
    for (var element in ls) {
      if (element != null) {
        ps.add(element);
      }
    }

    for (var neighbor in ps) {
      if (neighbor.state.light && !_lookupAroundTemp.contains(neighbor)) {
        var l = _getAroundLightPoints(neighbor);
        global.addAll(l);
      }
    }

    return global;
  }

  _refreshBound(Brick brick) {
    top = brick.top < top ? brick.top : top;
    LogPrint('cur Top = $top');
  }

  GroupBrick _getRandomGroupBrick() {
    var bricks = SettingState.single.bricks;
    var g = Random().nextInt(bricks.length);
    LogPrint('new GroupBrick i=$g');
    return bricks[g];
  }

  bool _outBound_LRB(Brick brick, {int offsetX = 0, int offsetY = 0}) {
    // LogPrint('bound bottom=${brick.bottom}');
    return brick.left + offsetX < 0 ||
        brick.right + offsetX > displayController.lastRowIndex ||
        brick.bottom + offsetY > displayController.lastColumIndex;
  }

  bool _overlap(Brick brick, {int offsetX = 0, int offsetY = 0}) =>
      displayController.checkOverlapList(brick.plist,
          offsetX: offsetX, offsetY: offsetY);

  bool _canMoveDown(Brick brick) {
    if (_outBound_LRB(brick, offsetY: 1)) {
      return false;
    }
    var overlap = _overlap(brick, offsetY: 1);
    return !overlap;
  }

  bool _canMoveLeft(Brick brick) {
    if (_outBound_LRB(brick, offsetX: -1)) {
      return false;
    }
    var overlap = _overlap(brick, offsetX: -1);
    return !overlap;
  }

  bool _canMoveRight(Brick brick) {
    if (_outBound_LRB(brick, offsetX: 1)) {
      return false;
    }
    var overlap = _overlap(brick, offsetX: 1);
    return !overlap;
  }

  void moveLeft() {
    if (!_startFlag) {
      return;
    }
    if (_canMoveLeft(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: -1);
      displayController.refresh();
      curBrick.moveOffset(x: -1);
    }
  }

  void moveRight() {
    if (!_startFlag) {
      return;
    }
    if (_canMoveRight(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: 1);
      displayController.refresh();
      curBrick.moveOffset(x: 1);
    }
  }

  bool moveDown() {
    if (!_startFlag) {
      return false;
    }
    if (_canMoveDown(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetY: 1);
      displayController.refresh();
      curBrick.moveOffset(y: 1);
      return true;
    }
    return false;
  }

  void ajustOffsetBound_LR(Brick brick) {
    if (brick.left < 0) {
      var offsetX = -brick.left;
      brick.moveOffset(x: offsetX);
    }
    if (brick.right > displayController.lastRowIndex) {
      var offsetX = displayController.lastRowIndex - brick.right;
      brick.moveOffset(x: offsetX);
    }
  }

  void changeShape({bool next = true}) {
    if (!_startFlag) {
      return;
    }
    var nextBrick = next ? groupBrick.next : groupBrick.last;
    if (nextBrick == null) {
      return;
    }
    nextBrick.center = curBrick.center;
    ajustOffsetBound_LR(nextBrick);

    //去除妨碍监测碰撞的阻碍
    displayController.pushStateList(curBrick.plist, getState: setLightOff);
    if (_overlap(nextBrick)) {
      displayController.pushStateList(curBrick.plist, getState: setLightOn);
      groupBrick.last;
      return;
    }

    curBrick = nextBrick;
    displayController.pushStateList(curBrick.plist);
    displayController.refresh();
  }

  void dispose() {
    displayController.dispose();
  }
}

class PanelController extends ValueNotifier<_Panel> {
  PanelController() : super(_Panel());

  set score(int score) {
    value.score = score;
    notifyListeners();
  }

  int get score => value.score;
}

class _Panel {
  int score = 0;
}
