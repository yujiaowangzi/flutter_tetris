import 'dart:async';
import 'dart:collection';

import 'package:flutter_tetris/utils/log/logger.dart';

class PeriodicTask {
  PeriodicTask({this.mainTask});

  bool _start = false;
  Timer? _timer;
  Duration? _intervalTime;
  final Queue<_TaskEntity> _runnables=Queue();
  void Function()? mainTask;

  void add<T>(_Runnable task,[T? param]){
    _runnables.addLast(_TaskEntity<T>(task,param));
  }

  void setInterval(Duration time) {
    _intervalTime = time;
    if (_start && _timer != null&&_timer!.isActive) {
      _timer!.cancel();
      _timeStart();
    }
  }

  void start() {
    if (_start||_intervalTime == null) {
      return;
    }
    _start = true;
    _invokeTask();
    _timeStart();
  }

  _invokeTask(){
    if (_runnables.isNotEmpty) {
      var task=_runnables.first;
      _runnables.removeFirst();
      task.runnable.call(task.param);
    }else{
      mainTask?.call();
    }
  }

  _timeStart(){
    _timer = Timer.periodic(_intervalTime!,(timer){
      if (!_start) {
        return;
      }
      _invokeTask();
    });
  }

  void stop() {
    _start = false;
    _timer?.cancel();
    _timer = null;
  }

  void clean(){
    stop();
    _runnables.clear();
  }
}

typedef _Runnable=void Function(Object? param);

class _TaskEntity<T>{
  _TaskEntity(this.runnable,[this.param]);
  _Runnable runnable;
  T? param;
}