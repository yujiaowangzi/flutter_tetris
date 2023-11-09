
class DateTimeHelp {
  DateTimeHelp._();

  static String? getFormatStringBySecond(int second,
      {DateTimeEntity? entity}) {
    DateTimeEntity dateTime = splitFromSecond(second);

    var dt= "${dateTime.day > 0 && (entity?.day ?? 0) >= 0 ? "${dateTime.day}天" : ""}${dateTime.hour > 0 && (entity?.hour ?? 0) >= 0 ? "${dateTime.hour}时" : ""}"
        "${dateTime.minute > 0 && (entity?.minute ?? 0) >= 0 ? "${dateTime.minute}分" : ""}${dateTime.second > 0 && (entity?.second ?? 0) >= 0 ? "${dateTime.second}秒" : ""}";
    return dt.trim().isEmpty?null:dt;
  }

  static DateTimeEntity splitFromSecond(int seconds) {
    int residue = seconds;
    int day = seconds ~/ Duration.secondsPerDay;
    residue -= day * Duration.secondsPerDay;

    int hour = residue ~/ Duration.secondsPerHour;
    residue -= hour * Duration.secondsPerHour;

    int minute = residue ~/ Duration.secondsPerMinute;
    residue -= minute * Duration.secondsPerMinute;
    return DateTimeEntity(
        day: day, hour: hour, minute: minute, second: residue);
  }
}

class DateTimeEntity {
  int day;
  int hour;
  int minute;
  int second;

  DateTimeEntity(
      {this.day = 0, this.hour = 0, this.minute = 0, this.second = 0});

}
