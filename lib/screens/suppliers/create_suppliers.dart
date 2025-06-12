import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/screens/product/create_product.dart';
import 'package:pointify/screens/sales/create_sale.dart';
import 'package:pointify/screens/suppliers/suppliers_page.dart';

import '../../../../utils/colors.dart';
import '../../controllers/customercontroller.dart';
import '../../controllers/homecontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../controllers/suppliercontroller.dart';
import '../../main.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';

class CreateSuppliers extends StatelessWidget {
  final String? page;

  CreateSuppliers({Key? key, required this.page}) : super(key: key) {
    supplierController.nameController.clear();
    supplierController.phoneController.clear();
    // if (supplierController.importedSuppliers.length == 0) {
    //   supplierController.importContacts();
    // }
  }

  final CustomerController customersController = Get.find<CustomerController>();
  final  SupplierController supplierController = Get.find<SupplierController>();
  final  ShopController shopController = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.96),
      appBar: AppBar(
          elevation: 0.3,
          titleSpacing: 0.0,
          centerTitle: false,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              if (!isSmallScreen(context)) {
                if (page == "suppliersPage") {
                  Get.find<HomeController>().selectedWidget.value =
                      SuppliersPage();
                }
                if (page == "createSale") {
                  Get.find<HomeController>().selectedWidget.value =
                      CreateSale();
                }
                if (page == "createProduct") {
                  Get.find<HomeController>().selectedWidget.value =
                      CreateProduct(
                    page: "create",
                    productModel: null,
                  );
                }
                if (page == "createPurchase") {
                  // Get.find<HomeController>().selectedWidget.value =
                  //     CreatePurchase();
                }
              } else {
                Get.back();
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              majorTitle(
                  title: "Supplier Details", color: Colors.black, size: 16.0),
              minorTitle(
                  title: userController.currentUser.value?.primaryShop?.name,
                  color: Colors.grey),
            ],
          )),
      body: Column(
        children: [
          TabBar(
              controller: supplierController.tabController,
              onTap: (value) {},
              tabs: const [
                Tab(
                  child: Text(
                    "Add New",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                Tab(
                  child: Text(
                    "Import",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                )
              ]),
          Expanded(
              child: TabBarView(
                  controller: supplierController.tabController,
                  children: [
                SingleChildScrollView(
                  child: customerInfoCard(context),
                ),
                Obx(() {
                  return supplierController.loadingImportedSuppliers.value
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: TextFormField(
                                onChanged: (value) {
                                  // if (value.isNotEmpty) {
                                  //   //filter based on the text entered
                                  //   supplierController.filteredSuppliers.value =
                                  //       supplierController.importedSuppliers
                                  //           .where((element) {
                                  //     return element.displayName
                                  //             .toLowerCase()
                                  //             .contains(value.toLowerCase()) &&
                                  //         !supplierController.suppliers
                                  //             .contains(
                                  //                 element.phones.first.number);
                                  //   }).toList();
                                  // } else {
                                  //   supplierController.filteredSuppliers.value =
                                  //       supplierController.importedSuppliers;
                                  // }
                                },
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  suffixIcon: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.search),
                                  ),
                                  hintText: "Search Contact by name",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ),
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 1)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 1)),
                                ),
                              ),
                            ),
                            Container()
                            // Expanded(
                            //     child: ListView.builder(
                            //         shrinkWrap: true,
                            //         itemCount: supplierController
                            //             .filteredSuppliers.length,
                            //         itemBuilder: (context, index) {
                            //           Contact contact = supplierController
                            //               .filteredSuppliers
                            //               .elementAt(index);
                            //           return Container(
                            //             padding: EdgeInsets.all(10),
                            //             width:
                            //                 MediaQuery.of(context).size.width,
                            //             child: Row(
                            //               children: [
                            //                 Icon(Icons.person),
                            //                 SizedBox(
                            //                   width: 10,
                            //                 ),
                            //                 Column(
                            //                   crossAxisAlignment:
                            //                       CrossAxisAlignment.start,
                            //                   children: [
                            //                     minorTitle(
                            //                         title: contact.displayName,
                            //                         color: Colors.grey),
                            //                     majorTitle(
                            //                         title: contact.phones[0]
                            //                             .normalizedNumber,
                            //                         color: Colors.black,
                            //                         size: 13.0)
                            //                   ],
                            //                 ),
                            //                 Spacer(),
                            //                 InkWell(
                            //                   onTap: () {
                            //                     supplierController
                            //                         .importSupplier(
                            //                             contact: contact);
                            //                   },
                            //                   child: Row(
                            //                     children: [
                            //                       Icon(Icons.add,
                            //                           color: Colors.black),
                            //                       minorTitle(
                            //                           title: "Import",
                            //                           color: Colors.black)
                            //                     ],
                            //                   ),
                            //                 )
                            //               ],
                            //             ),
                            //           );
                            //         })),
                          ],
                        );
                })
              ]))
        ],
      ),
    );
  }

  Widget customerInfoCard(context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text("Supplier Name".capitalize!),
              const SizedBox(height: 10),
              TextFormField(
                controller: supplierController.nameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    isDense: true,
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                    hintText: "eg.John Doe",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    filled: true,
                    fillColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Phone"),
              const SizedBox(height: 10),
              TextFormField(
                  controller: supplierController.phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                    hintText: "eg.07XXXXXXXX",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                  ))
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),
          InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () async {
              await supplierController.createSupplier(
                  context: context, page: page);
            },
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.25,
                decoration: BoxDecoration(
                    border: Border.all(width: 3, color: AppColors.mainColor),
                    borderRadius: BorderRadius.circular(40)),
                child: Center(
                    child: majorTitle(
                        title: "Save", color: AppColors.mainColor, size: 18.0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
