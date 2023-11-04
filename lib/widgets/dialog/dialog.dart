import 'package:flutter/material.dart';
import 'package:flutter_tetris/widgets/dialog/base/base_dialog.dart';

class WelcomeDialog extends BaseDialog {
  WelcomeDialog({super.key}):super(backgroundColor: Colors.transparent);

  @override
  Widget content(BuildContext context) {
    return const Center(
        child: Text(
      'Welcome',
      style: TextStyle(
          fontSize: 30, fontWeight: FontWeight.bold, color: Colors.lightGreen),
    ));
  }
}
