import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../utils/colors.dart';
import 'major_title.dart';

class CustomDateFilter extends StatefulWidget {
 final Function function;
 final DateTime? firstDay;
 final bool? showTitle ;
 final DateTime? lastDay;
 final Color? color;
  const CustomDateFilter(
      {super.key,
      required this.function,
      this.color = AppColors.mainColor,
      this.showTitle= true,
      this.firstDay,
      this.lastDay});

  @override
  State<CustomDateFilter> createState() => _CustomDateFilterState();
}

class _CustomDateFilterState extends State<CustomDateFilter> {
  DateTime? from;
  DateTime? to;
  TextEditingController fromDate = TextEditingController();
  TextEditingController toDate = TextEditingController();

  @override
  void initState() {
    if (widget.firstDay != null && widget.lastDay != null) {
      from = widget.firstDay;
      to = widget.lastDay;
      fromDate.text = DateFormat("yyy-MM-dd").format(from!);
      toDate.text = DateFormat("yyy-MM-dd").format(to!);
    }
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle == true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: majorTitle(
                  title: "Filter by Date", color: widget.color!, size: 16.0),
            ),
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                controller: fromDate,
                onTap: () async {
                  from = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900, 5, 5, 20, 50),
                    lastDate: DateTime(2030, 6, 7, 05, 09),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.mainColor,
                            onPrimary: Colors.white,
                            surface: AppColors.lightDeepPurple,
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  fromDate.text =
                      DateFormat("yyy-MM-dd").format(from ?? DateTime.now());
                  toDate.text = "";
                  setState(() {});
                },
                readOnly: true,
                scrollPadding: const EdgeInsets.all(0),
                decoration: InputDecoration(
                    hintText: "From date",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1)),
                    suffixIcon: fromDate.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.cancel),
                            color: AppColors.mainColor,
                            onPressed: () {
                              widget.function(null, null);
                              fromDate.text = "";
                              setState(() {});
                            },
                          ),
                    fillColor: widget.color,
                    filled: true),
              )),
              Text(
                " - ",
                style: TextStyle(color: widget.color),
              ),
              Expanded(
                  child: TextFormField(
                controller: toDate,
                onTap: () async {
                  to = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900, 5, 5, 20, 50),
                    lastDate: DateTime(2030, 6, 7, 05, 09),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.mainColor,
                            onPrimary: Colors.white,
                            surface: AppColors.lightDeepPurple,
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  toDate.text = DateFormat("yyy-MM-dd").format(to!);
                  setState(() {});
                  if (from != null && to != null) {
                    widget.function(from, to);
                  }
                },
                readOnly: true,
                scrollPadding: const EdgeInsets.all(0),
                decoration: InputDecoration(
                    fillColor: widget.color,
                    filled: true,
                    hintText: "To date",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1)),
                    suffixIcon: toDate.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.cancel),
                            color: AppColors.mainColor,
                            onPressed: () {
                              toDate.text = "";
                              widget.function(null, null);
                              setState(() {});
                            },
                          )),
              )),
              if (fromDate.text.isNotEmpty && toDate.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    color: widget.color,
                    onPressed: () {
                      widget.function(from, to);
                    },
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}
