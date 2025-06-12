import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/models/payment.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/utils/helper.dart';
import 'package:printing/printing.dart';

import '../../controllers/customercontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../receipts/pdf/wallet_pdf.dart';
import 'components/deposit_dialog.dart';
import 'components/wallet_card.dart';

class WalletPage extends StatelessWidget {
  final String? page;

  WalletPage({Key? key, this.page}) : super(key: key) {
    customersController.initialPage.value = 0;
    customersController
        .getCustomersById(customersController.currentCustomer.value!.sId!);
    customersController.getTransactions(
        "deposit", customersController.currentCustomer.value!.sId!);
    customersController.customerReceiptType.value = 'deposit';
  }

  final CustomerController customersController = Get.find<CustomerController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Helper(
          appBar: _appBar(context),
          widget: SingleChildScrollView(
            child: Column(children: [
              walletBalanceContainer(context, "small"),
              tabsPage(context)
            ]),
          ),
        ));
  }

  Widget tabsPage(context) {
    return Obx(() => DefaultTabController(
          length: 2,
          initialIndex: customersController.initialPage.value,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: kToolbarHeight,
                  child: TabBar(
                      unselectedLabelColor: Colors.grey,
                      labelColor: Colors.purple,
                      indicatorColor: Colors.purple,
                      indicatorWeight: 3,
                      onTap: (index) {
                        if (index == 0) {
                          customersController.customerReceiptType.value =
                              'deposit';
                          customersController.getTransactions(
                            "deposit",
                            customersController.currentCustomer.value!.sId!,
                          );
                        } else {
                          customersController.customerReceiptType.value =
                              'payment';
                          customersController.getTransactions(
                            "payment",
                            customersController.currentCustomer.value!.sId!,
                          );
                        }
                      },
                      tabs: const [
                        Tab(text: "Deposit"),
                        Tab(text: "Usage"),
                      ]),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey.withOpacity(0.1),
                    child: TabBarView(
                      controller: customersController.tabController,
                      children: [
                        DepositHistory(
                          uid: customersController.currentCustomer.value!.sId!,
                          type: "deposit",
                        ),
                        DepositHistory(
                          uid: customersController.currentCustomer.value!.sId!,
                          type: "usage",
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget walletBalanceContainer(context, type) {
    return Container(
      color: AppColors.mainColor,
      height: MediaQuery.of(context).size.height * 0.2,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Wallet Balance",
            style: TextStyle(
                color: type == "small" ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Obx(
            () => Text(
              htmlPrice(customersController.currentCustomer.value?.wallet ?? 0)
                  .toUpperCase(),
              style: TextStyle(
                  color: type == "small" ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          if (verifyPermission(category: "customers", permission: "deposit"))
            InkWell(
              onTap: () {
                showDepositDialog(
                    context: context,
                    customerModel: customersController.currentCustomer.value!,
                    title:
                        customersController.currentCustomer.value!.wallet! < 0
                            ? "Payment"
                            : "Deposit",
                    page: page,
                    size: "small");
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white),
                child: Text(
                  "Make ${customersController.currentCustomer.value!.wallet! < 0 ? "Payment" : "Deposit"}",
                  style: TextStyle(
                      color: type == "large" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }

  AppBar _appBar(context) {
    return AppBar(
      elevation: 0.2,
      backgroundColor: AppColors.mainColor,
      leading: IconButton(
          onPressed: () {
            Get.find<CustomerController>().currentCustomer.value =
                customersController.currentCustomer.value!;
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          )),
      title: Text(
        "${customersController.currentCustomer.value!.name}".capitalize!,
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: false,
      actions: [
        if (userController.currentUser.value?.usertype == "admin")
          IconButton(
              onPressed: () {
                showModalSheet(
                    context,
                    customersController.currentCustomer.value!.name,
                    customersController.currentCustomer.value!.sId);
              },
              icon: const Icon(Icons.download, color: Colors.white))
      ],
    );
  }

  _printPdf(type) async {
    if (type == "Full") {
      customersController.getTransactions(
          "all", customersController.currentCustomer.value!.sId!,
          reason: "download");
    }
    if (type == "Usage") {
      customersController.getTransactions(
          "payment", customersController.currentCustomer.value!.sId!,
          reason: "download");
    }
    if (type == "Deposit") {
      customersController.getTransactions(
          "deposit", customersController.currentCustomer.value!.sId!,
          reason: "download");
    }
    Get.to(() => Scaffold(
          appBar: AppBar(
            title: Text("$type Statement"),
          ),
          body: Obx(() => customersController.isLoadingcustomerPayments.isTrue
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : PdfPreview(
                  build: (context) => customerStatement(
                      customersController.downloadPaymentsHistory, type))),
        ));
  }

  showModalSheet(context, title, uid) {
    CustomerController walletController = Get.find<CustomerController>();
    return showModalBottomSheet<void>(
        backgroundColor:
            isSmallScreen(context) ? Colors.white : Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
              height: 200,
              color: Colors.white,
              margin: EdgeInsets.only(
                  left: isSmallScreen(context)
                      ? 0
                      : MediaQuery.of(context).size.width * 0.2),
              child: Center(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      color: Colors.grey.withOpacity(0.7),
                      child: const Text('Select Download Option')),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        walletController.initialPage.value = 0;
                        _printPdf("Deposit");
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward),
                            SizedBox(
                              width: 10,
                            ),
                            Text('Deposit History ')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        walletController.initialPage.value = 1;
                        _printPdf("Usage");
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(Icons.cloud_download_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text('Usage History')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        walletController.initialPage.value = 1;
                        _printPdf("Full");
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(Icons.cloud_download_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text('Full Statement')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(Icons.clear),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )));
        });
  }
}

class DepositHistory extends StatelessWidget {
  final String uid;
  final String type;

  DepositHistory({Key? key, required this.uid, required this.type})
      : super(key: key);
  final CustomerController customerController = Get.find<CustomerController>();
  final ShopController shopController = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return customerController.gettingWalletLoad.value
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : customerController.deposits.isEmpty
              ? const Center(
                  child: Text("No Entries found"),
                )
              : ListView.builder(
                  itemCount: customerController.deposits.length,
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemBuilder: (context, index) {
                    Payment depositModel =
                        customerController.deposits.elementAt(index);
                    return walletUsageCard(
                        context: context, depositBody: depositModel);
                  });
    });
  }
}
