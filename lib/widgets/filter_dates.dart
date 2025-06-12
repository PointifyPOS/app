import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/reports_controller.dart';

import '../reports/daterange_picker.dart';
import '../utils/colors.dart';

List<Map<String, dynamic>> filterCards = [
  {
    "title": "Today",
    "key": "today",
  },
  {
    "title": "Yesterday",
    "key": "yesterday",
  },
  {
    "title": "This Week",
    "key": "week",
  },
  {
    "title": "This Month",
    "key": "month",
  },
  {
    "title": "This Year",
    "key": "year",
  },
  {
    "title": "Custom",
    "key": "custom",
  }
];

Widget filterByDates({required Function onFilter}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
          spacing: 15,
          direction: Axis.horizontal,
          clipBehavior: Clip.none,
          children: List.generate(
              filterCards.length,
              (index) => filterCards[index]["key"] == "today"
                  ? filterCard(
                      onFilter: onFilter,
                      title: filterCards[index]["title"],
                      key: filterCards[index]["key"])
                  : filterCard(
                      onFilter: onFilter,
                      title: filterCards[index]["title"],
                      key: filterCards[index]["key"]))),
    ),
  );
}

Widget filterCard(
    {required Function onFilter, String title = "", String key = ""}) {
  return InkWell(
    onTap: () async {
      DateTime from = DateTime.now();
      DateTime to = DateTime.now();
      if (key == "today") {
        from = DateTime.now();
        to = from;
      }

      if (key == "yesterday") {
        from = DateTime.now().subtract(const Duration(days: 1));
        to = from;
      }

      if (key == "week") {
        from = DateTime.now().subtract(const Duration(days: 7));
        to = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
      }

      if (key == "month") {
        from = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );
        to = DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          0,
        );
      }

      if (key == "year") {
        from = DateTime(
          DateTime.now().year,
          1,
          1,
        );
        to = DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          0,
        );
      }

      if (key == "custom") {
        Get.to(() => DateRangerPicker(function: (String fromm, String too) {
              from = DateTime.parse(fromm);
              to = DateTime.parse(too);
              Get.back();
              onFilter(from, to, key);
            }));
      } else {
        onFilter(from, to, key);
      }
    },
    child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Get.find<ReportsController>().activeFilter.value == key
              ? AppColors.mainColor
              : Colors.white,
          border: Get.find<ReportsController>().activeFilter.value == key
              ? null
              : Border.all(color: AppColors.lightDeepPurple),
          boxShadow: !(Get.find<ReportsController>().activeFilter.value == key)
              ? null
              : const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0.0, 0.0), //(x,y)
                    blurRadius: 4.0,
                  ),
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
              color: Get.find<ReportsController>().activeFilter.value == key
                  ? Colors.white
                  : AppColors.mainColor),
        )),
  );
}
