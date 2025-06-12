import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/models/salereturn.dart';
import 'package:pointify/screens/customers/edit_user.dart';
import 'package:pointify/screens/customers/wallet_page.dart';
import 'package:pointify/screens/sales/components/sales_card.dart';
import 'package:pointify/utils/helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/customercontroller.dart';
import '../../controllers/salescontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../controllers/suppliercontroller.dart';
import '../../functions/functions.dart';
import '../../main.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';
import '../../models/salemodel.dart';
import '../../utils/colors.dart';
import '../../widgets/alert.dart';
import '../../widgets/delete_dialog.dart';
import '../../widgets/snackBars.dart';
import '../sales/components/sales_rerurn_card.dart';

class CustomerInfoPage extends StatelessWidget {
  CustomerInfoPage({super.key, Key? ke}) {
    salesController.getSalesByDate(
        shop: userController.currentUser.value!.primaryShop!.id!,
        status: "cashed",
        paymentType: "credit",
        customerid: customerController.currentCustomer.value?.sId);

    salesController.getReturns(
        customerModel: customerController.currentCustomer.value,
        type: "return",
        shopid: userController.currentUser.value!.primaryShop!.id!);
    customerController
        .getCustomersById(customerController.currentCustomer.value!.sId!);
  }

  final CustomerController customerController = Get.find<CustomerController>();
  final SupplierController supplierController = Get.find<SupplierController>();
  final ShopController shopController = Get.find<ShopController>();
  final SalesController salesController = Get.find<SalesController>();

  launchWhatsApp({required number, required message}) async {
    String url = "whatsapp://send?phone=+254$number&text=$message";
    await canLaunchUrl(Uri.parse(url))
        ? canLaunchUrl(Uri.parse(url))
        : showSnackBar(message: "Cannot open whatsapp", color: Colors.red);
  }

  launchMessage({required number, required message}) async {
    Uri sms = Uri.parse('sms:$number?body=$message');
    if (await launchUrl(sms)) {
      //app opened
    } else {
      //app is not opened
    }
  }

