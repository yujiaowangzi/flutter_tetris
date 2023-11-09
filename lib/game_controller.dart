import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tetris/global/setting_state.dart';
import 'package:flutter_tetris/utils/log/logger.dart';
import 'package:flutter_tetris/utils/periodic_task.dart';
import 'package:flutter_tetris/widgets/battery_view.dart';

import 'widgets/matrix_widget.dart';

class GameController {
  GameController() {
    top = displayController.colum;
    speedNotifier = ValueNotifier(speedDescriber);
    stateNotifier.addListener(() {
      LogPrint('当前状态 state',stateNotifier.value);
    });

    scoreNotifier.addListener(() {
      var value=scoreNotifier.value;
      var ic=value-_lastScore;
      if (ic!=0) {
        _increaseScore=ic;
        _lastScore=scoreNotifier.value;
      }
    });
  }

  DisplayController displayController = DisplayController(
      SettingState.single.row_count, SettingState.single.colum_count,
      viewDebug: false);
  DisplayController nextDisplayCtrl = DisplayController(3, 3, viewDebug: false);

  //当前方块
  late Brick curBrick;
  //当前方块分组
  late GroupBrick groupBrick;
  //下一个方块分组
  GroupBrick? nextGroupBrick;

  //信息面板的状态控制器
  ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  int _lastScore=0;
  int _increaseScore=0;
  int get increaseScore=>_increaseScore;

  late ValueNotifier<String> speedNotifier;

  //当前状态
  ValueNotifier<GameState> stateNotifier = ValueNotifier(GameState.READY);

  GameState get state => stateNotifier.value;

  //记录当前方块最高位置
  late int top;

  late final PeriodicTask _task = PeriodicTask(mainTask: _tickFrame);

  //速度变化阶段大小
  final Duration speedStep = const Duration(milliseconds: 100);

//速度的信息描述
  String get speedDescriber {
    var max = SpeedType.normal.value - _minSpeed;
    return '${((SpeedType.normal.value - curSpeed + speedStep).inMilliseconds)}/${(max + speedStep).inMilliseconds}';
  }

  //当前速度类型
  SpeedType? _speedType;

  final Duration _minSpeed = const Duration(milliseconds: 200);

  int _increaseSpeedCountTemp = 0;
  final int _increaseSpeedCountThreshold = 10;
  Duration curSpeed = SpeedType.normal.value;
  Duration? lastSpeed;

  void reset() async {
    if (state == GameState.CLEARING || state == GameState.READY) {
      return;
    }
    stopGame();

    _resetSpeed();
    _task.clean();

    await animationCleanMatrix();

    scoreNotifier.value = 0;
    stateNotifier.value = GameState.READY;
    nextGroupBrick = null;
  }

  animationCleanMatrix()async{
    var state=stateNotifier.value;
    stateNotifier.value = GameState.CLEARING;

    await displayController.climb(stepX: 1, stepY: -1, getState: setLightOn);
    await displayController.climb(stepX: 1, stepY: 1, getState: setLightOff);

    stateNotifier.value=state;
  }

  //开始游戏
  void startGame() {
    if (state==GameState.CLEARING||state == GameState.RUNNING) {
      return;
    }
    LogPrint('startGame', 'state=$state');
    setMainRunning();
    _task.start();
  }

  //关闭游戏
  void stopGame() {
    if (state != GameState.RUNNING) {
      return;
    }
    LogPrint('stopGame', 'state=$state');
    stateNotifier.value = GameState.STOP;
    _task.stop();
    top = displayController.colum;
  }

  void startOrStop() {
    if (state == GameState.RUNNING) {
      stopGame();
    } else {
      startGame();
    }
  }

  void _tickFrame() {
    stateNotifier.value = GameState.RUNNING;
    //刚开始
    if (nextGroupBrick == null) {
      _resetBrick();
      return;
    }

    if (!moveDown()) {
      _onDropDownComplete();
    }
  }

  void setMainRunning() {
    if (_speedType == SpeedType.normal && curSpeed == lastSpeed) {
      return;
    }
    _speedType = SpeedType.normal;
    LogPrint('setMainRunning', 'lastSpeed=$lastSpeed speed=$curSpeed');
    lastSpeed = curSpeed;
    _task.setInterval(curSpeed);
  }

  void setMiddleRunning() {
    if (_speedType == SpeedType.middle) {
      return;
    }
    _speedType = SpeedType.middle;
    LogPrint('setMiddleRunning', 'speed=${_speedType?.value}');
    _task.setInterval(_speedType!.value);
  }

  void setFastRunning() {
    if (_speedType == SpeedType.fast) {
      return;
    }
    _speedType = SpeedType.fast;
    LogPrint('setFastRunning', 'speed=${_speedType?.value}');
    _task.setInterval(_speedType!.value);
  }

