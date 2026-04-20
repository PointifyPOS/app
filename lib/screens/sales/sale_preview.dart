import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/widgets/minor_title.dart';

import '../../controllers/customercontroller.dart';
import '../../controllers/salescontroller.dart';
import '../../functions/functions.dart';
import '../../main.dart';
import '../../models/customer.dart';
import '../../utils/colors.dart';
import '../../widgets/alert.dart';
import '../../widgets/major_title.dart';
import '../customers/customers_page.dart';

class SalePreview extends StatelessWidget {
  final String? page;
  SalePreview({
    super.key,
    this.page,
  });

  final SalesController salesController = Get.find<SalesController>();
  final CustomerController customersController = Get.find<CustomerController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.3,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title:
            majorTitle(title: "Sale Preview", color: Colors.black, size: 16.0),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: majorTitle(
                fontWeight: FontWeight.normal,
                title: "Sale Total",
                color: Colors.black,
                size: 19.0,
              ),
            ),
            Center(
              child: majorTitle(
                title: htmlPrice(
                  salesController.receipt.value?.totalWithDiscount
                          ?.toStringAsFixed(2) ??
                      0,
                ),
                color: Colors.black,
                size: 19.0,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: majorTitle(
                title: "Select Payment Method",
                color: Colors.black,
                size: 19.0,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: salesController.paymentMethods.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      if (salesController.receipt.value == null ||
                          salesController.receipt.value!.items!.isEmpty) {
                        generalAlert(title: "No items to pay");
                        return;
                      }
                      salesController.paymentType.value =
                          salesController.paymentMethods[index];
                      _sell(
                        paymentType: salesController.paymentMethods[index],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20, top: 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 1, color: Colors.grey),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  majorTitle(
                                    title:
                                        salesController.paymentMethods[index],
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    size: 19.0,
                                  ),
                                  if (salesController.currentCustomer.value !=
                                          null &&
                                      (salesController.paymentType.value ==
                                          salesController
                                              .paymentMethods[index]))
                                    minorTitle(
                                      title:
                                          "Customer: ${salesController.currentCustomer.value?.name?.capitalizeFirst}",
                                      color: Colors.black,
                                      size: 14.0,
                                    ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _needCustomer() {
    return salesController.paymentType.value == "Credit" ||
        salesController.paymentType.value == "Wallet";
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _sheetInputDecoration({
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.mainColor),
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.mainColor.withOpacity(0.10)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: highlighted
                ? AppColors.mainColor.withOpacity(0.25)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: highlighted ? AppColors.mainColor : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: highlighted ? AppColors.mainColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernCashField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Amount Received"),
        const SizedBox(height: 6),
        TextFormField(
          controller: salesController.amountPaid,
          onChanged: (value) {
            salesController.getTotalCredit();
            salesController.receipt.refresh();
          },
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: _sheetInputDecoration(
            prefixText:
                "${userController.currentUser.value!.primaryShop!.currency!} ",
            hintText: "Enter amount received",
          ),
        ),
      ],
    );
  }

  Widget _modernMpesaFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Amount Received"),
        const SizedBox(height: 6),
        TextFormField(
          controller: salesController.mpesaCashPaid,
          onChanged: (value) {
            salesController.amountPaid.text =
                salesController.mpesaCashPaid.text;
            salesController.getTotalCredit();
            salesController.receipt.refresh();
          },
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: _sheetInputDecoration(
            prefixText:
                "${userController.currentUser.value!.primaryShop!.currency!} ",
            hintText: "Enter amount received",
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel("Mpesa Transaction ID"),
        const SizedBox(height: 6),
        TextFormField(
          controller: salesController.mpesaTransId,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: _sheetInputDecoration(
            hintText: "Enter transaction ID",
          ),
        ),
      ],
    );
  }

  Widget _modernBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Amount Received"),
        const SizedBox(height: 6),
        TextFormField(
          controller: salesController.bankCashPaid,
          onChanged: (value) {
            salesController.amountPaid.text = salesController.bankCashPaid.text;
            salesController.getTotalCredit();
            salesController.receipt.refresh();
          },
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: _sheetInputDecoration(
            prefixText:
                "${userController.currentUser.value!.primaryShop!.currency!} ",
            hintText: "Enter amount received",
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel("Bank Transaction ID"),
        const SizedBox(height: 6),
        TextFormField(
          controller: salesController.bankTransId,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: _sheetInputDecoration(
            hintText: "Enter transaction ID",
          ),
        ),
      ],
    );
  }

  void confirmSplitPayment(status, {String paymentType = ""}) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Obx(
                () => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              paymentType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.mainColor.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              htmlPrice(
                                salesController.receipt.value?.totalWithDiscount
                                        ?.toStringAsFixed(2) ??
                                    0,
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel("Cash"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.cashPaid,
                        onChanged: (value) {
                          salesController.getTotalCredit();
                          salesController.receipt.refresh();
                        },
                        keyboardType: TextInputType.number,
                        decoration: _sheetInputDecoration(
                          prefixText:
                              "${userController.currentUser.value!.primaryShop!.currency!} ",
                          hintText: "Enter cash amount",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _fieldLabel("Mpesa"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.mpesaCashPaid,
                        onChanged: (value) {
                          salesController.getTotalCredit();
                          salesController.receipt.refresh();
                        },
                        keyboardType: TextInputType.number,
                        decoration: _sheetInputDecoration(
                          prefixText:
                              "${userController.currentUser.value!.primaryShop!.currency!} ",
                          hintText: "Enter mpesa amount",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _fieldLabel("Mpesa Code"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.mpesaTransId,
                        keyboardType: TextInputType.text,
                        decoration: _sheetInputDecoration(
                          hintText: "Enter mpesa code",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _fieldLabel("Bank"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.bankCashPaid,
                        onChanged: (value) {
                          salesController.getTotalCredit();
                          salesController.receipt.refresh();
                        },
                        keyboardType: TextInputType.number,
                        decoration: _sheetInputDecoration(
                          prefixText:
                              "${userController.currentUser.value!.primaryShop!.currency!} ",
                          hintText: "Enter bank amount",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _fieldLabel("Sales Note"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.salesnote,
                        keyboardType: TextInputType.text,
                        maxLines: 2,
                        decoration: _sheetInputDecoration(
                          hintText: "Optional note",
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              salesController.changeText.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              htmlPrice(
                                salesController.change.value.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: salesController.change.value > 0
                                    ? Colors.green.shade700
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.mainColor,
                                side: BorderSide(
                                  color: AppColors.mainColor.withOpacity(0.35),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                salesController.saveSale(
                                  screen: page ?? "admin",
                                  status: status,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Confirm Payment",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void confirmPayment(context, status, {String paymentType = ""}) {
    salesController.amountPaid.text = "";
    salesController.showSalesDiscount.value = false;

    final bool hasServiceItems = salesController.receipt.value?.items
            ?.any((e) => e.product?.type == "service") ??
        false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Obx(
                () => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              paymentType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.mainColor.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              htmlPrice(
                                salesController.receipt.value?.totalWithDiscount
                                        ?.toStringAsFixed(2) ??
                                    0,
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (paymentType == "Cash") _modernCashField(),
                      if (paymentType == "Mpesa") _modernMpesaFields(),
                      if (paymentType == "Bank") _modernBankFields(),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionChip(
                            label: salesController.showSalesDiscount.isTrue
                                ? "Hide Discount"
                                : "Add Discount",
                            icon: Icons.local_offer_outlined,
                            onTap: () {
                              salesController.showSalesDiscount.value =
                                  !salesController.showSalesDiscount.value;
                            },
                          ),
                          if (hasServiceItems &&
                              userController.currentUser.value?.primaryShop
                                      ?.shopCategoryId?.name ==
                                  "Laundry")
                            _actionChip(
                              label: salesController
                                      .readyDateController.text.isEmpty
                                  ? "Ready Date"
                                  : salesController.readyDateController.text,
                              icon: Icons.calendar_month_outlined,
                              highlighted: salesController
                                  .readyDateController.text.isNotEmpty,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  initialDate: DateTime.now(),
                                );

                                if (picked != null) {
                                  salesController.readyDateController.text =
                                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  salesController.refresh();
                                }
                              },
                            ),
                        ],
                      ),
                      if (salesController.showSalesDiscount.isTrue) ...[
                        const SizedBox(height: 12),
                        _fieldLabel("Discount"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: salesController.saleDiscount,
                          keyboardType: TextInputType.number,
                          decoration: _sheetInputDecoration(
                            prefixText:
                                "${userController.currentUser.value!.primaryShop!.currency!} ",
                            hintText: "Enter discount",
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _fieldLabel("Sales Note"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: salesController.salesnote,
                        keyboardType: TextInputType.text,
                        maxLines: 2,
                        decoration: _sheetInputDecoration(
                          hintText: "Optional note",
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              salesController.changeText.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              htmlPrice(
                                salesController.change.value.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: salesController.change.value > 0
                                    ? Colors.green.shade700
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.mainColor,
                                side: BorderSide(
                                  color: AppColors.mainColor.withOpacity(0.35),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: checkEnoughAmountEntered() == false
                                  ? null
                                  : () {
                                      salesController.saveSale(
                                        screen: page ?? "admin",
                                        status: status,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Confirm Payment",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool checkEnoughAmountEntered() {
    final bool hasServiceItems = salesController.receipt.value?.items
            ?.any((e) => e.product?.type == "service") ??
        false;

    if (hasServiceItems) {
      return toDouble(
            salesController.amountPaid.text.isEmpty
                ? 0
                : salesController.amountPaid.text,
          ) >
          0;
    }

    return toDouble(
          salesController.amountPaid.text.isEmpty
              ? 0
              : salesController.amountPaid.text,
        ) >=
        toDouble(salesController.receipt.value?.totalWithDiscount);
  }

  void _sell({String status = "cashed", String paymentType = ""}) {
    if (salesController.currentCustomer.value == null && _needCustomer()) {
      generalAlert(
        title: "Error!",
        message: "please select customer to sell to",
        function: () {
          customersController.getCustomersInShop("all");
          Get.to(
            () => Customers(
              type: "sale",
              function: (Customer? customer) {
                if (customer != null) {
                  if (paymentType == "Credit" || paymentType == "Wallet") {
                    if (paymentType == "Credit" &&
                        customer.creditLimit != null &&
                        customer.creditLimit != 0 &&
                        customer.creditLimit! <
                            salesController.receipt.value!.totalWithDiscount!) {
                      salesController.currentCustomer.value = null;
                      customersController.currentCustomer.value = null;
                      generalAlert(
                        title: "Error!",
                        message:
                            "Customer has reached credit limit to sell on credit",
                        function: () {
                          Get.back();
                        },
                      );
                      return;
                    }
                    generalAlert(
                      title: "Confirm",
                      message:
                          "Are you sure you want to sell on $paymentType to ${salesController.currentCustomer.value?.name}?",
                      function: () {
                        salesController.saveSale(
                          screen: page ?? "admin",
                          status: status,
                        );
                      },
                    );
                  }
                }
              },
            ),
          );
        },
      );
      return;
    }

    if (paymentType == "Credit") {
      if (salesController.currentCustomer.value?.creditLimit != null &&
          salesController.currentCustomer.value?.creditLimit != 0 &&
          salesController.currentCustomer.value!.creditLimit! <
              salesController.receipt.value!.totalWithDiscount!) {
        customersController.currentCustomer.value = null;
        salesController.currentCustomer.value = null;
        salesController.selectedCustomerController.clear();
        generalAlert(
          title: "Error!",
          message: "Customer has reached credit limit to sell on credit",
          function: () {
            Get.back();
          },
        );
        return;
      }
      generalAlert(
        title: "Confirm",
        message:
            "Are you sure you want to sell on $paymentType to ${salesController.currentCustomer.value?.name}?",
        function: () {
          if (customersController.customer.value?.creditLimit != null &&
              customersController.customer.value?.creditLimit != 0 &&
              customersController.customer.value!.creditLimit! <
                  salesController.receipt.value!.totalWithDiscount!) {
            customersController.currentCustomer.value = null;
            salesController.currentCustomer.value = null;
            generalAlert(
              title: "Error!",
              message: "Customer has reached credit limit to sell on credit",
              function: () {
                Get.back();
              },
            );
            return;
          }
          salesController.saveSale(
            screen: page ?? "admin",
            status: status,
          );
        },
      );
    } else {
      if (paymentType == "Cash" ||
          paymentType == "Mpesa" ||
          paymentType == "Bank") {
        confirmPayment(Get.context!, status, paymentType: paymentType);
      } else {
        if (paymentType == "Split Payment") {
          confirmSplitPayment(status, paymentType: paymentType);
        } else {
          salesController.saveSale(
            screen: page ?? "admin",
            status: status,
          );
        }
      }
    }
  }
}
