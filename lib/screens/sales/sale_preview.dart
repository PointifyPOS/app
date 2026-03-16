import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/widgets/minor_title.dart';

import '../../controllers/customercontroller.dart';
import '../../controllers/salescontroller.dart';
import '../../functions/functions.dart';
import '../../main.dart';
import '../../models/customer.dart';
import '../../utils/colors.dart';
import '../../widgets/alert.dart';
import '../../widgets/major_title.dart';
import '../customers/customers_page.dart';

class SalePreview extends StatelessWidget {
  final String? page;
  SalePreview({
    super.key,
    this.page,
  });

  final SalesController salesController = Get.find<SalesController>();

  final CustomerController customersController = Get.find<CustomerController>();

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
                    title: "Sale Total",
                    color: Colors.black,
                    size: 19.0)),
            Center(
                child: majorTitle(
                    title: htmlPrice(salesController
                            .receipt.value?.totalWithDiscount
                            ?.toStringAsFixed(2) ??
                        0),
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
              child: ListView.builder(
                  itemCount: salesController.paymentMethods.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        if (salesController.receipt.value == null ||
                            salesController.receipt.value!.items!.isEmpty) {
                          generalAlert(title: "No items to pay");
                          return;
                        }
                        salesController.paymentType.value =
                            salesController.paymentMethods[index];
                        _sell(
                            paymentType: salesController.paymentMethods[index]);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 20, top: 20),
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(width: 1, color: Colors.grey))),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    majorTitle(
                                        title: salesController
                                            .paymentMethods[index],
                                        color: Colors.black,
                                        fontWeight: FontWeight.normal,
                                        size: 19.0),
                                    if (salesController.currentCustomer.value !=
                                            null &&
                                        (salesController.paymentType.value ==
                                            salesController
                                                .paymentMethods[index]))
                                      minorTitle(
                                          title:
                                              "Customer: ${salesController.currentCustomer.value?.name?.capitalizeFirst}",
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
            )
          ],
        ),
      ),
    );
  }

  _needCustomer() {
    return salesController.paymentType.value == "Credit" ||
        salesController.paymentType.value == "Wallet";
  }

  confirmSplitPayment(status, {String paymentType = ""}) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.only(left: 0),
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Obx(
              () => ListView(
                children: [
                  majorTitle(
                      title: "Payment Method $paymentType",
                      color: Colors.black,
                      size: 20.0,
                      fontWeight: FontWeight.bold),
                  const SizedBox(height: 15),
                  majorTitle(
                      title:
                          "Total Amount ${htmlPrice(salesController.receipt.value?.totalWithDiscount?.toStringAsFixed(2) ?? 0)}",
                      color: Colors.black,
                      size: 14.0),
                  const SizedBox(height: 10),
                  majorTitle(title: "Cash", color: Colors.black, size: 14.0),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: salesController.cashPaid,
                      onChanged: (value) {
                        salesController.getTotalCredit();
                        salesController.receipt.refresh();
                      },
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(userController
                                .currentUser.value!.primaryShop!.currency!),
                          ))),
                  const SizedBox(height: 10),
                  majorTitle(title: "Mpesa", color: Colors.black, size: 14.0),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: salesController.mpesaCashPaid,
                      onChanged: (value) {
                        salesController.getTotalCredit();
                        salesController.receipt.refresh();
                      },
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(userController
                                .currentUser.value!.primaryShop!.currency!),
                          ))),
                  const SizedBox(height: 10),
                  majorTitle(
                      title: "Mpesa Code", color: Colors.black, size: 14.0),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: salesController.mpesaTransId,
                      keyboardType: TextInputType.text,
                      autofocus: true,
                      decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ))),
                  const SizedBox(height: 10),
                  majorTitle(title: "Bank", color: Colors.black, size: 14.0),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: salesController.bankCashPaid,
                      onChanged: (value) {
                        salesController.getTotalCredit();
                        salesController.receipt.refresh();
                      },
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(userController
                                .currentUser.value!.primaryShop!.currency!),
                          ))),
                  const SizedBox(height: 10),
                  majorTitle(
                      title: "Sales Note", color: Colors.black, size: 14.0),
                  const SizedBox(height: 5),
                  TextFormField(
                      controller: salesController.salesnote,
                      keyboardType: TextInputType.text,
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )),
                  const SizedBox(height: 10),
                  // if (salesController.change.value > 0)
                  Center(
                    child: Obx(
                      () => majorTitle(
                          title:
                              "${salesController.changeText.value} ${htmlPrice(salesController.change.value.toStringAsFixed(2))}",
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
                          onPressed: () {
                            salesController.saveSale(
                                screen: page ?? "admin", status: status);
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
        );
      },
    );
  }

  confirmPayment(context, status, {String paymentType = ""}) {
    salesController.amountPaid.text = "";
    salesController.showSalesDiscount.value = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      title: "Payment Method $paymentType",
                      color: Colors.black,
                      size: 20.0,
                      fontWeight: FontWeight.bold),
                  const SizedBox(height: 15),
                  majorTitle(
                      title:
                          "Total  ${htmlPrice(salesController.receipt.value?.totalWithDiscount?.toStringAsFixed(2) ?? 0)}",
                      color: Colors.black,
                      size: 14.0),
                  if (paymentType == "Cash") _cashFieldsWidgets(),
                  if (paymentType == "Mpesa") mpesaFieldsWidgets(),
                  if (paymentType == "Bank") bankFieldsWidgets(),
                  const SizedBox(height: 10),
                  if (salesController.showSalesDiscount.isFalse)
                    InkWell(
                      child: const Text(
                        "Add Discount",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        salesController.showSalesDiscount.value =
                            !salesController.showSalesDiscount.value;
                      },
                    ),
                  if (salesController.showSalesDiscount.isTrue)
                    majorTitle(
                        title: "Discount", color: Colors.black, size: 14.0),
                  if (salesController.showSalesDiscount.isTrue)
                    const SizedBox(height: 5),
                  if (salesController.showSalesDiscount.isTrue)
                    TextFormField(
                        controller: salesController.saleDiscount,
                        keyboardType: TextInputType.text,
                        autofocus: true,
                        decoration: InputDecoration(
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(userController
                                .currentUser.value!.primaryShop!.currency!),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )),
                  const SizedBox(height: 10),
                  majorTitle(
                      title: "Sales Note", color: Colors.black, size: 14.0),
                  const SizedBox(height: 5),
                  TextFormField(
                      controller: salesController.salesnote,
                      keyboardType: TextInputType.text,
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Center(
                    child: Obx(
                      () => majorTitle(
                          title:
                              "${salesController.changeText.value} ${htmlPrice(salesController.change.value.toStringAsFixed(2))}",
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
                                  salesController.saveSale(
                                      screen: page ?? "admin", status: status);
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
            controller: salesController.bankCashPaid,
            onChanged: (value) {
              salesController.amountPaid.text =
                  salesController.bankCashPaid.text;
              salesController.getTotalCredit();
              salesController.receipt.refresh();
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
            controller: salesController.bankTransId,
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
            controller: salesController.mpesaCashPaid,
            onChanged: (value) {
              salesController.amountPaid.text =
                  salesController.mpesaCashPaid.text;
              salesController.getTotalCredit();
              salesController.receipt.refresh();
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
            controller: salesController.mpesaTransId,
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
            controller: salesController.amountPaid,
            onChanged: (value) {
              salesController.getTotalCredit();
              salesController.receipt.refresh();
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
    return toDouble(salesController.amountPaid.text.isEmpty
            ? 0
            : salesController.amountPaid.text) >=
        toDouble(salesController.receipt.value?.totalWithDiscount);
  }

  void _sell({String status = "cashed", String paymentType = ""}) {
    if (salesController.currentCustomer.value == null && _needCustomer()) {
      generalAlert(
          title: "Error!",
          message: "please select customer to sell to",
          function: () {
            customersController.getCustomersInShop("all");
            Get.to(() => Customers(
                  type: "sale",
                  function: (Customer? customer) {
                    if (customer != null) {
                      if (paymentType == "Credit" || paymentType == "Wallet") {
                        if (paymentType == "Credit" &&
                            customer.creditLimit != null &&
                            customer.creditLimit != 0 &&
                            customer.creditLimit! <
                                salesController
                                    .receipt.value!.totalWithDiscount!) {
                          salesController.currentCustomer.value = null;
                          customersController.currentCustomer.value = null;
                          generalAlert(
                              title: "Error!",
                              message:
                                  "Customer has reached credit limit to sell on credit",
                              function: () {
                                Get.back();
                              });
                          return;
                        }
                        generalAlert(
                            title: "Confirm",
                            message:
                                "Are you sure you want to sell on $paymentType to ${salesController.currentCustomer.value?.name}?",
                            function: () {
                              salesController.saveSale(
                                  screen: page ?? "admin", status: status);
                            });
                      }
                    }
                  },
                ));
          });
      return;
    }
    print("paymentType: ${salesController.currentCustomer.value?.creditLimit}");
    if (paymentType == "Credit") {
      if (salesController.currentCustomer.value?.creditLimit != null &&
          salesController.currentCustomer.value?.creditLimit != 0 &&
          salesController.currentCustomer.value!.creditLimit! <
              salesController.receipt.value!.totalWithDiscount!) {
        customersController.currentCustomer.value = null;
        salesController.currentCustomer.value = null;
        salesController.selectedCustomerController.clear();
        generalAlert(
            title: "Error!",
            message: "Customer has reached credit limit to sell on credit",
            function: () {
              Get.back();
            });
        return;
      }
      generalAlert(
          title: "Confirm",
          message:
              "Are you sure you want to sell on $paymentType to ${salesController.currentCustomer.value?.name}?",
          function: () {
            if (customersController.customer.value?.creditLimit != null &&
                customersController.customer.value?.creditLimit != 0 &&
                customersController.customer.value!.creditLimit! <
                    salesController.receipt.value!.totalWithDiscount!) {
              customersController.currentCustomer.value = null;
              salesController.currentCustomer.value = null;
              generalAlert(
                  title: "Error!",
                  message:
                      "Customer has reached credit limit to sell on credit",
                  function: () {
                    Get.back();
                  });
              return;
            }
            salesController.saveSale(screen: page ?? "admin", status: status);
          });
    } else {
      if (paymentType == "Cash" ||
          paymentType == "Mpesa" ||
          paymentType == "Bank") {
        confirmPayment(Get.context!, status, paymentType: paymentType);
      } else {
        if (paymentType == "Split Payment") {
          confirmSplitPayment(status, paymentType: paymentType);
        } else {
          salesController.saveSale(screen: page ?? "admin", status: status);
        }
      }
    }
  }
}
