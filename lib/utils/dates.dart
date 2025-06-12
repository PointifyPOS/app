import 'package:intl/intl.dart';

var now = DateTime.now();
var startYear = int.parse(DateFormat("yyyy").format(DateTime.now()));
var endYear = DateTime(now.year - 10, now.month, now.day);

var lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
var firstDayOfMonth = DateTime(now.year, now.month + 0, 1);

convertTimeToMilliSeconds() {
  var now = DateTime.now();
  var tomm = now.add(const Duration(days: 1));
  var today = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(now))
      .toIso8601String();
  var tomorrow = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(tomm))
      .toIso8601String();
  convertTimeToMonth();
  return {"startDate": today, "endDate": tomorrow};
}

convertTimeToMonth() {
  var now = DateTime.now();
  var last = DateTime(now.year, now.month + 1, 0);
  var first = DateTime(now.year, now.month + 0, 1);

  var firstDay = DateFormat().parse(DateFormat().format(first)).toIso8601String();
  var lastDay = DateFormat().parse(DateFormat().format(last)).toIso8601String();
  return {"startDate": firstDay, "endDate": lastDay};
}

convertTimeToYear(selectedYear) {
  var last = DateTime(int.parse("$selectedYear"), DateTime.december + 1, 0);
  var first = DateTime(int.parse("$selectedYear"), DateTime.january + 0, 1);

  var firstDay = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(first))
      .toIso8601String();
  var lastDay = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(last))
      .toIso8601String();

  return {"startDate": firstDay, "endDate": lastDay};
}

convertTimeToMonthByDate(date) {
  var last = DateTime(date.year, date.month + 1, 0);
  var first = DateTime(date.year, date.month + 0, 1);
  var firstDay = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(first))
      .toIso8601String();
  var lastDay = DateFormat('yyyy-MM-dd')
      .parse(DateFormat('yyyy-MM-dd').format(last))
      .toIso8601String();

  return {"startDate": firstDay, "endDate": lastDay};
}
