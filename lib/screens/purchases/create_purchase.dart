import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/main.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/screens/purchases/purchases_preview.dart';
import 'package:pointify/screens/suppliers/suppliers_page.dart';
import 'package:pointify/widgets/alert.dart';

import '../../../../utils/colors.dart';
import '../../controllers/homecontroller.dart';
import '../../controllers/productcontroller.dart';
import '../../controllers/purchase_controller.dart';
import '../../controllers/shopcontroller.dart';
import '../../controllers/suppliercontroller.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';
import '../product/products_page.dart';
import '../suppliers/create_suppliers.dart';
import 'components/invoice_card.dart';

class CreatePurchase extends StatelessWidget {
  CreatePurchase({Key? key}) : super(key: key) {
    purchaseController.selectedpaymentMethod.value = "Cash";
    supplierController.getSuppliers("all");
  }

  final PurchaseController purchaseController = Get.find<PurchaseController>();
  final ShopController shopController = Get.find<ShopController>();
  final SupplierController supplierController = Get.find<SupplierController>();
  final ProductController productController = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvoked: (val) => purchaseController.invoice.value?.items!.clear(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.3,
            titleSpacing: 0.0,
            leading: IconButton(
                onPressed: () {
                  purchaseController.invoice.value = null;

                  Get.back();
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                )),
            title: majorTitle(
                title: "Create a purchase", color: Colors.black, size: 20.0),
            actions: [
              if (!isSmallScreen(context) &&
                  purchaseController.invoice.value != null)
                InkWell(
                  onTap: () async {
                    saveFunction(context);
                  },
                  child: Container(
                    height: kToolbarHeight * 0.5,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    margin: const EdgeInsets.symmetric(vertical: 10)
                        .copyWith(right: 10),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.mainColor),
                        borderRadius: BorderRadius.circular(5)),
                    child:  Text(
                      "Create Purchase",
                      style: TextStyle(color: AppColors.mainColor),
                    ),
                  ),
                )
            ],
          ),
          body: Column(
            children: [
              Material(
                elevation: 1,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _addItems(context);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 15, 10),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15)),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Select products to stock"),
                                    Icon(Icons.arrow_drop_down,
                                        color: Colors.grey)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                // productController.scanQR(
                                //     context: context, type: 'stock');
                              },
                              icon: const Icon(Icons.qr_code))
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller:
                                  purchaseController.selectedSupplierController,
                              onTap: () {
                                Get.to(() => Suppliers(
                                      from: "purchases",
                                    ));
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.fromLTRB(10, 2, 10, 2),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    if (purchaseController
                                            .selectedSupplier.value !=
                                        null) {
                                      purchaseController
                                          .selectedSupplierController
                                          .clear();
                                      purchaseController
                                          .selectedSupplier.value = null;
                                    } else {
                                      // Get.to(() => _gotoSupplierPage(context));
                                      Get.to(() => Suppliers(
                                            from: "purchases",
                                          ));
                                    }
                                  },
                                  icon:  Icon(
                                    Icons.cancel,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                                hintText: "Select supplier",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  return purchaseController.invoice.value == null
                      ? InkWell(
                          onTap: () {
                            _addItems(context);
                          },
                          child:  Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_outlined,
                                size: 40,
                                color: AppColors.mainColor,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "purchase items",
                                style: TextStyle(
                                    color: AppColors.mainColor, fontSize: 21),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              purchaseController.invoice.value!.items!.length,
                          itemBuilder: (context, index) {
                            InvoiceItem invoiceItem = purchaseController
                                .invoice.value!.items!
                                .elementAt(index);
                            return createPurchaseCard(
                                invoiceItem: invoiceItem, index: index);
                          });
                }),
              ),
            ],
          ),
          bottomNavigationBar: Obx(() {
            return BottomAppBar(
              color: Colors.white,
              child: purchaseController.invoice.value == null
                  ? Container(height: 0)
                  : createPurchase(context),
            );
          }),
        ));
  }

  void _addItems(BuildContext context) {
    Get.to(() => ProductPage(
          type: "purchase",
          function: (Product product) {
            purchaseController.addNewPurchase(product);
            Get.back();
          },
        ));
  }

  Widget createPurchase(context) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        saveFunction(context);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(width: 3, color: AppColors.mainColor),
            borderRadius: BorderRadius.circular(40)),
        child: Center(
            child: majorTitle(
                title: "Create Purchase",
                color: AppColors.mainColor,
                size: 18.0)),
      ),
    );
  }

  saveFunction(context) {
    if (purchaseController.invoice.value == null ||
        purchaseController.invoice.value!.items!.isEmpty) {
      generalAlert(title: "Error!", message: "Please select products to sell");
      return;
    }
    Get.to(() => PurchaesPreview(
          page: 'admin',
        ));
    // if (purchaseController.invoice.value == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("Please select products to sell")));
    // } else {
    //   if (purchaseController.selectedpaymentMethod.value.toLowerCase() ==
    //       "credit") {
    //     generalAlert(
    //         title: "Credit purchase",
    //         message: "Are you sure you want to make credit purchase?",
    //         function: () {
    //           showModalBottomSheet(
    //             context: context,
    //             isScrollControlled: true,
    //             backgroundColor:
    //                 isSmallScreen(context) ? Colors.white : Colors.transparent,
    //             builder: (context) {
    //               return Padding(
    //                 padding: EdgeInsets.only(
    //                     bottom: MediaQuery.of(context).viewInsets.bottom),
    //                 child: Container(
    //                   color: Colors.white,
    //                   margin: EdgeInsets.only(
    //                       left: isSmallScreen(context)
    //                           ? 0
    //                           : MediaQuery.of(context).size.width * 0.2),
    //                   padding: const EdgeInsets.symmetric(
    //                       horizontal: 10, vertical: 10),
    //                   child: Obx(
    //                     () => Column(
    //                       crossAxisAlignment: CrossAxisAlignment.start,
    //                       mainAxisSize: MainAxisSize.min,
    //                       children: [
    //                         Row(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             Expanded(
    //                               flex: 3,
    //                               child: Column(
    //                                 crossAxisAlignment:
    //                                     CrossAxisAlignment.start,
    //                                 children: [
    //                                   minorTitle(
    //                                       title: "Amount paid",
    //                                       color: Colors.black),
    //                                   const SizedBox(
    //                                     height: 10,
    //                                   ),
    //                                   TextFormField(
    //                                     keyboardType: TextInputType.number,
    //                                     autofocus: true,
    //                                     controller: purchaseController
    //                                         .textEditingControllerAmount,
    //                                     onChanged: (value) {
    //                                       purchaseController.calculateAmount();
    //                                       purchaseController.invoice.refresh();
    //                                     },
    //                                     decoration: InputDecoration(
    //                                         isDense: true,
    //                                         contentPadding:
    //                                             const EdgeInsets.fromLTRB(
    //                                                 10, 10, 10, 0),
    //                                         border: OutlineInputBorder(
    //                                             borderRadius:
    //                                                 BorderRadius.circular(10)),
    //                                         prefix: Text(
    //                                             "${userController.currentUser.value!.primaryShop?.currency!} ")),
    //                                   ),
    //                                 ],
    //                               ),
    //                             ),
    //                             const Spacer(),
    //                             Expanded(
    //                               flex: 2,
    //                               child: Column(
    //                                 crossAxisAlignment:
    //                                     CrossAxisAlignment.start,
    //                                 children: [
    //                                   majorTitle(
    //                                       title: "Total",
    //                                       color: Colors.black,
    //                                       size: 13.0),
    //                                   const SizedBox(
    //                                     height: 3,
    //                                   ),
    //                                   Obx(() {
    //                                     return minorTitle(
    //                                         title: htmlPrice(purchaseController
    //                                             .invoice.value?.totalAmount),
    //                                         color: Colors.grey,
    //                                         size: 14);
    //                                   }),
    //                                   const SizedBox(
    //                                     height: 8,
    //                                   ),
    //                                   majorTitle(
    //                                       title: purchaseController.balanceText,
    //                                       color: Colors.black,
    //                                       size: 13.0),
    //                                   const SizedBox(
    //                                     height: 3,
    //                                   ),
    //                                   Obx(() {
    //                                     return minorTitle(
    //                                         title: htmlPrice(purchaseController
    //                                             .balance
    //                                             .abs()),
    //                                         color: Colors.grey,
    //                                         size: 11);
    //                                   })
    //                                 ],
    //                               ),
    //                             )
    //                           ],
    //                         ),
    //                         const SizedBox(
    //                           height: 20,
    //                         ),
    //                         Row(
    //                           mainAxisAlignment: MainAxisAlignment.start,
    //                           children: [
    //                             TextButton(
    //                                 onPressed: () {
    //                                   Navigator.pop(context);
    //                                 },
    //                                 child: majorTitle(
    //                                     title: "Cancel",
    //                                     color: Colors.red,
    //                                     size: 16.0)),
    //                             const SizedBox(width: 30),
    //                             TextButton(
    //                                 onPressed: () {
    //                                   purchaseController.createPurchase();
    //                                 },
    //                                 child: majorTitle(
    //                                     title: "Cash in",
    //                                     color: AppColors.mainColor,
    //                                     size: 16.0)),
    //                             const SizedBox(width: 10),
    //                           ],
    //                         )
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               );
    //             },
    //           );
    //         });
    //     // return;
    //   } else {
    //     purchaseController.createPurchase();
    //   }
    // }
  }

  Scaffold _gotoSupplierPage(context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0.0,
        elevation: 0.3,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            if (isSmallScreen(Get.context)) {
              Get.back();
            } else {
              Get.find<HomeController>().selectedWidget.value =
                  CreatePurchase();
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            majorTitle(title: "Supplier", color: Colors.black, size: 16.0),
            minorTitle(
                title: "${userController.currentUser.value!.primaryShop?.name}",
                color: Colors.grey)
          ],
        ),
        actions: [
          if (verifyPermission(category: "suppliers", permission: "manage"))
            InkWell(
              onTap: () {
                if (isSmallScreen(Get.context)) {
                  Get.to(() => CreateSuppliers(
                        page: "createPurchase",
                      ));
                } else {
                  Get.find<HomeController>().selectedWidget.value =
                      CreateSuppliers(
                    page: "createPurchase",
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: (BorderRadius.circular(10)),
                      border: Border.all(color: AppColors.mainColor, width: 1)),
                  child: Center(
                    child: majorTitle(
                        title: "Add Supplier",
                        color: AppColors.mainColor,
                        size: 12.0),
                  ),
                ),
              ),
            )
        ],
      ),
      body: Suppliers(
        from: "purchases",
        function: () {
          saveFunction(Get.context);
        },
      ),
    );
  }
}
