import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/saleitem.dart';
import 'package:pointify/widgets/alert.dart';

import '../../../controllers/salescontroller.dart';

salesDialog(
    {required TextEditingController controller,
    required SaleItem receiptItem,
    required index}) {
  SalesController salesController = Get.find<SalesController>();
  Get.find<ProductController>();
  controller.text = receiptItem.quantity.toString();
  return showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Qty"),
          content: Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,3}'),
                  ),
                ],
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
                final quantity = double.tryParse(
                  controller.text.trim(),
                );

                if (quantity == null || quantity <= 0) {
                  generalAlert(
                    title: "Error",
                    message: "Enter a valid quantity greater than zero",
                  );
                  return;
                }

                final availableQuantity = receiptItem.product?.quantity ?? 0;

                if (receiptItem.product?.type != "service" &&
                    quantity > availableQuantity &&
                    userController.currentUser.value?.primaryShop
                            ?.allownegativeselling ==
                        false) {
                  generalAlert(
                    title: "Error",
                    message:
                        "Quantity cannot be greater than $availableQuantity",
                  );
                  return;
                }

                Navigator.pop(context);

                receiptItem.quantity = quantity;
                controller.clear();

                salesController.calculateAmount(
                  index,
                  totalDiscount: salesController
                          .receipt.value?.items?[index].lineDiscount ??
                      0,
                );
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
