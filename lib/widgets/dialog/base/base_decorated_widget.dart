import "package:flutter/material.dart";

class BaseDecoratedWidget extends StatelessWidget {
  BaseDecoratedWidget(
      {super.key,
      this.backgroundColor = Colors.white,
      this.primaryColor = Colors.orange,
      this.padding,
      this.child});

  Widget? child;

  Color? backgroundColor;
  Color? primaryColor;
  EdgeInsetsGeometry? padding;

  Widget content(BuildContext context) {
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child ?? content(context),
      ),
    );
  }
}
