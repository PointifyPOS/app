import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/productcount.dart';
import 'package:pointify/models/transferhistory.dart';
import 'package:pointify/services/product_service.dart';
import 'package:pointify/widgets/alert.dart';
import 'package:pointify/widgets/loading_dialog.dart';

import '../models/product.dart';
import '../models/shop.dart';
import '../screens/stock/transfer_history.dart';
import '../utils/colors.dart';

class StockController extends GetxController {

  RxList<Product> productsCount = RxList([]);
  RxList<Product> productsCountCart = RxList([]);
  Rxn<Product> selectedProductCount = Rxn();
  RxList<TransferHistory> transferHistory = RxList([]);
  final GlobalKey<State> _keyLoader = GlobalKey<State>();

  TextEditingController textEditingControllerQty = TextEditingController();
  TextEditingController textEditingControllerCount = TextEditingController();

  RxBool gettingTransferHistoryLoad = RxBool(false);
  RxBool isSavingingCount = RxBool(false);
  RxBool isLoadingCount = RxBool(false);
  RxList<ProductCount> countHistory = RxList([]);

  RxString activeItem = RxString("Transfer In");
  RxString filterDate =
      RxString(DateFormat("MMM dd, yyyy").format(DateTime.now()));

  

  

  incrementQuantityWidget(context, Product product) {
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text(
              "Update product count",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: textEditingControllerCount,
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onChanged: (v) => {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  "Cancel".toUpperCase(),
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  int index = productsCountCart
                      .indexWhere((element) => element.sId == product.sId);
                  if (index != -1) {
                    productsCountCart[index].lastCount =
                        int.parse(textEditingControllerCount.text);
                  } else {
                    product.lastCount =
                        int.parse(textEditingControllerCount.text);
                    productsCountCart.add(product);
                  }
                  productsCountCart.refresh();
                  productsCount.refresh();
                  Get.back();
                  textEditingControllerCount.clear();
                },
                child: Text(
                  "Update".toUpperCase(),
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        });
  }

  gettingTransferHistory(
      {String? startDate = "",
      String? toDate = "",
      String? shopid = "",
      String? direction = ""}) async {
    try {
      transferHistory.clear();
      gettingTransferHistoryLoad.value = true;
      List<dynamic> response = await ProductService().getTransferHistory(
          startDate: startDate,
          toDate: toDate,
          shopid: shopid,
          direction: direction);
      transferHistory
          .addAll(response.map((e) => TransferHistory.fromJson(e)).toList());
      gettingTransferHistoryLoad.value = false;
      refresh();
    } catch (e) {
      gettingTransferHistoryLoad.value = false;
    }
  }

  Future<void> countProduct() async {
    LoadingDialog.showLoadingDialog(
        context: Get.context!, title: "Please wait", key: _keyLoader);
    var productdata = {
      "attendantId": userController.currentUser.value!.attendantId,
      "useWarehouse":
          userController.currentUser.value!.primaryShop!.useWarehouse,
      "shopId": userController.currentUser.value!.primaryShop!.id,
      "products": productsCountCart
          .map((element) =>
              {"productId": element.sId, "physicalCount": element.lastCount!})
          .toList()
    };
    var response = await ProductService.countProduct(productdata);
    Get.back();
    if (response["error"] != null) {
      generalAlert(message: response["error"], title: "Error");
      return;
    }
    productsCountCart.clear();
    Get.find<ProductController>().getProductsBySort(type: "all");
    Get.back();
  }

  getCountHistory(
      {Product? product, String? fromDate = "", String? toDate = ""}) async {
    countHistory.clear();
    isLoadingCount.value = true;
    List<dynamic> productCountHistory = await ProductService.getCountHistory(
        shop: userController.currentUser.value!.primaryShop!.id,
        toDate: toDate,
        fromDate: fromDate);
    countHistory.addAll(
        productCountHistory.map((e) => ProductCount.fromJson(e)).toList());
    isLoadingCount.value = false;
  }
}
