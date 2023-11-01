import 'dart:async';
import 'dart:collection';

import 'package:flutter/animation.dart';
import 'package:flutter_tetris/common/functions.dart';
import 'package:flutter_tetris/utils/log/logger.dart';

class PeriodicTask {
  PeriodicTask(this.runnable);

  bool _start = false;
  Timer? _timer;
  Duration? _intervalTime;
  final Queue<Runnable> _taskQueue = Queue();
  Runnable runnable;

  void setInterval(Duration time) {
    _intervalTime = time;
    if (_start && _timer != null&&_timer!.isActive) {
      _timer!.cancel();
      _doStart();
    }
  }

  void start() {
    if (_start||_intervalTime == null) {
      return;
    }
    _start = true;
    _doStart();
    _run();
  }

  _doStart(){
    _timer = Timer.periodic(_intervalTime!,(timer){
      if (!_start) {
        return;
      }
      _run();
    });
  }

  void stop() {
    _start = false;
    _timer?.cancel();
    _timer = null;
  }

  void addMicroTask(Runnable task){
    _taskQueue.addLast(task);
  }

  _run() async {
    if (_taskQueue.isNotEmpty) {
      _taskQueue.first.call();
      _taskQueue.removeFirst();
      return;
    }
    runnable.call();
  }
}