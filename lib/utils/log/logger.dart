

import "package:flutter/foundation.dart";

int maxLogRowSize = 380;
int maxLogCharSize = 1000;

LogPrint(dynamic tag, [dynamic log]) {
  if (!kDebugMode) {
    return;
  }
  String? logStr = log?.toString();
  if (logStr == null || logStr.length <= maxLogRowSize) {
    printTap(tag, logStr);
    return;
  }

  int start = 0;
  int end = 0;

  void printStage() {
    var printText = '';
    if (start >= 0 && end <= logStr.length) {
      printText = logStr.substring(start, end);
    }
    if (start > 0) {
      printText = '\n\\n $printText';
      printTap(printText);
    } else {
      printTap(tag, printText);
    }
  }

  while (end < logStr.length) {
    end += maxLogRowSize;
    if (end >= logStr.length) {
      end=logStr.length;
      printStage();
      return;
    }
    //超出最大单次打印字符数量
    if (end - start > maxLogCharSize) {
      end = start + maxLogCharSize;
      printStage();
      start = end;
    } else {
      var nIndex = logStr.indexOf('\n', end - maxLogRowSize);
      //行内没有换行符，打印
      if (nIndex < 0 || nIndex > end) {
        printStage();
        start = end;
      }
    }
  }
}

printTap(dynamic tag, [dynamic log]) {
  if (log == null) {
    print(tag);
  } else {
    print("$tag -> $log");
  }
}
