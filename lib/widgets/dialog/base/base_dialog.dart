import "package:flutter/material.dart";

import "base_decorated_widget.dart";

class BaseDialog<R> extends BaseDecoratedWidget {
  BaseDialog({
    super.key,
    this.dismissWhenTouch = true,
    this.barrierColor=Colors.transparent,
    super.backgroundColor,
    super.primaryColor,
    super.padding,
    super.child,
  });

  BuildContext? context;
  bool dismissWhenTouch;
  Color barrierColor;

  Future<R?> show(BuildContext context) async {
    return showDialog<R>(
      barrierColor: barrierColor,
      barrierDismissible: dismissWhenTouch,
      context: context,
      builder: (context) {
        this.context=context;
        return WillPopScope(
          onWillPop: () {
            return Future<bool>.value(dismissWhenTouch);
          },
          child: Dialog(
            shadowColor: backgroundColor,
            backgroundColor: backgroundColor,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: this,
            ),
          ),
        );
      },
    );
  }

  cancel() {
    if (context != null && ((context!.findRenderObject()?.attached) ?? false)) {
      Navigator.pop(context!);
    }
  }
}

typedef DialogTap=void Function(BuildContext context);
