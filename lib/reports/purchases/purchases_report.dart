import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/reports_controller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/reports/purchases/invoice_order_card.dart';
import 'package:pointify/utils/colors.dart';
import 'package:pointify/widgets/no_items_found.dart';
import 'package:printing/printing.dart';

import '../../../controllers/purchase_controller.dart';
import '../../../controllers/shopcontroller.dart';
import '../../functions/functions.dart';
import '../../screens/receipts/pdf/sales/purchases_report.dart';
import '../../widgets/alert.dart';
import '../../widgets/textbutton.dart';

class PurchasesReport extends StatelessWidget {
  final String? title;
  final String? type;
  PurchasesReport({super.key, this.title, this.type});

  final ShopController shopController = Get.find<ShopController>();
  final PurchaseController purchaseController = Get.find<PurchaseController>();
  final ReportsController reportsController = Get.find<ReportsController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          titleSpacing: 0.4,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.clear,
              color: AppColors.mainColor,
            ),
          ),
          title: Text(
            title!,
            style: TextStyle(color: AppColors.mainColor),
          ),
          actions: [
            Center(
                child: textBtn(
                    vPadding: 5,
                    hPadding: 20,
                    text: "Print",
                    bgColor: AppColors.mainColor,
                    color: Colors.white,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: const Text(
                                  "Only 50 items will show in the pdf, if the record is more than that, enter your email to get the port in your email address"),
                              actions: [
                                TextField(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(),
                                    hintText: "Enter your email",
                                  ),
                                  controller:
                                      purchaseController.emailController,
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                        onPressed: () {
                                          Get.back();
                                        },
                                        child: const Text("Cancel")),
                                    TextButton(
                                        onPressed: () {
                                          Get.back();
                                          Get.to(() => Scaffold(
                                                appBar: AppBar(
                                                  title: Text(
                                                      "${type.toString().capitalizeFirst} Purchases"),
                                                ),
                                                body: PdfPreview(
                                                  build: (context) =>
                                                      purchasesReportPdf(
                                                          "receipts",
                                                          "${type!.toUpperCase()} PURCHASES"),
                                                ),
                                              ));
                                        },
                                        child: const Text("Print")),
                                    TextButton(
                                        onPressed: () {
                                          if (purchaseController.emailController
                                              .text.isNotEmpty) {
                                            purchaseController.sendReportEmail(
                                                email: purchaseController
                                                    .emailController.text,
                                                fromDate: reportsController
                                                    .filterStartDate.value,
                                                toDate: reportsController
                                                    .filterEndDate.value,
                                                shop: userController.currentUser
                                                    .value!.primaryShop!.id!,
                                                // paymentTag: reportsController
                                                //     .cashsalesfilterSelected
                                                //     .value,
                                                status: "cashed");
                                          } else {
                                            generalAlert(
                                                message:
                                                    "Please enter your email");
                                          }
                                        },
                                        child: const Text("Send to email")),
                                  ],
                                ),
                              ],
                            );
                          });
                    })),
            const SizedBox(
              width: 10,
            )
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: TextFormField(
                controller: purchaseController.searchInvoiceController,
                onChanged: (value) {
                  if (value == "") {
                    purchaseController.filteredInvoices.value =
                        purchaseController.invoices
                            .where((p0) =>
                                p0.paymentType ==
                                purchaseController.selectedItem.value)
                            .toList();
                  } else {
                    purchaseController.filteredInvoices.value =
                        purchaseController.invoices
                            .where((p0) =>
                                p0.paymentType ==
                                        purchaseController.selectedItem.value &&
                                    p0.purchaseNo
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()) ||
                                p0.items!.any((element) => element
                                    .product!.name!
                                    .toLowerCase()
                                    .contains(value.toLowerCase())))
                            .toList();
                  }
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                  hintText: ""
                      "Search by invoice number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (type!.toLowerCase() != "credit")
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => Wrap(
                        direction: Axis.horizontal,
                        spacing: 8,
                        runSpacing: 12,
                        children: List.generate(
                            purchaseController.reportpaymentMethods.length,
                            (index) => InkWell(
                                  onTap: () {
                                    purchaseController.selectedItem.value =
                                        purchaseController
                                            .reportpaymentMethods[index]
                                            .toString()
                                            .toLowerCase();
                                    purchaseController.filteredInvoices.value =
                                        purchaseController.invoices
                                            .where((p0) =>
                                                p0.paymentType ==
                                                purchaseController
                                                    .reportpaymentMethods[index]
                                                    .toString()
                                                    .toLowerCase())
                                            .toList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 5, left: 10, right: 15),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            width: 1,
                                            color: AppColors.mainColor),
                                        color: purchaseController
                                                    .selectedItem.value ==
                                                purchaseController
                                                    .reportpaymentMethods[index]
                                                    .toString()
                                                    .toLowerCase()
                                            ? AppColors.mainColor
                                            : Colors.white),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${purchaseController.reportpaymentMethods[index]}:",
                                          style: TextStyle(
                                              color: purchaseController
                                                          .selectedItem.value ==
                                                      purchaseController
                                                          .reportpaymentMethods[
                                                              index]
                                                          .toString()
                                                          .toLowerCase()
                                                  ? Colors.white
                                                  : AppColors.mainColor,
                                              fontSize: 12),
                                        ),
                                        const SizedBox(width: 10),
                                        Obx(
                                          () => Text(
                                            htmlPrice(purchaseController
                                                .totals[purchaseController
                                                    .reportpaymentMethods[index]
                                                    .toString()
                                                    .toLowerCase()]
                                                .toStringAsFixed(2)
                                                .toString()),
                                            style: TextStyle(
                                                color: purchaseController
                                                            .selectedItem
                                                            .value ==
                                                        purchaseController
                                                            .reportpaymentMethods[
                                                                index]
                                                            .toString()
                                                            .toLowerCase()
                                                    ? Colors.white
                                                    : AppColors.mainColor),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                      )),
                ),
              ),
            Obx(() {
              return purchaseController.isLoadingPurchases.isTrue
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : purchaseController.filteredInvoices.isEmpty
                      ? Center(child: noItemsFound(context, true))
                      : Expanded(
                          child: ListView.builder(
                              itemCount:
                                  purchaseController.filteredInvoices.length +
                                      1,
                              physics: const ScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                if (index <
                                    purchaseController.invoices.length) {
                                  return invoiceCard(
                                    invoice: purchaseController.invoices[index],
                                  );
                                }
                                if (!purchaseController.hasMore.value) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: purchaseController.isLoadingMore.value
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: () {
                                            purchaseController.getPurchases(
                                              shopid: userController.currentUser
                                                  .value!.primaryShop!.id,
                                              loadMore: true,
                                              fromDate: reportsController
                                                  .filterStartDate.value,
                                              toDate: reportsController
                                                  .filterEndDate.value,
                                            );
                                          },
                                          child: const Text("Load More"),
                                        ),
                                );
                              }),
                        );
            }),
          ],
        ));
  }
}
