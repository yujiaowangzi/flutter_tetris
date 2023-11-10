import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/car_controller.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/global/setting_state.dart';
import 'package:flutter_tetris/utils/utils.dart';

class StateUI extends StatelessWidget {
  StateUI({super.key, this.getIncreaseScore,this.state = GameState.READY});

  GameState state;
  int Function()? getIncreaseScore;

  _readyView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Let\'s Go',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen),
        ),
        const SizedBox(
          height: 10,
        ),
        Text.rich(TextSpan(text: lt.press, children: [
          TextSpan(
              text: Platform.isWindows ? ' Enter' : '',
              style: TextStyle(color: SettingState.primaryTextColor1)),
          TextSpan(text: ' ${lt.button} ${lt.start}')
        ]))
      ],
    );
  }

  _stopView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lt.stop,
          style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen),
        ),
        const SizedBox(
          height: 10,
        ),
        Text.rich(TextSpan(text: lt.press, children: [
          TextSpan(
              text: Platform.isWindows ? ' Enter' : '',
              style: TextStyle(color: SettingState.primaryTextColor1)),
          TextSpan(text: ' ${lt.button} ${lt.start}')
        ]))
      ],
    );
  }

  _gameOverView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'GAME OVER',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent),
        ),
        const SizedBox(
          height: 10,
        ),
        DefaultTextStyle(
          style: const TextStyle(color: Colors.grey),
          child: Text.rich(TextSpan(text: lt.press, children: [
            TextSpan(
                text: Platform.isWindows ? ' Shift + Enter' : ' ${lt.reset} ',
                style: const TextStyle(color: Colors.black)),
            TextSpan(text: ' ${lt.button} ${lt.reset}')
          ])),
        )
      ],
    );
  }

  _goal(int score) {
    var text1;
    var text1Color;
    if (score == 1) {
      text1 = 'Go on';
      text1Color = Colors.blue;
    } else if (score == 2) {
      text1 = "Good";
      text1Color = Colors.purpleAccent;
    } else if (score > 2) {
      text1 = 'Perfect';
      text1Color = Colors.orange;
    } else {
      return null;
    }
    return DefaultTextStyle(
      style: TextStyle(color: text1Color, fontWeight: FontWeight.bold),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text1,
            style: TextStyle(fontSize: 30, color: text1Color),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            '+ ${score * CarController.energyPerScore}',
            style: const TextStyle(fontSize: 14),
          )
        ],
      ),
    );
  }

  Widget? getStateWidget(){
    switch (state) {
      case GameState.READY:
        return _readyView();
      case GameState.STOP:
        return _stopView();
      case GameState.GOAL:
        return _goal(getIncreaseScore?.call() ?? 0);
      case GameState.GAME_OVER:
        return _gameOverView();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: getStateWidget(),
    );
  }
}
