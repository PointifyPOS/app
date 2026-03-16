import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/expensecontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/reports/net_profit_report.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/screens/finance/product_comparison.dart';
import 'package:pointify/utils/helper.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../controllers/homecontroller.dart';
import '../../controllers/salescontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../utils/colors.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';
import '../home/home_page.dart';
import 'graph_analysis.dart';

class FinancialPage extends StatelessWidget {
  final SalesController salesController = Get.find<SalesController>();
  final ShopController shopController = Get.find<ShopController>();
  final ExpenseController expenseController = Get.find<ExpenseController>();

  final List operations = [
    {
      "title": "Today profit",
      "subtitle": "Gross & Net profits",
      "icon": Icons.today,
      "color": Colors.amber.shade100,
      "showsummary": false,
    },
    {
      "title": "Current Month profit",
      "subtitle": "Gross & Net profits",
      "icon": Icons.calendar_month,
      "color": Colors.amber.shade100,
      "showsummary": false,
    },
    {
      "title": "Monthly Profit & Expenses",
      "subtitle": "Monthly profits versus expenses",
      "icon": Icons.calendar_month,
      "color": Colors.blue.shade100,
      "showsummary": false,
    },
    {
      "title": "Graphical Analysis",
      "subtitle": "Analyze shop performance in a graph",
      "icon": Icons.show_chart,
      "color": AppColors.mainColor.withOpacity(0.2),
      "showsummary": false,
    },
    {
      "title": "Products Movement",
      "subtitle": "Fast vs slow moving products",
      "icon": Icons.sell_rounded,
      "color": Colors.blue.shade100,
      "showsummary": false,
    },
  ];