  //当方块到达并结束时
  _onDropDownComplete() {
    _refreshBound(curBrick);

    //变成固定图
    displayController.pushStateList(curBrick.plist, getState: (data) {
      return data..state = PointState.FIXED;
    });
    displayController.refresh();

    if (_checkGameOver()) {
      stopGame();
      stateNotifier.value = GameState.GAME_OVER;
      LogPrint('Game over');
      return;
    }

    if (_checkRowFull()) {
      return;
    }
    _resetBrick();
    //每次都得以主要速度开始
    setMainRunning();
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

  List<int> fullRows = [];

  //下落帧
  _performDropDownFrame(o) {
    LogPrint('task', '_performDropDownFrame');
    Set<Brick> _wouldMoveDownBricks = o ?? {};
    List<Brick> list = _wouldMoveDownBricks.toList();

    for (var brick in list) {
      if (_canMoveDown(brick)) {
        displayController.pushOffsetList(brick.plist, offsetY: 1);
        displayController.refresh();
        brick.moveOffset(y: 1);
      } else {
        _wouldMoveDownBricks.remove(brick);
        displayController.pushStateList(brick.plist, getState: (data) {
          return data..state = PointState.FIXED;
        });
        displayController.refresh();
      }
    }
    if (_wouldMoveDownBricks.isNotEmpty) {
      _task.add(_performDropDownFrame, _wouldMoveDownBricks);
    }
  }

  //消耗电池
  _performConsumeEnergy() {
    LogPrint('task', '_performConsumeEnergyFrame');
    //变成电量电池
    displayController.pushStateRow(fullRows, getState: (data) {
      return data
        ..state = PointState.FULL
        ..energyLevel = BatteryView.energyTotalCount;
    });
    displayController.refresh();

    consumeEnergy(o) {
      var level = 0;
      displayController.pushStateRow(fullRows, getState: (data) {
        level = --data.energyLevel;
        return data;
      });
      displayController.refresh();
      LogPrint('task', 'consumeEnergy level=${level}');
      if (level > 0) {
        _task.add(consumeEnergy);
      } else {
        _task.add(_dismissFullRowsFrame);
      }
    }

    _task.add(consumeEnergy);
  }

  _dismissFullRowsFrame(o) {
    LogPrint('task', '_dismissFullRowsFrame');
    displayController.pushStateRow(fullRows, getState: setLightOff);
    displayController.refresh();

    var checkBottom = 0;
    for (var i in fullRows) {
      checkBottom = i > checkBottom ? i : checkBottom;
    }

    Set<Brick> _wouldMoveDownBricks = {};
    _lookupAroundTemp.clear();
    for (int x = 0; x < displayController.row; x++) {
      for (int y = top; y < checkBottom; y++) {
        var matrixPoint = displayController.getPoint(x, y);
        if (matrixPoint != null &&
            matrixPoint.data.light &&
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
    if (_wouldMoveDownBricks.isNotEmpty) {
      _task.add(_performDropDownFrame, _wouldMoveDownBricks);
    }
    fullRows.clear();
  }

  //检查是否有满行
  bool _checkRowFull() {
    fullRows = displayController.lookupFullRowsIndex();
    if (fullRows.isEmpty) {
      return false;
    }
    LogPrint('吃 rows=$fullRows');
    var score = fullRows.length;
    scoreNotifier.value += score;
    _checkChangeSpeed(score);

    stateNotifier.value=GameState.GOAL;

    setMiddleRunning();

    _performConsumeEnergy();
    return true;
  }

  _checkChangeSpeed(int score) {
    _increaseSpeedCountTemp += score;
    //检查是否增加速度,
    if (_increaseSpeedCountTemp > _increaseSpeedCountThreshold) {
      _increaseSpeedCountTemp = 0;
      if (curSpeed > _minSpeed) {
        curSpeed -= speedStep;
        setMainRunning();
        speedNotifier.value = speedDescriber;
      }
    }
  }

  _resetSpeed() {
    _increaseSpeedCountTemp = 0;
    curSpeed = SpeedType.normal.value;
    lastSpeed = null;
    speedNotifier.value = speedDescriber;
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
      if (neighbor.data.light && !_lookupAroundTemp.contains(neighbor)) {
        var l = _getAroundLightPoints(neighbor);
        global.addAll(l);
      }
    }

    return global;
  }

  _refreshBound(Brick brick) {
    top = brick.top < top ? brick.top : top;
  }

  GroupBrick _getRandomGroupBrick() {
    var bricks = SettingState.single.bricks;
    var g = Random().nextInt(bricks.length);
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
    if (state != GameState.RUNNING) {
      return;
    }
    if (_canMoveLeft(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: -1);
      displayController.refresh();
      curBrick.moveOffset(x: -1);
    }
  }

  void moveRight() {
    if (state != GameState.RUNNING) {
      return;
    }
    if (_canMoveRight(curBrick)) {
      displayController.pushOffsetList(curBrick.plist, offsetX: 1);
      displayController.refresh();
      curBrick.moveOffset(x: 1);
    }
  }

  bool moveDown() {
    if (state != GameState.RUNNING) {
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
    if (state != GameState.RUNNING) {
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
    displayController.pushStateList(curBrick.plist,getState: setLightOn);
    displayController.refresh();
  }

  void dispose() {
    displayController.dispose();
  }
}

enum SpeedType {
  normal(Duration(milliseconds: 1000)),
  middle(Duration(milliseconds: 140)),
  fast(Duration(milliseconds: 40));

  const SpeedType(this.value);

  final Duration value;
}

enum GameState { READY, RUNNING, STOP, CLEARING, GOAL,GAME_OVER }