  @override
  Widget build(BuildContext context) {
    return Helper(
        floatButton: Container(),
        widget: SingleChildScrollView(
          child: Column(
            children: [
              Obx(
                () => Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  color: AppColors.mainColor,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                          child: Text(
                        customerController.currentCustomer.value!.name ?? "",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                                onPressed: () {
                                  launchMessage(
                                      number: customerController
                                          .currentCustomer.value?.phoneNumber,
                                      message:
                                          "A quick reminder that you owe our shop please pay your debt ");
                                },
                                icon: const Icon(Icons.message),
                                color: Colors.white),
                            IconButton(
                                onPressed: () {
                                  launchWhatsApp(
                                      number: customerController
                                          .currentCustomer.value?.phoneNumber,
                                      message:
                                          "A quick reminder that you owe our shop please pay your debt ");
                                },
                                icon: const Icon(Icons.whatshot),
                                color: Colors.white),
                            IconButton(
                                onPressed: () async {
                                  final Uri launchUri = Uri(
                                    scheme: 'tel',
                                    path: customerController
                                        .currentCustomer.value?.phoneNumber,
                                  );
                                  await launchUrl(launchUri);
                                },
                                icon: const Icon(Icons.phone),
                                color: Colors.white),
                            InkWell(
                              onTap: () {
                                Get.to(
                                  () => WalletPage(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.only(
                                    top: 5, bottom: 5, left: 10, right: 15),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.white.withOpacity(0.2)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.credit_card,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "Wallet",
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: kToolbarHeight,
                  child: DefaultTabController(
                    initialIndex: 0,
                    length: 4,
                    child: Builder(builder: (context) {
                      return Column(
                        children: [
                          TabBar(
                            controller: DefaultTabController.of(context),
                            onTap: (index) {
                              if (index == 0) {
                                salesController.getSalesByDate(
                                  shop: userController
                                      .currentUser.value!.primaryShop!.id!,
                                  status: "cashed",
                                  paymentType: "credit",
                                  customerid: customerController
                                      .currentCustomer.value?.sId,
                                );
                              } else if (index == 1) {
                                salesController.getSalesByDate(
                                    shop: userController
                                        .currentUser.value!.primaryShop!.id!,
                                    status: "cashed",
                                    customerid: customerController
                                        .currentCustomer.value?.sId);
                              } else if (index == 2) {
                                salesController.getReturns(
                                    customerModel: customerController
                                        .currentCustomer.value!,
                                    type: "return",
                                    shopid: userController
                                        .currentUser.value!.primaryShop!.id!);
                              } else if (index == 3) {
                                customerController.getTransactions(
                                    "all",
                                    customerController
                                        .currentCustomer.value!.sId!);
                              }
                            },
                            tabs: const [
                              Tab(
                                  child: Text(
                                "Credit",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                              Tab(
                                  child: Text(
                                "Sales",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                              Tab(
                                  child: Text(
                                "Returns",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                              Tab(
                                  child: Text(
                                "Statement",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                            ],
                            isScrollable: true,
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: Colors.white,
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  CreditInfo(
                                      customerModel: customerController
                                          .currentCustomer.value!),
                                  SalesTab(),
                                  ReturnsTab(),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20),
                                    child: Obx(
                                      () => DataTable2(
                                        minWidth: 400,
                                        horizontalMargin: 5,
                                        columns: const [
                                          DataColumn2(
                                            label: Text('Date'),
                                          ),
                                          DataColumn(
                                            label: Text('In'),
                                          ),
                                          DataColumn(
                                            label: Text('Out'),
                                          ),
                                          DataColumn(
                                            label: Text('Balance'),
                                          )
                                        ],
                                        rows: List<DataRow>.generate(
                                            customerController.deposits.length,
                                            (index) {
                                          Payment? payment = customerController
                                              .deposits
                                              .elementAt(index);

                                          return DataRow(cells: [
                                            DataCell(Text(
                                              DateFormat("dd-MM-yyyy HH:mm:a")
                                                  .format(DateTime.parse(
                                                      payment.date!)),
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            )),
                                            DataCell(Text(
                                              "${payment.type == "withdraw" ? "" : "-${htmlPrice(payment.amount ?? 0)}"} ",
                                              style: TextStyle(
                                                color:
                                                    payment.type == "withdraw"
                                                        ? Colors.red
                                                        : Colors.green,
                                                fontSize: 12,
                                              ),
                                            )),
                                            DataCell(Text(
                                              "${payment.type == "withdraw" ? "+${htmlPrice(payment.amount ?? 0)}" : ""} ",
                                              style: TextStyle(
                                                  color:
                                                      payment.type == "withdraw"
                                                          ? Colors.red
                                                          : Colors.green,
                                                  fontSize: 12),
                                            )),
                                            DataCell(Text(htmlPrice(
                                              payment.balance ?? 0,
                                            ))),
                                          ]);
                                        }),
                                        isHorizontalScrollBarVisible: true,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                  ),
                ),
              )
            ],
          ),
        ),
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: AppColors.mainColor,
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          actions: [
            IconButton(
                onPressed: () {
                  customerController.assignTextFields(
                      customerController.currentCustomer.value!);
                  Get.to(() => EditCustomer());
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                )),
            if (verifyPermission(category: "customers", permission: "manage"))
              IconButton(
                  onPressed: () {
                    generalAlert(
                        title:
                            "Are you sure you want to delete ${customerController.currentCustomer.value!.name}",
                        function: () {
                          customerController.deleteCustomer(
                              customerController.currentCustomer.value!);
                        });
                  },
                  icon: const Icon(Icons.delete, color: Colors.white)),
          ],
        ));
  }

  showModalSheet(context) {
    return showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
              height: 200,
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward),
                            SizedBox(
                              width: 10,
                            ),
                            Text('Credit History ')
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
                            Icon(Icons.cloud_download_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text('Purchase History')
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

class SalesTab extends StatelessWidget {
  SalesTab({Key? key}) : super(key: key);

  final CustomerController customerController = Get.find<CustomerController>();
  final SupplierController supplierController = Get.find<SupplierController>();
  final ShopController createShopController = Get.find<ShopController>();
  final SalesController salesController = Get.find<SalesController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return salesController.loadingSales.value
          ? const Center(child: CircularProgressIndicator())
          : salesController.allSales.isEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 50),
                  child: const Text(
                    "No entries",
                    textAlign: TextAlign.center,
                  ))
              : ListView.builder(
                  itemCount: salesController.allSales.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    SaleModel saleOrder =
                        salesController.allSales.elementAt(index);
                    return salesCard(
                        salesModel: saleOrder, from: 'customerpage');
                  });
    });
  }
}

class ReturnsTab extends StatelessWidget {
  ReturnsTab({Key? key}) : super(key: key);

  final SalesController salesController = Get.find<SalesController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return salesController.allSalesReturns.isEmpty
          ? Container(
              margin: const EdgeInsets.only(top: 50),
              child: const Text(
                "No entries",
                textAlign: TextAlign.center,
              ))
          : ListView.builder(
              itemCount: salesController.allSalesReturns.length,
              itemBuilder: (context, index) {
                SaleRetuns saleReturnItems =
                    salesController.allSalesReturns.elementAt(index);
                return saleReturnCard(saleReturnItems);
              });
    });
  }
}

class CreditInfo extends StatelessWidget {
  final Customer customerModel;
  final SalesController salesController = Get.find<SalesController>();

  CreditInfo({Key? key, required this.customerModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return salesController.loadingSales.value
          ? const Center(child: CircularProgressIndicator())
          : salesController.creditSales.isEmpty
              ? const Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        "No entries found.",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    Center(
                      child: Text(
                        "For now",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ))
              : ListView.builder(
                  itemCount: salesController.creditSales.length,
                  itemBuilder: (context, index) {
                    SaleModel salesBody =
                        salesController.creditSales.elementAt(index);

                    return salesCard(salesModel: salesBody);
                  });
    });
  }
}

showBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
            height: 150,
            child: Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.7),
                    child: const Text('Manage Bank')),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // editingDialog(
                      //   context: context,
                      //   onPressed: () {},
                      // );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Edit')
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      deleteDialog(context: context, onPressed: () {});
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Delete')
                      ],
                    ),
                  ),
                ),
              ],
            )));
      });
}