  FinancialPage({Key? key}) : super(key: key);

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      salesController.range.value =
          '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
          ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      if (args.value.startDate != null && args.value.endDate != null) {
        salesController.getNetAnalysis(
            fromDate: DateFormat('yyy-MM-dd').format(args.value.startDate),
            toDate: DateFormat('yyy-MM-dd')
                .format(args.value.endDate ?? args.value.startDate),
            shopId: userController.currentUser.value!.primaryShop!.id!);
        isSmallScreen(Get.context)
            ? Get.to(() => NetProfitReport(
                  headline: "from\n${salesController.range.value}",
                  firstday: args.value.startDate,
                  lastday: args.value.endDate ?? args.value.startDate,
                ))
            : Get.find<HomeController>().selectedWidget.value = NetProfitReport(
                headline: "from\n${salesController.range.value}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Helper(
      widget: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            SfDateRangePicker(
                onSelectionChanged: _onSelectionChanged,
                selectionMode: DateRangePickerSelectionMode.range,
                monthCellStyle:  DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
                monthViewSettings: const DateRangePickerMonthViewSettings(),
                headerStyle:  DateRangePickerHeaderStyle(
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                        fontSize: 18)),
                onSubmit: (v) {}),
            isSmallScreen(context)
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: operations.length,
                    itemBuilder: (context, index) {
                      return financeCards(
                          title: operations[index]["title"],
                          subtitle: operations[index]["subtitle"],
                          icon: operations[index]["icon"],
                          onPresssed: () {
                            switch (operations[index]["title"]) {
                              case "Today profit":
                                {
                                  salesController.filterStartDate.value =
                                      DateFormat("yyy-MM-dd")
                                          .format(DateTime.now());
                                  salesController.filterEndDate.value =
                                      DateFormat("yyy-MM-dd").format(
                                          DateTime.now()
                                              .add(const Duration(days: 1)));

                                  salesController.getNetAnalysis(
                                      fromDate:
                                          salesController.filterStartDate.value,
                                      toDate:
                                          salesController.filterEndDate.value,
                                      shopId: userController
                                          .currentUser.value!.primaryShop!.id!);
                                  isSmallScreen(context)
                                      ? Get.to(() => NetProfitReport(
                                            headline: "Today",
                                            firstday: DateTime.now(),
                                            lastday: DateTime.now()
                                                .add(const Duration(days: 1)),
                                          ))
                                      : Get.find<HomeController>()
                                              .selectedWidget
                                              .value =
                                          NetProfitReport(headline: "Today");
                                }
                                break;

                              case "Current Month profit":
                                {
                                  DateTime now = DateTime.now();
                                  var lastday =
                                      DateTime(now.year, now.month + 1, 0);

                                  final noww = DateTime.now();

                                  var firstday =
                                      DateTime(noww.year, noww.month, 1);

                                  salesController.filterStartDate.value =
                                      DateFormat("yyy-MM-dd").format(firstday);
                                  salesController.filterEndDate.value =
                                      DateFormat("yyy-MM-dd").format(lastday);

                                  salesController.getNetAnalysis(
                                      fromDate:
                                          salesController.filterStartDate.value,
                                      toDate:
                                          salesController.filterEndDate.value,
                                      shopId: userController
                                          .currentUser.value!.primaryShop!.id!);
                                  isSmallScreen(context)
                                      ? Get.to(() => NetProfitReport(
                                            firstday: firstday,
                                            lastday: lastday,
                                            headline:
                                                '\n${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}',
                                          ))
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = NetProfitReport(
                                          headline:
                                              '\n${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}',
                                        );
                                }
                                break;
                              case "Monthly Profit & Expenses":
                                {
                                  isSmallScreen(context)
                                      ? Get.to(() => MonthFilter())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = MonthFilter();
                                }
                                break;

                              case "Graphical Analysis":
                                {
                                  isSmallScreen(context)
                                      ? Get.to(() => const GraphAnalysis())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = const GraphAnalysis();
                                }
                                break;
                              case "Products Movement":
                                {
                                  salesController.selectedMonth.value =
                                      DateTime.now().month;
                                  salesController.currentYear.value =
                                      DateTime.now().year;
                                  isSmallScreen(context)
                                      ? Get.to(() => const ProductAnalysis())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = const ProductAnalysis();
                                }
                                break;
                            }
                          },
                          color: operations[index]["color"],
                          amount: operations[index]["amount"]);
                    })
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio:
                            MediaQuery.of(context).size.width > 1100
                                ? 1.6
                                : MediaQuery.of(context).size.width > 900
                                    ? 1.3
                                    : 1.1,
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10),
                    shrinkWrap: true,
                    itemCount: operations.length,
                    itemBuilder: (context, index) {
                      return financeCards(
                          title: operations[index]["title"],
                          subtitle: operations[index]["subtitle"],
                          icon: operations[index]["icon"],
                          showsummary: false,
                          onPresssed: () {
                            switch (operations[index]["title"]) {
                              case "Today profit":
                                {
                                  salesController.getNetAnalysis(
                                      fromDate: DateFormat("yyy-MM-dd")
                                          .format(DateTime.now()),
                                      toDate: DateFormat("yyy-MM-dd").format(
                                          DateTime.now()
                                              .add(const Duration(days: 1))),
                                      shopId: userController
                                          .currentUser.value!.primaryShop!.id!);
                                  isSmallScreen(context)
                                      ? Get.to(() =>
                                          NetProfitReport(headline: "Today"))
                                      : Get.find<HomeController>()
                                              .selectedWidget
                                              .value =
                                          NetProfitReport(headline: "Today");
                                }
                                break;

                              case "Current Month profit":
                                {
                                  DateTime now = DateTime.now();
                                  var lastday =
                                      DateTime(now.year, now.month + 1, 0);

                                  final noww = DateTime.now();

                                  var firstday =
                                      DateTime(noww.year, noww.month, 1);
                                  salesController.getNetAnalysis(
                                      fromDate: DateFormat("yyy-MM-dd")
                                          .format(firstday),
                                      toDate: DateFormat("yyy-MM-dd")
                                          .format(lastday),
                                      shopId: userController
                                          .currentUser.value!.primaryShop!.id!);
                                  isSmallScreen(context)
                                      ? Get.to(() => NetProfitReport(
                                            headline:
                                                '\n${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}',
                                          ))
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = NetProfitReport(
                                          headline:
                                              '\n${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}',
                                        );
                                }
                                break;
                              case "Monthly Profit & Expenses":
                                {
                                  isSmallScreen(context)
                                      ? Get.to(() => MonthFilter())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = MonthFilter();
                                }
                                break;

                              case "Graphical Analysis":
                                {
                                  isSmallScreen(context)
                                      ? Get.to(() => const GraphAnalysis())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = const GraphAnalysis();
                                }
                                break;
                              case "Products Movement":
                                {
                                  salesController.selectedMonth.value =
                                      DateTime.now().month;
                                  salesController.currentYear.value =
                                      DateTime.now().year;
                                  isSmallScreen(context)
                                      ? Get.to(() => const ProductAnalysis())
                                      : Get.find<HomeController>()
                                          .selectedWidget
                                          .value = const ProductAnalysis();
                                }
                                break;
                            }
                          },
                          color: operations[index]["color"],
                          amount: operations[index]["amount"]);
                    }),
          ],
        ),
      ),
      floatButton: Container(),
      appBar: appBar(context),
    );
  }

  AppBar appBar(context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: Colors.white,
      elevation: 0.3,
      centerTitle: false,
      leading: IconButton(
        onPressed: () {
          if (MediaQuery.of(context).size.width > 600) {
            Get.find<HomeController>().selectedWidget.value = HomePage();
          } else {
            Get.back();
          }
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
        ),
      ),
      title: majorTitle(
          title: "Profit & expenses", color: Colors.black, size: 16.0),
      actions: [
        if (!isSmallScreen(context))
          InkWell(
            onTap: () {
              // Get.find<HomeController>().selectedWidget.value = ExpensePage();
            },
            child: Container(
                height: kToolbarHeight * 0.4,
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.mainColor),
                child: const Center(
                    child: Text(
                  "Add Expense",
                  style: TextStyle(color: Colors.white),
                ))),
          )
      ],
    );
  }

  Widget financeCards(
      {required title,
      required subtitle,
      required icon,
      bool? showsummary = false,
      required onPresssed,
      required Color color,
      required amount}) {
    return InkWell(
      onTap: () {
        onPresssed();
      },
      child: Container(
        margin: EdgeInsets.only(
            top: 10, right: isSmallScreen(Get.context) ? 0 : 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: isSmallScreen(Get.context)
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: isSmallScreen(Get.context)
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            isSmallScreen(Get.context)
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                        child: Center(child: Icon(icon)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          majorTitle(
                              title: title,
                              color: Colors.black,
                              size: isSmallScreen(Get.context) ? 16.0 : 12.0),
                          const SizedBox(height: 5),
                          minorTitle(title: subtitle, color: Colors.grey)
                        ],
                      )
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                        child: Center(child: Icon(icon)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: majorTitle(
                                title: title,
                                color: Colors.black,
                                size: isSmallScreen(Get.context) ? 16.0 : 12.0),
                          ),
                          const SizedBox(height: 5),
                          Center(
                              child: minorTitle(
                                  title: subtitle, color: Colors.grey))
                        ],
                      )
                    ],
                  ),
            const SizedBox(
              height: 10,
            ),
            if (showsummary == true)
              Text(
                " $title summary: ${userController.currentUser.value!.primaryShop?.currency}.$amount ",
                style: const TextStyle(color: Colors.black, fontSize: 14.0),
                textAlign: TextAlign.center,
              )
          ],
        ),
      ),
    );
  }
}

