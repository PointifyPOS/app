import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/main.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/widgets/no_items_found.dart';

import '../../controllers/homecontroller.dart';
import '../../controllers/purchase_controller.dart';
import '../../controllers/shopcontroller.dart';
import '../../models/invoice.dart';
import '../../reports/purchases/invoice_order_card.dart';
import '../../utils/colors.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';
import '../receipts/view/invoice_screen.dart';

class AllPurchases extends StatelessWidget {
  AllPurchases({Key? key}) : super(key: key) {
    purchaseController.getPurchases(
        shopid: userController.currentUser.value!.primaryShop!.id);
  }

  final ShopController shopController = Get.find<ShopController>();
  final PurchaseController purchaseController = Get.find<PurchaseController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.3,
          centerTitle: false,
          titleSpacing: 0.4,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    majorTitle(
                        title: "Purchases", color: Colors.black, size: 16.0),
                    minorTitle(
                        title:
                            "${userController.currentUser.value?.primaryShop?.name}",
                        color: Colors.grey)
                  ],
                )
              ],
            ),
          ),
          actions: [
            InkWell(
                onTap: () {
                  // PurchasesPdf(
                  //     sales: purchaseController.purchasedItems, type: "type");
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.download,
                    color: Colors.black,
                  ),
                ))
          ],
        ),
        body: Obx(() {
          return purchaseController.isLoadingPurchases.isTrue
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : purchaseController.invoices.isEmpty
                  ? Center(child: noItemsFound(context, true))
                  : isSmallScreen(context)
                      ? ListView.builder(
                          itemCount: purchaseController.invoices.length,
                          physics: const ScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            Invoice invoiceData =
                                purchaseController.invoices.elementAt(index);
                            return invoiceCard(invoice: invoiceData);
                          })
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          margin: const EdgeInsets.symmetric(horizontal: 10)
                              .copyWith(top: 10),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.grey),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: DataTable(
                                  headingTextStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                  dataTextStyle: const TextStyle(
                                      fontSize: 18, color: Colors.black),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                    width: 1,
                                    color: Colors.black,
                                  )),
                                  columnSpacing: 30.0,
                                  columns: [
                                    const DataColumn(
                                        label: Text('Receipt Number',
                                            textAlign: TextAlign.center)),
                                    DataColumn(
                                        label: Text(
                                            'Amount(${userController.currentUser.value!.primaryShop?.currency})',
                                            textAlign: TextAlign.center)),
                                    const DataColumn(
                                        label: Text('Products',
                                            textAlign: TextAlign.center)),
                                    const DataColumn(
                                        label: Text('Status',
                                            textAlign: TextAlign.center)),
                                    const DataColumn(
                                        label: Text('Date',
                                            textAlign: TextAlign.center)),
                                    const DataColumn(
                                        label: Text('Actions',
                                            textAlign: TextAlign.center)),
                                  ],
                                  rows: List.generate(
                                      purchaseController.invoices.length,
                                      (index) {
                                    Invoice invoiceData = purchaseController
                                        .invoices
                                        .elementAt(index);

                                    final y = invoiceData.purchaseNo;
                                    const x = '';
                                    final z =
                                        invoiceData.items!.length.toString();
                                    final w = invoiceData.createdAt;

                                    return DataRow(cells: [
                                      DataCell(Text("#${y!}".toUpperCase())),
                                      const DataCell(Text(x)),
                                      DataCell(Text(z)),
                                      DataCell(Text(
                                        chechPayment(invoiceData),
                                        style: TextStyle(
                                            color:
                                                chechPaymentColor(invoiceData)),
                                      )),
                                      DataCell(Text(
                                          DateFormat("yyyy-dd-MMM hh:mm a")
                                              .format(DateTime.parse(w!)))),
                                      DataCell(InkWell(
                                        onTap: () {
                                          Get.find<HomeController>()
                                              .selectedWidget
                                              .value = InvoiceScreen(
                                            invoice: invoiceData,
                                            type: "",
                                            from: "AllPurchases",
                                          );
                                        },
                                        child: const Text(
                                          "View",
                                          style: TextStyle(
                                              color: AppColors.mainColor),
                                        ),
                                      )),
                                    ]);
                                  }),
                                ),
                              ),
                            ),
                          ),
                        );
        }));
  }
}
