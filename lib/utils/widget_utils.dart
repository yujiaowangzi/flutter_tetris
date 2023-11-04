import "package:flutter/scheduler.dart";

class WidgetUtil {
  WidgetUtil._();

  static SchedulerPhase saveUpdate(VoidCallback fn) {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      onPostFrame(fn);
    } else {
      fn.call();
    }
    return schedulerPhase;
  }

  static onPostFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fn.call();
    });
  }
}
