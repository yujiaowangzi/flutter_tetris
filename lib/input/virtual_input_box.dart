import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/input/action_input_box.dart';

import '../utils/log/logger.dart';

class VirtualInputBox extends ActionInputBox {
  VirtualInputBox({super.key, super.controller});

  double _haftSize = 55;
  double _spaceSize = 5;

  double get _holdSize => 2 * _haftSize + _spaceSize;

  Timer? _crossMoveTimer;

  _moveFast(bool right) {
    _crossMoveTimer?.cancel();
    _crossMoveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (right) {
        moveRight();
      } else {
        moveLeft();
      }
    });
  }

  _getDirectButtons() {
    return FittedBox(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _haftSize,
                height: _holdSize,
                child: GestureDetector(
                  onLongPress: () {
                    _moveFast(false);
                  },
                  onLongPressUp: () {
                    _crossMoveTimer?.cancel();
                  },
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_outlined,
                      size: _iconSize,
                      color: _buttonIconColor,
                    ),
                    onPressed: () {
                      moveLeft();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll(_buttonBackgroundColor),
                        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_haftSize),
                          bottomLeft: Radius.circular(_haftSize),
                        )))),
                  ),
                ),
              ),
              SizedBox(width: _spaceSize),
              SizedBox(
                width: _haftSize,
                height: _holdSize,
                child: GestureDetector(
                  onLongPress: () {
                    _moveFast(true);
                  },
                  onLongPressUp: () {
                    _crossMoveTimer?.cancel();
                  },
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: _iconSize,
                      color: _buttonIconColor,
                    ),
                    onPressed: () {
                      moveRight();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll(_buttonBackgroundColor),
                        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                          topRight: Radius.circular(_haftSize),
                          bottomRight: Radius.circular(_haftSize),
                        )))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _getRightButton() {
    return FittedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: _haftSize,
                height: _haftSize,
                child: IconButton(
                  padding: const EdgeInsets.only(top: 7, left: 7),
                  icon: Icon(
                    Icons.skip_previous_outlined,
                    size: _iconSize,
                    color: _buttonIconColor,
                  ),
                  onPressed: () {
                    controller?.changeShape(next: false);
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(_buttonBackgroundColor),
                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_haftSize),
                        // bottomLeft: Radius.circular(_haftSize),
                      )))),
                ),
              ),
              SizedBox(
                width: _spaceSize,
              ),
              SizedBox(
                width: _haftSize,
                height: _haftSize,
                child: IconButton(
                  padding: const EdgeInsets.only(top: 7, right: 7),
                  icon: Icon(
                    Icons.skip_next_outlined,
                    size: _iconSize,
                    color: _buttonIconColor,
                  ),
                  onPressed: () {
                    controller?.changeShape();
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(_buttonBackgroundColor),
                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                        topRight: Radius.circular(_haftSize),
                        // bottomRight: Radius.circular(_haftSize),
                      )))),
                ),
              ),
            ],
          ),
          SizedBox(height: _spaceSize),
          SizedBox(
            width: 2 * _haftSize + _spaceSize,
            height: _haftSize,
            child: GestureDetector(
              onLongPress: () {
                fastSpeedMove();
              },
              onLongPressDown: (_) {
                // LogPrint('down','onLongPressDown');
              },
              onLongPressUp: () {
                normalSpeedMove();
              },
              child: IconButton(
                icon: Icon(
                  Icons.keyboard_double_arrow_down,
                  size: _iconSize,
                  color: _buttonIconColor,
                ),
                onPressed: () {
                  fastSpeedMove();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStatePropertyAll(_buttonBackgroundColor),
                  shape: MaterialStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(_haftSize),
                        bottomRight: Radius.circular(_haftSize),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _buttonBackgroundColor = Color(0xAAdddddd);
  Color _buttonIconColor = Color(0xAA999999);
  double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _getDirectButtons(),
        _getRightButton(),
      ],
    );
  }
}
