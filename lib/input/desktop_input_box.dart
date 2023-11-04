import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tetris/input/action_input_box.dart';

class DesktopInputBox extends ActionInputBox {
  DesktopInputBox({super.key, super.controller});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveLeftIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _MoveRightIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            _Change2NextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): _Change2LastIntent(),
        const SingleActivator(LogicalKeyboardKey.space): _FastMoveDownIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): _StartOrStopIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
            _CompletelyStopIntent(),
      },
      child: Actions(
        actions: {
          _MoveLeftIntent: CallbackAction(onInvoke: (intent) {
            moveLeft();
          }),
          _MoveRightIntent: CallbackAction(onInvoke: (intent) {
            moveRight();
          }),
          _FastMoveDownIntent: CallbackAction(onInvoke: (intent) {
            fastMove();
          }),
          _Change2NextIntent: CallbackAction(onInvoke: (intent) {
            change2Next();
          }),
          _Change2LastIntent: CallbackAction(onInvoke: (intent) {
            change2Last();
          }),
          _StartOrStopIntent: CallbackAction(onInvoke: (intent) {
            startOrStop();
          }),
          _CompletelyStopIntent: CallbackAction(onInvoke: (intent) {
            completeStop();
          }),
        },
        child: Focus(
            autofocus: true,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: DefaultTextStyle(
                style: const TextStyle(fontSize: 16,color: Colors.black54),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    child: Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('开始/暂停：Enter '),
                              Text('重开：Shift + Enter '),
                              Text('速降：Space '),
                            ]),
                        SizedBox(width: 16.h,),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('右移：Right '),
                            Text('右移：Right '),
                            Text('变换：Up/Down '),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}

class _MoveLeftIntent extends Intent {}

class _MoveRightIntent extends Intent {}

class _FastMoveDownIntent extends Intent {}

class _Change2NextIntent extends Intent {}

class _Change2LastIntent extends Intent {}

class _StartOrStopIntent extends Intent {}

class _CompletelyStopIntent extends Intent {}
