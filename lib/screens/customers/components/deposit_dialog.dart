import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/customercontroller.dart';
import 'package:pointify/models/payment.dart';

import '../../../models/customer.dart';

showDepositDialog(
    {required context,
    required Customer customerModel,
    required title,
    String? page,
    String? size,
    Payment? depositModel}) {
  CustomerController walletController = Get.find<CustomerController>();
  if (title == "edit") {
    walletController.amountController.text = depositModel!.amount.toString();
  }
  return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width > 600
                ? MediaQuery.of(context).size.width * 0.2
                : MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title".capitalize!,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: walletController.amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      hintText: title == "edit"
                          ? depositModel!.amount.toString()
                          : "Amount",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5))),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  enabled: false,
                  decoration: InputDecoration(
                      hintText:
                          DateFormat("MMMM/dd/yyyy").format(DateTime.now()),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5))),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (title == "edit") {
                          walletController.amountController.text = "";
                        }
                      },
                      child: Text(
                        "Cancel".toUpperCase(),
                        style: const TextStyle(color: Colors.purple),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        if (title == "edit") {
                        } else {
                          walletController.deposit(
                              customerModel, context, page, size);
                        }
                      },
                      child: Text(
                        (title == "Deposit" ? "Deposit" : "Pay").toUpperCase(),
                        style: const TextStyle(color: Colors.purple),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      });
}
