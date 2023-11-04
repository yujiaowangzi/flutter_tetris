import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/input/desktop_input_box.dart';
import 'package:flutter_tetris/input/virtual_input_box.dart';

abstract class ActionInputBox extends StatelessWidget {
  GameController? controller;

  ActionInputBox({super.key, this.controller});

  static get({GameController? controller}) {
    if (Platform.isWindows) {
      return Stack(
        children: [
          DesktopInputBox(
            controller: controller,
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: VirtualInputBox(
                controller: controller,
              ),
            ),
          ),
        ],
      );
    }
    return VirtualInputBox(
      controller: controller,
    );
  }

  void moveDown() {
    controller?.moveDown();
  }

  void moveLeft() {
    controller?.moveLeft();
  }

  void moveRight() {
    controller?.moveRight();
  }

  void fastMove() {
    controller?.setFastRunning();
  }

  void resetMoveDown() {
    controller?.setMainRunning();
  }

  void change2Next() {
    controller?.changeShape();
  }

  void change2Last() {
    controller?.changeShape(next: false);
  }

  void start() {
    controller?.startGame();
  }

  void stop() {
    controller?.stopGame();
  }

  void startOrStop() {
    controller?.startOrStop();
  }

  void completeStop() {
    controller?.completelyStop();
  }
}
