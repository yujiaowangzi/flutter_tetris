
import "package:flutter/cupertino.dart";

import "log/logger.dart";

class LayoutPrintWidget<T> extends StatelessWidget {
  const LayoutPrintWidget({
    Key? key,
    this.tag,
    this.child,
  }) : super(key: key);

  final Widget? child;
  final T? tag; //指定日志tag

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, cs) {
      // assert在编译release版本时会被去除
      assert(() {
        LogPrint("${tag ?? key ?? child?.runtimeType??"parent"} constraints: ${cs.minWidth} < width <${cs.maxWidth} | ${cs.minHeight} < height <${cs.maxHeight}");
        return true;
      }());
      return child??const SizedBox();
    });
  }
}