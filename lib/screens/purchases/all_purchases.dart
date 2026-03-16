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
                  : ListView.builder(
                      itemCount: purchaseController.invoices.length,
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        Invoice invoiceData =
                            purchaseController.invoices.elementAt(index);
                        return invoiceCard(invoice: invoiceData);
                      });
        }));
  }
}
