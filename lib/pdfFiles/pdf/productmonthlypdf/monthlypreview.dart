import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reggypos/pdfFiles/pdf/productmonthlypdf/product_monthly_report.dart';
import 'package:reggypos/utils/colors.dart';
import 'package:printing/printing.dart';

import '../../../models/product.dart';

class MonthlyPreviewPage extends StatelessWidget {
  final List<dynamic>? sales;
  final String? type;
  final String? title;
  final double? total;
  final Product? product;

  const MonthlyPreviewPage(
      {super.key,
      this.sales,
      this.type,
      required this.product,
      this.title,
      this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            )),
        backgroundColor:
            AppColors.mainColor,
        title: Text(
          type ?? "",
          style: TextStyle(
              color: Colors.white),
        ),
      ),
      body: PdfPreview(
        build: (context) => productMonthlyReport(sales,
            product: product!, title: title, total: total),
      ),
    );
  }
}
