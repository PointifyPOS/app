import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/productcount.dart';
import 'package:pointify/models/transferhistory.dart';
import 'package:pointify/services/product_service.dart';
import 'package:pointify/sqlite/helper.dart';
import 'package:pointify/widgets/alert.dart';
import 'package:pointify/widgets/loading_dialog.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/shop.dart';
import '../screens/stock/transfer_history.dart';
import '../utils/colors.dart';
import '../utils/helper.dart';
import '../widgets/snackBars.dart';

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

  RxString activeItem = RxString('Transfer In');
  RxString filterDate =
      RxString(DateFormat('MMM dd, yyyy').format(DateTime.now()));

  incrementQuantityWidget(context, Product product) {
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Update product count',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
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
                        borderRadius: BorderRadius.circular(5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'.toUpperCase(),
                    style: TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  final idx =
                      productsCountCart.indexWhere((e) => e.sId == product.sId);
                  if (idx != -1) {
                    productsCountCart[idx].lastCount =
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
                child: Text('Update'.toUpperCase(),
                    style: TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
  }

  gettingTransferHistory({
    String? startDate = '',
    String? toDate = '',
    String? shopid = '',
    String? direction = '',
  }) async {
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

  // countProduct — saves offline if no internet, syncs back on reconnect
  Future<void> countProduct() async {
    LoadingDialog.showLoadingDialog(
        context: Get.context!, title: 'Please wait', key: _keyLoader);

    final productdata = {
      'attendantId': userController.currentUser.value!.attendantId?.sId,
      'useWarehouse':
          userController.currentUser.value!.primaryShop!.useWarehouse,
      'shopId': userController.currentUser.value!.primaryShop!.id,
      'products': productsCountCart
          .map((e) => {'productId': e.sId, 'physicalCount': e.lastCount!})
          .toList(),
    };

    final connected = await isConnected();

    if (!connected) {
      Get.back(); // close loader
      await DatabaseHelper().insertStockCountOffline(productdata);
      // Update local quantities immediately so UI is accurate
      for (final p in productsCountCart) {
        await DatabaseHelper()
            .updateProduct({'id': p.sId, 'quantity': p.lastCount});
      }
      productsCountCart.clear();
      Get.find<ProductController>().getProductsBySort(type: 'all');
      showSnackBar(
          message: 'Stock count saved offline — will sync when connected',
          color: Colors.orange);
      Get.back();
      return;
    }

    final response = await ProductService.countProduct(productdata);
    Get.back(); // close loader
    if (response['error'] != null) {
      generalAlert(message: response['error'], title: 'Error');
      return;
    }
    productsCountCart.clear();
    Get.find<ProductController>().getProductsBySort(type: 'all');
    Get.back();
  }

  getCountHistory(
      {Product? product, String? fromDate = '', String? toDate = ''}) async {
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
