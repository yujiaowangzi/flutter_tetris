
import 'package:flutter/material.dart';
import 'package:flutter_tetris/input/action_input_box.dart';

import '../utils/log/logger.dart';

class VirtualInputBox extends ActionInputBox{
  VirtualInputBox({super.key,super.controller}){
    controller?.setRunningListener((r) {
      _buttonNotifier.value = r;
    });
  }

  final ValueNotifier<bool> _buttonNotifier = ValueNotifier(false);

  _getDirectButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getAIconButton(
                onPressed: () {
                  moveLeft();
                },
                iconData: Icons.arrow_back),
            const SizedBox(width: 20),
            _getAIconButton(
                onPressed: () {
                  moveRight();
                },
                iconData: Icons.arrow_forward),
          ],
        ),
        const SizedBox(width: 10),
        Center(
          child: GestureDetector(
            onLongPress: () {
              // controller.startFastRunning();
              LogPrint('onLongPress');
            },
            onLongPressCancel: () {
              // controller.startMainRunning();
              LogPrint('onLongPressCancel');
            },
            child: IconButton(
                onPressed: () {
                  LogPrint('onPressed');
                  fastMove();
                },
                icon: const Icon(Icons.arrow_downward)),
          ),
        )
      ],
    );
  }

  _getAIconButton(
      {required IconData iconData, required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(iconData),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _buttonNotifier,
      builder: (_, value, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _getDirectButtons(),
            _getAIconButton(
              iconData: Icons.cached,
              onPressed: () {
                change2Next();
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getAIconButton(
                  iconData: value
                      ? Icons.stop_circle_outlined
                      : Icons.play_arrow_outlined,
                  onPressed: () {
                    if (controller?.isStart??false) {
                      stop();
                    } else {
                      start();
                    }
                  },
                ),
                _getAIconButton(
                  iconData: Icons.exit_to_app,
                  onPressed: () {
                    completeStop();
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }

}