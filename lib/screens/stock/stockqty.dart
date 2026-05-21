import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/models/product.dart';

import '../../controllers/stockcontroller.dart';

stockDialog({required index, required Product product}) {
  final StockController stockTransferController = Get.find<StockController>();
  final ProductNewController productNewController =
      Get.find<ProductNewController>();

  return showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Qty"),
          content: Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
                controller: stockTransferController.textEditingControllerQty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: "0",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ))),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel".toUpperCase(),
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (double.parse(
                        stockTransferController.textEditingControllerQty.text) >
                    product.quantity!) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Quantity cannot be greater than${product.quantity}")));
                } else {
                  productNewController.selectedTransferProducts[index]
                          ["quantity"] =
                      double.parse(stockTransferController
                          .textEditingControllerQty.text);
                  productNewController.selectedTransferProducts.refresh();
                  stockTransferController.textEditingControllerQty.clear();
                }
              },
              child: Text(
                "Save now".toUpperCase(),
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      });
}
