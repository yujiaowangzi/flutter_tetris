import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tetris/setting_state.dart';
import 'package:flutter_tetris/utils/log/logger.dart';
import 'package:flutter_tetris/utils/periodic_task.dart';

import 'widgets/matrix_widget.dart';

class GameController {
  GameController() {
    top = displayController.colum;
  }

  DisplayController displayController = DisplayController(
      SettingState.single.row_count, SettingState.single.colum_count,
      viewDebug: false);
  DisplayController nextDisplayCtrl = DisplayController(3, 3, viewDebug: false);

  GameState state=GameState.READY;

  late Brick curBrick;

  late GroupBrick groupBrick;
  GroupBrick? nextGroupBrick;
  PanelController panelController = PanelController();

  late int top;
  List<Function(GameState)> _stateListeners=[];

  addListener(Function(GameState) l) {
    _stateListeners.add(l);
  }

  removeListener(Object l){
    _stateListeners.remove(l);
  }

  _publicListen(){
    for (var element in _stateListeners) {
      element.call(state);
    }
  }

  void completelyStop() async {
    if (state==GameState.RESET||state==GameState.READY) {
      return;
    }
    stopGame();

    state=GameState.RESET;
    _publicListen();

    await displayController.climb(stepX: 1, stepY: -1, getState: setLightOn);
    await displayController.climb(stepX: 1, stepY: 1, getState: setLightOff);
    nextDisplayCtrl.refreshStateAll(getState: setLightOff);
    nextDisplayCtrl.refresh();

    panelController.score = 0;
    state=GameState.READY;
    _publicListen();
    nextGroupBrick = null;
  }

  //开始游戏
  void startGame() {
    if (state==GameState.RUNNING) {
      return;
    }
    state=GameState.RUNNING;
    setMainRunning();
    _publicListen();
    _task.start();
  }

  void _tickFrame() {
    LogPrint('tick is speed = $_speedType');
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

  SpeedType? _speedType;
  Duration _increaseSpeed=const Duration(milliseconds: 0);
  final Duration _maxIncreaseSpeed=SpeedType.normal.value-const Duration(milliseconds: 200);
  int _increaseCount=0;

  void setMainRunning() {
    if (state!=GameState.RUNNING||_speedType==SpeedType.normal) {
      return;
    }
    _speedType=SpeedType.normal;
    var speed;
    speed=_speedType!.value-_increaseSpeed;
    LogPrint('当前speed = ${speed.inMilliseconds}');
    _task.setInterval(speed);
  }

  void setMiddleRunning() {
    if (state!=GameState.RUNNING || _speedType==SpeedType.middle) {
      return;
    }
    _speedType=SpeedType.middle;
    _task.setInterval(_speedType!.value);
  }

  void setFastRunning() {
    if (state!=GameState.RUNNING || _speedType==SpeedType.fast) {
      return;
    }
    _speedType=SpeedType.fast;
    _task.setInterval(_speedType!.value);
  }

  //关闭游戏
  void stopGame() {
    if (state!=GameState.RUNNING) {
      return;
    }
    state=GameState.STOP;
    _task.stop();
    _publicListen();
    top = displayController.colum;
  }

  void startOrStop() {
    if (state==GameState.RUNNING) {
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
      state=GameState.GAME_OVER;
      _publicListen();
      LogPrint('Game over');
      return;
    }

    if (_checkRowFull()) {
      setMiddleRunning();
      return;
    }
    _resetBrick();
    //检查是否增加速度,
    if (_increaseCount>10) {
      _increaseCount=0;
      if (_increaseSpeed<_maxIncreaseSpeed) {
        _increaseSpeed+=const Duration(milliseconds: 100);
      }
    }
    setMainRunning();
    _increaseCount++;
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

  //检查是否有满行
  bool _checkRowFull() {
    var fullRows =
        displayController.lookupFullRowsIndex();
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
            LogPrint('待下落',
                '${matrixPoint.x},${matrixPoint.y} size=${aroundPoints.length}');
            if (aroundPoints.isNotEmpty) {
              _wouldMoveDownBricks.add(
                CustomBrick(aroundPoints.map((e) => e.clone()).toList()),
              );
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
    if (state!=GameState.RUNNING) {
      return;
    }
    if (_canMoveLeft(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: -1);
      displayController.refresh();
      curBrick.moveOffset(x: -1);
    }
  }

  void moveRight() {
    if (state!=GameState.RUNNING) {
      return;
    }
    if (_canMoveRight(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: 1);
      displayController.refresh();
      curBrick.moveOffset(x: 1);
    }
  }

  bool moveDown() {
    if (state!=GameState.RUNNING) {
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
    if (state!=GameState.RUNNING) {
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
    _stateListeners.clear();
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

enum SpeedType {
  normal(Duration(milliseconds: 1000)),middle(Duration(milliseconds: 150)),fast(Duration(milliseconds: 50));

  const SpeedType(this.value);

  final Duration value;
}

enum GameState{
  READY,RUNNING,STOP,RESET,GAME_OVER
}