class MonthFilter extends StatelessWidget {
  MonthFilter({Key? key}) : super(key: key);
  final List<Map<String, dynamic>> months = [
    {"month": "January"},
    {"month": "February"},
    {"month": "March"},
    {"month": "April"},
    {"month": "May"},
    {"month": "June"},
    {"month": "July"},
    {"month": "August"},
    {"month": "September"},
    {"month": "October"},
    {"month": "November"},
    {"month": "December"},
  ];
  final SalesController salesController = Get.find<SalesController>();

  List<int> getYears(int year) {
    int currentYear = DateTime.now().year;

    List<int> yearsTilPresent = [];

    while (year <= currentYear) {
      yearsTilPresent.add(year);
      year++;
    }

    return yearsTilPresent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pick a month',
          style: TextStyle(
              color: isSmallScreen(context) ? Colors.white : Colors.black),
        ),
        elevation: 0.1,
        backgroundColor:
            isSmallScreen(context) ? AppColors.mainColor : Colors.white,
        leading: IconButton(
            onPressed: () {
              if (isSmallScreen(context)) {
                Get.back();
              } else {
                Get.find<HomeController>().selectedWidget.value =
                    FinancialPage();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: isSmallScreen(context) ? Colors.white : Colors.black,
            )),
        actions: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width * 0.2,
                      color: Colors.white,
                      child: ListView.builder(
                          itemCount: getYears(2019).length,
                          itemBuilder: (c, i) {
                            var year = getYears(2019)[i];
                            return InkWell(
                              onTap: () {
                                salesController.currentYear.value = year;
                                Get.back();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Text(
                                      year.toString().capitalize!,
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                  ),
                                  const Divider()
                                ],
                              ),
                            );
                          }),
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  Obx(() => Text(salesController.currentYear.value.toString())),
                  const Icon(Icons.arrow_drop_down)
                ],
              ),
            ),
          )
        ],
      ),
      body: Container(
        color: Colors.white,
        child: ListView.builder(
            itemCount: months.length,
            itemBuilder: (c, i) {
              var month = months[i];
              return InkWell(
                onTap: () {
                  DateTime now =
                      DateTime(salesController.currentYear.value, i + 1);
                  var lastday = DateTime(now.year, now.month + 1, 0);

                  final noww =
                      DateTime(salesController.currentYear.value, i + 1);

                  var firstday = DateTime(noww.year, noww.month, 1);

                  salesController.getNetAnalysis(
                      fromDate: DateFormat("yyy-MM-dd").format(firstday),
                      toDate: DateFormat("yyy-MM-dd").format(lastday),
                      shopId:
                          userController.currentUser.value!.primaryShop!.id!);

                  isSmallScreen(context)
                      ? Get.to(() => NetProfitReport(
                          firstday: firstday,
                          lastday: lastday,
                          headline:
                              "from\n${'${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}'}"))
                      : Get.find<HomeController>().selectedWidget.value =
                          NetProfitReport(
                              headline:
                                  "from\n${'${DateFormat("yyy-MM-dd").format(firstday)}-${DateFormat("yyy-MM-dd").format(lastday)}'}");
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Text(month["month"].toString().capitalize!),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey,
                          )
                        ],
                      ),
                    ),
                    const Divider()
                  ],
                ),
              );
            }),
      ),
    );
  }
}
