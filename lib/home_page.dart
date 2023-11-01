import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tetris/game_controller.dart';
import 'package:flutter_tetris/input/action_input_box.dart';
import 'package:flutter_tetris/matrix_widget.dart';
import 'package:flutter_tetris/widgets/ratio_box.dart';
import 'package:flutter_tetris/widgets/square_box.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameController controller = GameController();


  _getInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder(
        valueListenable: controller.panelController,
        builder: (_, value, child) {
          return DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SquareBox(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 1)),
                      child: child!),
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
                              color: Colors.blue),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const FittedBox(
                  child: Text('排行榜: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.h),
                    child: ListView.builder(
                      itemCount: 1,
                      itemBuilder: (_, i) {
                        return const FittedBox(
                          child: Text.rich(TextSpan(
                              text: '罗小帅 : ',
                              children: [TextSpan(text: '837289 分')])),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: MatrixView(
          controller: controller.nextDisplayCtrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int matrixX = controller.displayController.row;
    int matrixY = controller.displayController.colum;
    var hr = matrixY + matrixY / 6;
    var wr = matrixX + matrixX / 3; // 方块:信息面板 = 3:1
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: GestureDetector(
          child: const Text('测试...'),
          onTap: () async{

          },
        ),
      ),
      body: Center(
        child: RatioSizeBox(
          widthRadio: wr,
          heightRadio: hr.toDouble(),
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 1)),
                        child: MatrixView(
                          controller: controller.displayController,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _getInfoPanel(),
                    ),
                  ],
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
}
