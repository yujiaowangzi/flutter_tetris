import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/input/action_input_box.dart';
import 'package:flutter_tetris/setting_state.dart';
import 'package:flutter_tetris/utils/layout_print_widget.dart';
import 'package:flutter_tetris/utils/utils.dart';
import 'package:flutter_tetris/widgets/matrix_widget.dart';
import 'package:flutter_tetris/utils/widget_utils.dart';
import 'package:flutter_tetris/widgets/dialog/dialog.dart';
import 'package:flutter_tetris/widgets/ratio_box.dart';
import 'package:flutter_tetris/widgets/square_box.dart';
import 'package:flutter_tetris/widgets/ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameController controller = GameController();
  ValueNotifier<GameState> stateNotifier = ValueNotifier(GameState.READY);

  _getInfoPanel() {
    return ValueListenableBuilder(
      valueListenable: controller.panelController,
      builder: (_, value, child) {
        return DefaultTextStyle(
          style: const TextStyle(color: Colors.black, fontSize: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBox(
                child: child!,
              ),
              const SizedBox(height: 16),
              FittedBox(
                child: Text.rich(
                  TextSpan(
                    text: '分数：',
                    children: [
                      TextSpan(
                        text: '${value.score}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const FittedBox(
                child: Text(
                  '排行榜: ',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 120.h),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: 1,
                    itemBuilder: (_, i) {
                      return const FittedBox(
                        child: Text.rich(
                          TextSpan(
                            text: '罗小帅 : ',
                            children: [TextSpan(text: '837289 分')],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: stateNotifier,
                builder: (_, value, child) {
                  return Align(
                    child: FittedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getButton('重置', () {
                            controller.completelyStop();
                          }),
                          const SizedBox(height: 10),
                          _getButton(
                            value == GameState.RUNNING ? "暂停" : '开始',
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
      },
      child: MatrixView(
        controller: controller.nextDisplayCtrl,
      ),
    );
  }

  _getButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
        onPressed: onPressed,
        child: Text(text,style: const TextStyle(color: Colors.black87,fontSize: 12),));
  }

  void stateCallback(state) {
    stateNotifier.value = state;
  }

  @override
  void initState() {
    super.initState();
    /*WidgetUtil.onPostFrame(() {
      WelcomeDialog().show(context);
    });*/
    controller.addListener(stateCallback);
  }

  @override
  Widget build(BuildContext context) {
    int matrixX = controller.displayController.row;
    int matrixY = controller.displayController.colum;
    // var hr = matrixY + matrixY / 6;
    var wr = matrixX + matrixX / 3; // 方块:信息面板 = 3:1
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
                              valueListenable: stateNotifier,
                              builder: (_, value, child) {
                                return StateUI(state: value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: _getInfoPanel(),
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
