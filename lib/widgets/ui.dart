import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/setting_state.dart';

class StateUI extends StatelessWidget {
  StateUI({super.key, this.state = GameState.READY});

  GameState state;

  _readyView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Welcome',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen),
        ),
        const SizedBox(
          height: 10,
        ),
        Text.rich(TextSpan(text: '按', children: [
          TextSpan(
              text: Platform.isWindows ? ' Enter ' : '',
              style: TextStyle(color: SettingState.primaryColor)),
          const TextSpan(text: '键开始')
        ]))
      ],
    );
  }

  _stopView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '暂停',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen),
        ),
        const SizedBox(
          height: 10,
        ),
        Text.rich(TextSpan(text: '按', children: [
          TextSpan(
              text: Platform.isWindows ? ' Enter ' : '',
              style: TextStyle(color: SettingState.primaryColor)),
          const TextSpan(text: '键开始')
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
              color: Colors.grey),
        ),
        const SizedBox(
          height: 10,
        ),
        Text.rich(TextSpan(text: '按', children: [
          TextSpan(
              text: Platform.isWindows ? ' Shift + Enter ' : '重置',
              style: TextStyle(color: SettingState.primaryColor)),
          const TextSpan(text: '键重置')
        ]))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: () {
        switch (state) {
          case GameState.READY:
            return _readyView();
          case GameState.STOP:
            return _stopView();
          case GameState.GAME_OVER:
            return _gameOverView();
          default:
            return null;
        }
      }(),
    );
  }
}
