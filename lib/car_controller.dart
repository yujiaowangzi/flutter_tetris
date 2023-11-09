import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tetris/utils/log/logger.dart';

class CarController extends ValueNotifier {
  CarController(this.animationController) : super(Void);

  AnimationController animationController;

  int _energy = 0;

  int get energy => _energy;

  static const energyPerScore = 9;

  //电池最大容量
  static const maxSpeedEnergyThreshold = 100;

  double _distance = 0;
  DateTime? _lastTime;

  String get distance => _distance.toStringAsFixed(2);

  final _maxMilliseconds = 4000;
  final _minMilliseconds = 10;

  //km/h
  final int maxSpeed = 298;
  final int minSpeed = 30;
  double _curSpeed = 0;
  double _lastSpeed = 0;

  int get speed => _curSpeed.toInt();

  int _lastMilliseconds = 0;

  double getSpeedByEnergy(int energy) {
    if (energy == 0) {
      return 0;
    }
    if (energy > maxSpeedEnergyThreshold) {
      return maxSpeed.toDouble();
    }
    //二次函数增加
    var speed = (minSpeed - maxSpeed) /
            pow(energyPerScore - maxSpeedEnergyThreshold, 2) *
            pow(energy - maxSpeedEnergyThreshold, 2) +
        maxSpeed;
    return speed < minSpeed ? minSpeed.toDouble() : speed;
  }

  int getMilliseconds(double speed) {
    if (speed == 0) {
      return 0;
    }
    var speedMillisecond = (_maxMilliseconds - _minMilliseconds) /
            pow(maxSpeed, 2) *
            pow(speed - maxSpeed, 2) +
        _minMilliseconds; //二次函数减少
    return speedMillisecond.toInt();
  }

  int getEnergyByScore(int score) {
    return score * energyPerScore;
  }

  Timer? timer;

  startRepeatRefresh() {
    if (timer?.isActive ?? false) {
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _refresh();
    });
  }

  stopRepeatRefresh() {
    timer?.cancel();
  }

  _refresh() {
    var changeDistance = _calcDistance(_curSpeed);
    _consumeEnergy(changeDistance);

    _curSpeed = getSpeedByEnergy(_energy);

    notifyListeners();

    if (_curSpeed == _lastSpeed) {
      return;
    }
    _lastSpeed = _curSpeed;

    var curMilliseconds = getMilliseconds(_curSpeed);
    LogPrint(
        'speed=$_curSpeed distance=$distance curMilliseconds=$curMilliseconds');
    if (curMilliseconds != 0 && curMilliseconds == _lastMilliseconds) {
      return;
    }
    _lastMilliseconds = curMilliseconds;
    if (curMilliseconds > 0) {
      animationController.repeat(
          period: Duration(milliseconds: curMilliseconds));
    } else {
      animationController.stop();
    }
  }

  double _calcDistance(double speed) {
    var now = DateTime.now();
    if (_lastTime == null) {
      _lastTime = now;
      return 0;
    }
    var duration = now.difference(_lastTime!);
    var change = (duration.inSeconds / 3600 * speed);
    _distance += change;
    _lastTime = now;
    return change;
  }

  double _consumeEnergyTemp = 0;
  static const double consumeEnergyPer1Km = 20;

  //计算油耗
  _consumeEnergy(double dis) {
    if (dis == 0) {
      return;
    }
    _consumeEnergyTemp += dis * consumeEnergyPer1Km;

    int consumeEnergyCount = _consumeEnergyTemp.floor();
    if (consumeEnergyCount > 0) {
      _energy -= consumeEnergyCount;
      LogPrint('消耗energy=$consumeEnergyCount 剩余=$_energy');
      _refresh();
    }
    _consumeEnergyTemp -= consumeEnergyCount;
  }

  addScore(int score) {
    if (score == 0) {
      return;
    }
    _energy += getEnergyByScore(score);
    LogPrint('充电=$_energy score=$score');
    _refresh();
    startRepeatRefresh();
  }

  void clean() {
    _curSpeed = 0;
    _lastSpeed = 0;
    _distance = 0;
    _lastTime = null;
    _lastMilliseconds = 0;
    _energy = 0;
    _consumeEnergyTemp = 0;
    animationController.stop();
    stopRepeatRefresh();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    clean();
    LogPrint('dispose');
  }
}
