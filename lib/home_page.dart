import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_tetris/car_controller.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/global/setting_state.dart';
import 'package:flutter_tetris/global/sp_key.dart';
import 'package:flutter_tetris/input/action_input_box.dart';
import 'package:flutter_tetris/utils/data_time_help.dart';
import 'package:flutter_tetris/utils/log/logger.dart';
import 'package:flutter_tetris/utils/widget_utils.dart';
import 'package:flutter_tetris/widgets/battery_store_view.dart';
import 'package:flutter_tetris/widgets/battery_view.dart';
import 'package:flutter_tetris/widgets/matrix_widget.dart';
import 'package:flutter_tetris/widgets/ratio_box.dart';
import 'package:flutter_tetris/widgets/square_box.dart';
import 'package:flutter_tetris/widgets/ui.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin<HomePage> {
  GameController controller = GameController();

  ValueNotifier<int> timeCountNotifier = ValueNotifier(0);

  Timer? timer;

  int seconds = 0;

  _startCountTime() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeCountNotifier.value = ++seconds;
    });
  }

  _stopCountTime() {
    timer?.cancel();
  }

  _resetCountTime() {
    timer?.cancel();
    timeCountNotifier.value = seconds = 0;
  }

  SharedPreferences? sp;

  late CarController carController;

  _getInfoPanel() {
    return DefaultTextStyle(
      style: TextStyle(color: SettingState.primaryTextColor3, fontSize: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder(
            valueListenable: controller.scoreNotifier,
            builder: (_, value, child) {
              return FittedBox(
                child: Text.rich(
                  TextSpan(
                    text: '分数：',
                    style: TextStyle(color: SettingState.primaryTextColor1),
                    children: [
                      TextSpan(
                        text: value.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: timeCountNotifier,
            builder: (_, value, child) {
              return FittedBox(
                child: Text(
                    '时间：${DateTimeHelp.getFormatStringBySecond(value) ?? 0}',
                    style: const TextStyle(color: Color(0xff999999))),
              );
            },
          ),
          ValueListenableBuilder(
              valueListenable: controller.speedNotifier,
              builder: (_, value, child) {
                return FittedBox(
                  child: Text('速度：${controller.speedDescriber}',
                      style: const TextStyle(color: Color(0xff999999))),
                );
              }),
          const SizedBox(height: 6),
          SquareBox(
              child: MatrixView(
            controller: controller.nextDisplayCtrl,
          )),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              carController.addScore(1);
            },
            child: Lottie.asset('assets/lottie_car_loading.json',
                controller: carController.animationController),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder(
            valueListenable: carController,
            builder: (_, value, child) {
              return FittedBox(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('车速：${carController.speed} km/h',style: TextStyle(color: carController.speed>150?Colors.red:Colors.blue)),
                  Text('电量：${carController.energy/10} kW.h',style: const TextStyle(color: Colors.orangeAccent)),
                  Text('里程：${carController.distance} km',style: const TextStyle(color: Colors.green)),
                ],
              ));
            },
          ),
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: controller.scoreNotifier,
            builder: (_, value, child) {
              var score = 0;
              var time = '';
              if (sp != null) {
                score = sp!.getInt(SPKey.score_record) ?? 0;
                time = sp!.getString(SPKey.date_time_record) ?? '';
                if (value > score) {
                  score = value;
                  time = DateTime.now().toString().substring(0, 16);
                  sp!.setInt(SPKey.score_record, score);
                  sp!.setString(SPKey.date_time_record, time);
                }
              } else {
                SharedPreferences.getInstance().then((value) {
                  setState(() {
                    sp = value;
                  });
                });
              }
              return FittedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本机记录: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: SettingState.primaryTextColor1),
                    ),
                    const SizedBox(height: 6),
                    Text('分数：$score'),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                          color: Color(0xff999999), fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: controller.stateNotifier,
            builder: (_, value, child) {
              return Align(
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getButton('重置', () {
                        controller.reset();
                      }),
                      const SizedBox(height: 10),
                      _getButton(
                        value == GameState.READY||value==GameState.STOP ?  '开始': "暂停",
                        () {
                          controller.startOrStop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  _getButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(color: SettingState.primaryTextColor1, fontSize: 12),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    carController = CarController(AnimationController(vsync: this));
    controller.stateNotifier.addListener(() {
      var state = controller.stateNotifier.value;
      if (state == GameState.RUNNING) {
        _startCountTime();
      } else if (state == GameState.CLEARING) {
        _resetCountTime();
        carController.clean();
      } else if (state == GameState.GAME_OVER) {
      } else {
        _stopCountTime();
      }
    });
    controller.scoreNotifier.addListener(() {
      var increase=controller.increaseScore;
      if (increase>0) {
        carController.addScore(increase);
      }
    });

    WidgetUtil.onPostFrame(() {
      controller.animationCleanMatrix();
    });
  }

  @override
  Widget build(BuildContext context) {
    int matrixX = controller.displayController.row;
    int matrixY = controller.displayController.colum;
    // var hr = matrixY + matrixY / 6;
    var wr = matrixX + matrixX / 3; // 方块:信息面板 = 3:1
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Expanded(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: RatioSizeBox(
                        widthRadio: wr,
                        heightRadio: matrixY.toDouble(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  MatrixView(
                                    controller: controller.displayController,
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: controller.stateNotifier,
                                    builder: (_, value, child) {
                                      return StateUI(state: value,getIncreaseScore: (){
                                        return controller.increaseScore;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: SettingState.primaryTextColor3),
                                        right: BorderSide(color: SettingState.primaryTextColor3),
                                        bottom: BorderSide(color: SettingState.primaryTextColor3),
                                      ),
                                    ),
                                    width: 10,
                                    height: double.infinity,
                                    child: ValueListenableBuilder(
                                      valueListenable: carController,
                                      builder: (_, value, child) {
                                        return BatteryStoreView(
                                            energyShowCount:
                                                carController.energy);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: _getInfoPanel()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ActionInputBox.get(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    _stopCountTime();
    carController.dispose();
  }
}
