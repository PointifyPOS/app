import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/paymentcontroller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/models/saleitem.dart';
import 'package:printing/printing.dart';

import '../../../controllers/salescontroller.dart';
import '../../../controllers/shopcontroller.dart';
import '../../../models/product.dart';
import '../../../models/salemodel.dart';
import '../../../utils/colors.dart';
import '../../../utils/themer.dart';
import '../../../widgets/alert.dart';
import '../../../widgets/major_title.dart';
import '../../../widgets/normal_text.dart';
import '../../cash_flow/payment_history.dart';
import '../pdf/delivery_note_pdf.dart';

class SalesReceipt extends StatelessWidget {
  final SaleModel? salesModel;
  final String? type;
  final String? from;

  SalesReceipt({super.key, this.salesModel, this.type = "", this.from = ""}) {
    salesController.currentReceipt.value = salesModel;
  }

  final ShopController shopController = Get.find<ShopController>();
  final SalesController salesController = Get.find<SalesController>();
  final PaymentController paymentController = Get.find<PaymentController>();
  // final PrinterController printerController = Get.find<PrinterController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Receipt No. #${salesController.currentReceipt.value?.receiptNo ?? ""}",
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'Print') {
                salesController.reprintReceipt(
                  saleModel: salesController.currentReceipt.value!,
                );
              }
              if (value == 'Share') {
                salesController.sharePdf(salesModel!);
              }
              if (value == 'Delivery') {
                Get.to(() => Scaffold(
                      appBar: AppBar(
                        title: const Text("Print Delivery"),
                      ),
                      body: PdfPreview(
                        build: (context) => deliveryNotePdf(
                            salesController.currentReceipt.value!,
                            "Delivery Note"),
                      ),
                    ));
              }
              if (value == 'Delete') {
                if (verifyPermission(category: "sales", permission: "delete") &&
                    salesController.currentReceipt.value!.status != "order") {
                  saleReceiptActions(
                      saleModel: salesController.currentReceipt.value!,
                      delete: true,
                      from: from!);
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                if (verifyPermission(category: "sales", permission: "delete") &&
                    salesController.currentReceipt.value!.status != "order")
                  const PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete Receipt'),
                  ),
                const PopupMenuItem<String>(
                  value: 'Share',
                  child: Text('Share receipt'),
                ),
                const PopupMenuItem<String>(
                  value: 'Print',
                  child: Text('Print receipt'),
                ),
                const PopupMenuItem<String>(
                  value: 'Delivery',
                  child: Text('Print Delivery Note'),
                ),
              ];
            },
            icon: Icon(Icons.more_vert), // This can be any icon you prefer
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () {
            final receipt = salesController.currentReceipt.value!;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top status card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _chechPaymentColor(receipt, type!)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      chechPayment(receipt, type!),
                                      style: TextStyle(
                                        color:
                                            _chechPaymentColor(receipt, type!),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (verifyPermission(
                                      category: "sales", permission: "return"))
                                    InkWell(
                                      onTap: () {
                                        saleReceiptActions(
                                          saleModel: receipt,
                                          from: from ?? "",
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: const Text(
                                          "Refund",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _summaryBox(
                                      title: "Total",
                                      value:
                                          htmlPrice(receipt.totalWithDiscount),
                                    ),
                                  ),
                                  if (receipt.outstandingBalance! > 0) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _summaryBox(
                                        title: "Paid",
                                        value: htmlPrice(
                                          receipt.totalWithDiscount! -
                                              receipt.outstandingBalance!,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (onCredit(receipt) &&
                                      type != "returns") ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _summaryBox(
                                        title: "Balance",
                                        value: htmlPrice(
                                          receipt.outstandingBalance!.abs(),
                                        ),
                                        valueColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (receipt.createdAt != null)
                                _receiptInfoRow(
                                  title: "Date",
                                  value: DateFormat("yyyy-MM-dd hh:mm").format(
                                    DateTime.parse(receipt.createdAt!).toUtc(),
                                  ),
                                ),
                              if (salesModel?.status != "order")
                                _receiptInfoRow(
                                  title: "Served by",
                                  value: salesModel?.attendant?.username ?? "",
                                ),
                              if (receipt.customerId != null)
                                _receiptInfoRow(
                                  title: "Customer",
                                  value: receipt.customerId!.name ?? "",
                                ),
                              if (receipt.outstandingBalance! > 0 &&
                                  receipt.dueDate != null)
                                _receiptInfoRow(
                                  title: "Due date",
                                  value: DateFormat("yyyy/MM/dd HH:mm").format(
                                    DateTime.parse(receipt.dueDate!).toLocal(),
                                  ),
                                ),
                              if (receipt.salesnote != null &&
                                  receipt.salesnote!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Note: ${receipt.salesnote}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              if (receipt.paymentTag == 'credit' ||
                                  (onCredit(receipt) &&
                                      receipt.items!.fold(
                                            0.0,
                                            (previousValue, element) =>
                                                previousValue +
                                                element.quantity!,
                                          ) >
                                          0 &&
                                      type != "returns")) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (receipt.paymentTag == 'credit')
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            paymentController
                                                .getSalesPaymentBySaleId(
                                              receipt.sId!,
                                            );
                                            Get.to(() => PaymentHistory());
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text("View payments"),
                                        ),
                                      ),
                                    if (receipt.paymentTag == 'credit' &&
                                        onCredit(receipt) &&
                                        receipt.items!.fold(
                                              0.0,
                                              (previousValue, element) =>
                                                  previousValue +
                                                  element.quantity!,
                                            ) >
                                            0 &&
                                        type != "returns")
                                      const SizedBox(width: 10),
                                    if (onCredit(receipt) &&
                                        receipt.items!.fold(
                                              0.0,
                                              (previousValue, element) =>
                                                  previousValue +
                                                  element.quantity!,
                                            ) >
                                            0 &&
                                        type != "returns")
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showAmountDialog(receipt);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.mainColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text("Pay Now"),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          "Items",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: receipt.items!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext c, int i) {
                            SaleItem receiptitem = receipt.items![i];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        if (verifyPermission(
                                          category: "sales",
                                          permission: "return",
                                        )) {
                                          saleReceiptActions(
                                            saleItem: receiptitem,
                                            from: from!,
                                          );
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receiptitem
                                                .product!.name!.capitalize!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  receiptitem.quantity == 0
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${receiptitem.quantity!} @ ${htmlPrice(receiptitem.unitPrice! + receiptitem.lineDiscount!)}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              decoration:
                                                  receiptitem.quantity == 0
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        htmlPrice(
                                          (receiptitem.unitPrice! *
                                                  receiptitem.quantity!) +
                                              receiptitem.lineDiscount!,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          decoration: receiptitem.quantity == 0
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      if (receiptitem.quantity == 0)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Icon(
                                            Icons.file_download,
                                            color: Colors.red,
                                            size: 15,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (receipt.status != "order" &&
                                      verifyPermission(
                                        category: "sales",
                                        permission: "return",
                                      )) ...[
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () {
                                        saleReceiptActions(
                                          saleItem: receiptitem,
                                          from: from ?? "",
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.undo,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Obx(
          () {
            final receipt = salesController.currentReceipt.value!;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (receipt.totaltax! > 0 ||
                      receipt.paymentTag == 'split') ...[
                    Row(
                      children: [
                        if (receipt.totaltax! > 0)
                          Expanded(
                            child: _bottomMiniTotal(
                              title: "VAT",
                              value: htmlPrice(receipt.totaltax!),
                            ),
                          ),
                        if (receipt.paymentTag == 'split' &&
                            receipt.amountPaid! > 0)
                          Expanded(
                            child: _bottomMiniTotal(
                              title: "Cash",
                              value: htmlPrice(receipt.amountPaid!),
                            ),
                          ),
                        if (receipt.paymentTag == 'split' &&
                            receipt.mpesatotal! > 0)
                          Expanded(
                            child: _bottomMiniTotal(
                              title: "Mpesa",
                              value: htmlPrice(receipt.mpesatotal!),
                            ),
                          ),
                        if (receipt.paymentTag == 'split' &&
                            receipt.banktotal! > 0)
                          Expanded(
                            child: _bottomMiniTotal(
                              title: "Bank",
                              value: htmlPrice(receipt.banktotal!),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _bottomMiniTotal(
                          title: "Sub Total",
                          value: htmlPrice(
                            (receipt.totalAmount! - receipt.totaltax!)
                                .toStringAsFixed(2),
                          ),
                        ),
                      ),
                      if (receipt.totalDiscount != null &&
                          receipt.totalDiscount! > 0)
                        Expanded(
                          child: _bottomMiniTotal(
                            title: "Discount",
                            value: htmlPrice(receipt.totalDiscount!),
                          ),
                        ),
                      Expanded(
                        child: _bottomMiniTotal(
                          title: "Total",
                          value: htmlPrice(receipt.totalWithDiscount!),
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _summaryBox({
  required String title,
  required String value,
  Color? valueColor,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget _receiptInfoRow({
  required String title,
  required String value,
}) {
  if (value.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _bottomMiniTotal({
  required String title,
  required String value,
  bool bold = false,
}) {
  return Column(
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          color: Colors.black,
        ),
      ),
    ],
  );
}

String chechPayment(SaleModel salesModel, String? type) {
  if (salesModel.totalWithDiscount == 0 || type == "returns") {
    return type == "returns" ? "RETURNED ITEMS" : "RETURNED";
  }
  if (salesModel.status == 'order') return "PENDING";
  if (salesModel.outstandingBalance == 0) return "CASH SALE";
  if (onCredit(salesModel) == true) return "NOT PAID";
  return "";
}

onCredit(SaleModel salesModel) => salesModel.outstandingBalance! > 0;

Color _chechPaymentColor(SaleModel salesModel, String? type) {
  if (salesModel.totalWithDiscount! == 0 || type == "returns") {
    return Colors.red;
  }
  if (salesModel.status == 'order') return Colors.amber;
  if (salesModel.outstandingBalance == 0) return Colors.green;
  if (onCredit(salesModel) == true) return Colors.red;
  return Colors.black;
}

void saleReceiptActions(
    {SaleItem? saleItem,
    SaleModel? saleModel,
    bool delete = false,
    String from = ""}) {
  SalesController salesController = Get.find<SalesController>();
  if (saleModel != null) {
    generalAlert(
        title: "Warning",
        positiveText: "Yes",
        negativeText: "Not now",
        message:
            "Are you sure you want to ${delete ? "delete" : "return"} ${salesController.currentReceipt.value?.items!.length} items?",
        function: () {
          if (delete == true) {
            salesController.voidReceipt(salesController.currentReceipt.value!);
            return;
          }
          var items = salesController.currentReceipt.value?.items!
              .map((e) => {"product": e.product?.sId, "quantity": e.quantity})
              .toList();

          if (from == "sales") {
            Get.back();
          }
          salesController.returnSale(
              saledId: salesController.currentReceipt.value!.sId,
              returnItems: items,
              from: from,
              deleteReceipt: delete);
        });
  } else {
    if (saleItem != null && saleItem.quantity! > 0) {
      returnReceiptItem(receiptItem: saleItem);
    }
  }
}

returnReceiptItem({required SaleItem receiptItem, Product? product}) {
  SalesController salesController = Get.find<SalesController>();
  TextEditingController textEditingController = TextEditingController();
  textEditingController.text = receiptItem.quantity.toString();
  return showDialog(
      context: Get.context!,
      builder: (_) {
        return AlertDialog(
          title: const Text("Return Product?"),
          content: Container(
            decoration: ThemeHelper().inputBoxDecorationShaddow(),
            child: TextFormField(
              controller: textEditingController,
              decoration: ThemeHelper()
                  .textInputDecoration('Quantity', 'Enter quantity'),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  "Cancel".toUpperCase(),
                  style: TextStyle(color: AppColors.mainColor),
                )),
            TextButton(
                onPressed: () {
                  if (receiptItem.quantity! <
                      double.parse(textEditingController.text.isEmpty
                          ? "0"
                          : textEditingController.text)) {
                    generalAlert(
                        title: "Error",
                        message:
                            "You cannot return more than ${receiptItem.quantity}");
                  } else if (double.parse(textEditingController.text) <= 0) {
                    generalAlert(
                        title: "Error",
                        message: "You must atleast return 1 item");
                  } else {
                    Get.back();
                    salesController
                        .returnSale(saledId: receiptItem.sale, returnItems: [
                      {
                        "product": receiptItem.product?.sId,
                        'name': receiptItem.product?.name,
                        "quantity": double.parse(textEditingController.text)
                      }
                    ]);
                  }
                },
                child: Text(
                  "Okay".toUpperCase(),
                  style: TextStyle(color: AppColors.mainColor),
                ))
          ],
        );
      });
}

showAmountDialog(SaleModel salesBody) {
  SalesController salesController = Get.find<SalesController>();
  showDialog(
      context: Get.context!,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Pay invoice",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            child: Form(
                child: Obx(() => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Payment via",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5)),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                  context: Get.context!,
                                  builder: (context) {
                                    return SimpleDialog(
                                      children: List.generate(
                                          salesController
                                              .receiptpaymentMethods.length,
                                          (index) => SimpleDialogOption(
                                                onPressed: () {
                                                  salesController.paynowMethod
                                                      .value = salesController
                                                          .receiptpaymentMethods[
                                                      index];
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  child: Text(
                                                    "${salesController.receiptpaymentMethods[index]}",
                                                    style: const TextStyle(
                                                        fontSize: 18),
                                                  ),
                                                ),
                                              )),
                                    );
                                  });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(
                                  () =>
                                      Text(salesController.paynowMethod.value),
                                ),
                                const Icon(Icons.arrow_drop_down)
                              ],
                            ),
                          ),
                        ),
                        if (salesController.paynowMethod.value == "Mpesa")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Mpesa Code (Last 5 Digits)",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              TextFormField(
                                controller: salesController.mpesaCode,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    hintText: "eg DV409",
                                    hintStyle: const TextStyle(fontSize: 10),
                                    fillColor: Colors.white,
                                    filled: true,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                              ),
                            ],
                          ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          "Enter Amount",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: salesController.amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: "eg ${salesBody.totalWithDiscount}",
                              hintStyle: const TextStyle(fontSize: 10),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ))),
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
                Get.back();
                var amountPaid = int.parse(
                    salesController.amountController.text.isEmpty
                        ? "0"
                        : salesController.amountController.text);
                if (salesBody.outstandingBalance! < amountPaid) {
                  generalAlert(
                      title: "Error",
                      message:
                          "You cannot pay more than ${htmlPrice(salesBody.outstandingBalance!.abs())}");
                } else {
                  if (salesController.paynowMethod.value == "Wallet") {
                    var walletBalance = (salesBody.customerId!.wallet ?? 0);
                    if (walletBalance == 0) {
                      generalAlert(
                          title: "Error",
                          message: "Wallet balance is ${htmlPrice(0)}");
                    } else {
                      if (walletBalance < amountPaid) {
                        generalAlert(
                            title: "Warning",
                            message: walletBalance < 0
                                ? "Wallet balance is not sufficient to pay ${htmlPrice(amountPaid)}"
                                : "Wallet balance can only pay ${htmlPrice(walletBalance)} continue?",
                            function: () {
                              salesController.payCredit(
                                  salesBody: salesBody, amount: amountPaid);
                            });
                      } else {
                        salesController.payCredit(
                            salesBody: salesBody, amount: amountPaid);
                      }
                    }
                  } else {
                    salesController.payCredit(
                        salesBody: salesBody, amount: amountPaid);
                  }
                }
              },
              child: Text(
                "Pay".toUpperCase(),
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
