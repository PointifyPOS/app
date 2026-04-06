import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/purchase_controller.dart';
import 'package:pointify/controllers/suppliercontroller.dart';
import 'package:pointify/widgets/minor_title.dart';

import '../../functions/functions.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../widgets/alert.dart';
import '../../widgets/major_title.dart';
import '../suppliers/suppliers_page.dart';

class PurchaesPreview extends StatelessWidget {
  final String? page;
  PurchaesPreview({
    super.key,
    this.page,
  });

  final PurchaseController purchaseController = Get.find<PurchaseController>();

  final SupplierController supplierController = Get.find<SupplierController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.3,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title:
            majorTitle(title: "Sale Preview", color: Colors.black, size: 16.0),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: majorTitle(
                    fontWeight: FontWeight.normal,
                    title: "Purchase Total",
                    color: Colors.black,
                    size: 19.0)),
            Center(
                child: majorTitle(
                    title: htmlPrice(
                        purchaseController.balance.toStringAsFixed(2) ?? 0),
                    color: Colors.black,
                    size: 19.0)),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: majorTitle(
                  title: "Select Payment Method",
                  color: Colors.black,
                  size: 19.0),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                    itemCount: purchaseController.paymentMethods.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          if (purchaseController.invoice.value == null ||
                              purchaseController
                                  .invoice.value!.items!.isEmpty) {
                            generalAlert(title: "No items to pay");
                            return;
                          }
                          purchaseController.selectedpaymentMethod.value =
                              purchaseController.paymentMethods[index];
                          _sell(
                              selectedpaymentMethod:
                                  purchaseController.paymentMethods[index]);
                        },
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 20, top: 20),
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      width: 1, color: Colors.grey))),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Obx(
                                        () => majorTitle(
                                            title: purchaseController
                                                .paymentMethods[index],
                                            color: Colors.black,
                                            fontWeight: FontWeight.normal,
                                            size: 19.0),
                                      ),
                                      if (purchaseController
                                                  .selectedSupplier.value !=
                                              null &&
                                          (purchaseController
                                                  .selectedpaymentMethod
                                                  .value ==
                                              purchaseController
                                                  .paymentMethods[index]))
                                        minorTitle(
                                            title:
                                                "Supplier: ${purchaseController.selectedSupplier.value?.name?.capitalizeFirst}",
                                            color: Colors.black,
                                            size: 14.0),
                                    ],
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded)
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }

  _needSupplier() {
    return purchaseController.selectedpaymentMethod.value == "Credit";
  }

  confirmPayment(context, status, {String selectedpaymentMethod = ""}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.only(left: 0),
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    majorTitle(
                        title: "Payment Method $selectedpaymentMethod",
                        color: Colors.black,
                        size: 20.0,
                        fontWeight: FontWeight.bold),
                    const SizedBox(height: 15),
                    majorTitle(
                        title:
                            "Total Amount ${htmlPrice(purchaseController.invoice.value?.totalAmount?.toStringAsFixed(2) ?? 0)}",
                        color: Colors.black,
                        size: 14.0),
                    if (selectedpaymentMethod == "Cash") _cashFieldsWidgets(),
                    if (selectedpaymentMethod == "Mpesa") mpesaFieldsWidgets(),
                    if (selectedpaymentMethod == "Bank") bankFieldsWidgets(),
                    const SizedBox(height: 10),
                    // if (salesController.change.value > 0)
                    Center(
                      child: Obx(
                        () => majorTitle(
                            title:
                                "${purchaseController.balanceText.value} ${htmlPrice(purchaseController.balance.value.toStringAsFixed(2))}",
                            color: Colors.black,
                            size: 19.0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              Get.back();
                            },
                            child: majorTitle(
                                title: "Cancel",
                                color: AppColors.mainColor,
                                size: 16.0)),
                        TextButton(
                            onPressed: checkEnoughAmountEntered() == false
                                ? null
                                : () {
                                    purchaseController.createPurchase();
                                  },
                            child: majorTitle(
                                title: "Confirm payment",
                                color: checkEnoughAmountEntered() == false
                                    ? Colors.grey
                                    : AppColors.mainColor,
                                size: 16.0)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Column bankFieldsWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        majorTitle(
            title: "Enter Amount received", color: Colors.black, size: 14.0),
        const SizedBox(height: 10),
        TextFormField(
            controller: purchaseController.textEditingControllerAmount,
            onChanged: (value) {
              purchaseController.calculateAmount();
              purchaseController.invoice.refresh();
            },
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                      userController.currentUser.value!.primaryShop!.currency!),
                ))),
        const SizedBox(height: 10),
        majorTitle(
            title: "Bank Transaction ID", color: Colors.black, size: 14.0),
        const SizedBox(height: 10),
        TextFormField(
            controller: purchaseController.bankTransId,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                )))
      ],
    );
  }

  Column mpesaFieldsWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        majorTitle(
            title: "Enter Amount received", color: Colors.black, size: 14.0),
        const SizedBox(height: 10),
        TextFormField(
            controller: purchaseController.textEditingControllerAmount,
            onChanged: (value) {
              purchaseController.calculateAmount();
              purchaseController.invoice.refresh();
            },
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                      userController.currentUser.value!.primaryShop!.currency!),
                ))),
        const SizedBox(height: 10),
        majorTitle(
            title: "Mpesa Transaction ID", color: Colors.black, size: 14.0),
        const SizedBox(height: 10),
        TextFormField(
            controller: purchaseController.mpesaTransId,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                )))
      ],
    );
  }

  Column _cashFieldsWidgets() {
    return Column(
      children: [
        const SizedBox(height: 10),
        majorTitle(
            title: "Enter Amount received", color: Colors.black, size: 14.0),
        const SizedBox(height: 10),
        TextFormField(
            controller: purchaseController.textEditingControllerAmount,
            onChanged: (value) {
              purchaseController.calculateAmount();
              purchaseController.invoice.refresh();
            },
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                      userController.currentUser.value!.primaryShop!.currency!),
                )))
      ],
    );
  }

  bool checkEnoughAmountEntered() {
    return toDouble(purchaseController.textEditingControllerAmount.text.isEmpty
            ? 0
            : purchaseController.textEditingControllerAmount.text) >=
        toDouble(purchaseController.invoice.value?.totalAmount ?? 0);
  }

  void _sell({String status = "cashed", String selectedpaymentMethod = ""}) {
    if (purchaseController.selectedSupplier.value == null && _needSupplier()) {
      generalAlert(
          title: "Error!",
          message: "please select supplier to buy from",
          function: () {
            Get.to(() => Suppliers(
                  from: "purchases",
                  function: (v) {
                    print(purchaseController.selectedSupplier.value);
                    if (purchaseController.selectedSupplier.value != null) {
                      generalAlert(
                          title: "Confirm",
                          message:
                              "Are you sure you want to purchase on $selectedpaymentMethod from ${purchaseController.selectedSupplier.value?.name}?",
                          function: () {
                            purchaseController.createPurchase();
                          });
                    }
                  },
                ));
          });
      return;
    }

    if (selectedpaymentMethod == "Credit") {
      generalAlert(
          title: "Confirm",
          message:
              "Are you sure you want to purchase on $selectedpaymentMethod from ${purchaseController.selectedSupplier.value?.name}?",
          function: () {
            purchaseController.createPurchase();
          });
    } else {
      if (selectedpaymentMethod == "Cash" ||
          selectedpaymentMethod == "Mpesa" ||
          selectedpaymentMethod == "Bank") {
        confirmPayment(Get.context!, status,
            selectedpaymentMethod: selectedpaymentMethod);
      } else {
        purchaseController.createPurchase();
      }
    }
  }
}
