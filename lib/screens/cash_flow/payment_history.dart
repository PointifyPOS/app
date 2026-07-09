import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/reports_controller.dart';
import 'package:pointify/controllers/usercontroller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/screens/customers/components/cash_receipt.dart';
import 'package:pointify/widgets/no_items_found.dart';

import '../../controllers/paymentcontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';

// ignore: must_be_immutable
class PaymentHistory extends StatelessWidget {
  final String? type;
  String? saleId;
  final Customer? customerModel;

  PaymentHistory({super.key, this.customerModel, this.type, this.saleId});

  final ShopController shopController = Get.find<ShopController>();
  final PaymentController paymentController = Get.find<PaymentController>();
  ReportsController reportsController = Get.find<ReportsController>();
  UserController userController = Get.find<UserController>();
  final TextEditingController searchController = TextEditingController();

  Widget _miniChip(
    String title,
    dynamic amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$title: ${htmlPrice(amount)}",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Obx(
          () => Text(
            "Payment History (${paymentController.payments.length})",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
      ),
      body: Obx(
        () {
          if (paymentController.isPaymentLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search customer name or phone",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    paymentController.paymentSearch.value = value;
                  },
                ),
              ),
              if (paymentController.payments.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniChip(
                            "Cash",
                            reportsController.debtbreakdown['cash'] ?? 0,
                            Colors.green,
                          ),
                          _miniChip(
                            "Mpesa",
                            reportsController.debtbreakdown['mpesa'] ?? 0,
                            Colors.blue,
                          ),
                          _miniChip(
                            "Bank",
                            reportsController.debtbreakdown['bank'] ?? 0,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: paymentController.payments.isEmpty
                    ? noItemsFound(context, false)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        itemCount: paymentController.payments.length,
                        itemBuilder: (context, index) {
                          final Payment payHistory =
                              paymentController.payments[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Get.to(
                                () => CashReceipt(
                                  receipt: payHistory,
                                  saleId: saleId,
                                  customer: customerModel,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              Colors.green.shade100,
                                          child: const Icon(
                                            Icons.payments_outlined,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                payHistory.customerId?.name ??
                                                    "Walk-in Customer",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (payHistory.date != null)
                                                Text(
                                                  DateFormat(
                                                    "dd MMM yyyy • HH:mm",
                                                  ).format(
                                                    DateTime.parse(
                                                      payHistory.date!,
                                                    ).toLocal(),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          htmlPrice(
                                            payHistory.amount ?? 0,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
