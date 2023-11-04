import 'package:flutter/material.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/input/action_input_box.dart';

import '../utils/log/logger.dart';

class VirtualInputBox extends ActionInputBox {
  VirtualInputBox({super.key, super.controller}) {
    controller?.addListener((r) {
      _buttonNotifier.value = r;
    });
  }

  final ValueNotifier<GameState> _buttonNotifier =
      ValueNotifier(GameState.READY);

  _getDirectButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 45,
          height: 95,
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
                shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topLeft:
                      Radius.circular(45), bottomLeft: Radius.circular(45)
                )))),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 45,
          height: 95,
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
                shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topRight:
                      Radius.circular(45), bottomRight: Radius.circular(45)
                )))),
          ),
        ),
      ],
    );
  }

  _getRightButton(){
    return FittedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: IconButton(
                  padding: const EdgeInsets.only(top: 7,left: 7),
                  icon: Icon(
                    Icons.skip_previous_outlined,
                    size: _iconSize,
                    color: _buttonIconColor,
                  ),
                  onPressed: () {
                    controller?.changeShape(next: false);
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          _buttonBackgroundColor),
                      shape: const MaterialStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(45),
                              )))),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              SizedBox(
                width: 45,
                height: 45,
                child: IconButton(
                  padding: const EdgeInsets.only(top: 7,right: 7),
                  icon: Icon(
                    Icons.skip_next_outlined,
                    size: _iconSize,
                    color: _buttonIconColor,
                  ),
                  onPressed: () {
                    controller?.changeShape();
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          _buttonBackgroundColor),
                      shape: const MaterialStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(45),
                              )))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 95,
            height: 45,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_double_arrow_down,
                size: _iconSize,
                color: _buttonIconColor,
              ),
              onPressed: () {
                fastMove();
              },
              style: ButtonStyle(
                  backgroundColor:
                  MaterialStatePropertyAll(_buttonBackgroundColor),
                  shape: const MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(45),
                              bottomRight: Radius.circular(45))))),
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
    return ValueListenableBuilder(
      valueListenable: _buttonNotifier,
      builder: (_, value, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _getDirectButtons(),
            _getRightButton(),
          ],
        );
      },
    );
  }
}
