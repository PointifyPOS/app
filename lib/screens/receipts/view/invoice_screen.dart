import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/paymentcontroller.dart';
import 'package:pointify/controllers/purchase_controller.dart';
import 'package:pointify/controllers/suppliercontroller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:printing/printing.dart';

import '../../../../widgets/major_title.dart';
import '../../../../widgets/normal_text.dart';
import '../../../controllers/shopcontroller.dart';
import '../../../models/invoice.dart';
import '../../../pdfFiles/pdf/invoice_pdf.dart';
import '../../../utils/colors.dart';
import '../../../utils/themer.dart';
import '../../../widgets/alert.dart';
import '../../../widgets/textbutton.dart';
import '../../cash_flow/payment_history.dart';

class InvoiceScreen extends StatelessWidget {
  final Invoice? invoice;
  final String? type;
  final String? from;

  InvoiceScreen({Key? key, this.invoice, this.type = " ", this.from = ""})
    : super(key: key) {
    purchaseController.currentInvoice.value = invoice;
  }

  final ShopController shopController = Get.find<ShopController>();
  final PurchaseController purchaseController = Get.find<PurchaseController>();
  final PaymentController paymentController = Get.find<PaymentController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          color: Colors.black,
          onPressed: () {
            Get.back();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _printReceipt();
            },
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.mainColor),
          ),
          if (verifyPermission(
            category: "stocks",
            permission: "delete_purchase_invoice",
          ))
            IconButton(
              onPressed: () {
                _dialog(
                  invoice: purchaseController.currentInvoice.value!,
                  delete: true,
                );
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
        ],
        title: Text(
          "Invoice #${purchaseController.currentInvoice.value!.purchaseNo}"
              .toUpperCase(),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .supplierId
                          ?.name !=
                      null)
                    Text(
                      "Supplier: ${purchaseController.currentInvoice.value!.supplierId!.name}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .supplierId
                          ?.name !=
                      null)
                    const Spacer(),
                  Row(
                    children: [
                      normalText(
                        title: "Date:",
                        color: Colors.black,
                        size: 14.0,
                      ),
                      const SizedBox(width: 5),
                      if (purchaseController.currentInvoice.value!.createdAt !=
                          null)
                        majorTitle(
                          title: DateFormat("yyyy/MM/dd HH:mm").format(
                            DateTime.parse(
                              purchaseController
                                  .currentInvoice
                                  .value!
                                  .createdAt!,
                            ).toLocal(),
                          ),
                          color: Colors.grey,
                          size: 11.0,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      normalText(
                        title: "Total",
                        color: Colors.black,
                        size: 14.0,
                      ),
                      const SizedBox(height: 10),
                      majorTitle(
                        title: htmlPrice(
                          purchaseController.currentInvoice.value?.items != null
                              ? purchaseController.currentInvoice.value?.items!
                                      .fold(
                                        0.0,
                                        (previousValue, element) =>
                                            previousValue +
                                            (element.quantity! *
                                                element.unitPrice!),
                                      ) ??
                                  0
                              : 0,
                        ),
                        color: Colors.black,
                        size: 18.0,
                      ),
                    ],
                  ),
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .outstandingBalance! >
                      0)
                    const SizedBox(width: 30),
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .outstandingBalance! >
                      0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        normalText(
                          title: "Total Paid",
                          color: Colors.black,
                          size: 14.0,
                        ),
                        const SizedBox(height: 10),
                        majorTitle(
                          title: htmlPrice(
                            purchaseController
                                    .currentInvoice
                                    .value!
                                    .totalAmount! -
                                purchaseController
                                    .currentInvoice
                                    .value!
                                    .outstandingBalance!
                                    .abs(),
                          ),
                          color: Colors.black,
                          size: 18.0,
                        ),
                      ],
                    ),
                  const SizedBox(width: 70),
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .outstandingBalance! >
                      0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          normalText(
                            title: "Credit Balance",
                            color: Colors.black,
                            size: 14.0,
                          ),
                          const SizedBox(height: 10),
                          majorTitle(
                            title: htmlPrice(
                              purchaseController
                                  .currentInvoice
                                  .value
                                  ?.outstandingBalance!,
                            ),
                            color: Colors.black,
                            size: 18.0,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 30),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _chechPaymentColor(
                        purchaseController.currentInvoice.value!,
                        type ?? "",
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _chechPayment(
                        purchaseController.currentInvoice.value!,
                        type ?? "",
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (purchaseController
                          .currentInvoice
                          .value!
                          .outstandingBalance! >
                      0)
                    InkWell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _chechPaymentColor(
                              purchaseController.currentInvoice.value!,
                              type ?? "",
                            ),
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text("Pay Now"),
                      ),
                      onTap: () {
                        showAmountDialog(
                          purchaseController.currentInvoice.value!,
                        );
                      },
                    ),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                      purchaseController.currentInvoice.value!.items?.length,
                  itemBuilder: (BuildContext c, int i) {
                    InvoiceItem sale =
                        purchaseController.currentInvoice.value!.items![i];
                    return Table(
                      children: [
                        TableRow(
                          children: [
                            Text(
                              sale.product!.name?.capitalize ?? "",
                              style: TextStyle(
                                fontSize: 16,
                                decoration:
                                    sale.quantity == 0
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                            Text(
                              "${sale.quantity} @${htmlPrice(sale.unitPrice!)}",
                              style: TextStyle(
                                fontSize: 12,
                                decoration:
                                    sale.quantity == 0
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (type != "returns") {
                                  _dialog(invoiceItem: sale);
                                }
                              },
                              child: Row(
                                children: [
                                  Text(
                                    htmlPrice(sale.unitPrice! * sale.quantity!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          sale.quantity == 0
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (verifyPermission(
                                        category: "stocks",
                                        permission: "return",
                                      ) &&
                                      type != "returns")
                                    InkWell(
                                      onTap: () {
                                        _dialog(invoiceItem: sale);
                                      },
                                      child: const Icon(
                                        Icons.undo,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    normalText(
                      title: "Invoiced by: ",
                      color: Colors.black,
                      size: 14.0,
                    ),
                    const SizedBox(height: 10),
                    majorTitle(
                      title:
                          purchaseController
                              .currentInvoice
                              .value
                              ?.attendantId
                              ?.username,
                      color: Colors.black,
                      size: 18.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (purchaseController.currentInvoice.value?.invoiceType !=
                    'return' &&
                verifyPermission(category: "stocks", permission: "return"))
              Center(
                child: textBtn(
                  hPadding: 20,
                  text: "Return Invoice",
                  radius: 10,
                  onPressed: () {
                    _dialog(invoice: purchaseController.currentInvoice.value!);
                  },
                  bgColor: Colors.red,
                  color: Colors.white,
                ),
              ),
            Center(
              child: textBtn(
                hPadding: 20,
                text: "Print",
                onPressed: () {
                  _printReceipt();
                },
                radius: 10,
                bgColor: AppColors.mainColor,
                color: Colors.white,
              ),
            ),
            if (purchaseController.currentInvoice.value?.paymentType ==
                "credit")
              Center(
                child: textBtn(
                  hPadding: 20,
                  text: "Payments",
                  onPressed: () {
                    paymentController.getSalesPaymentByPurchaseId(
                      purchaseController.currentInvoice.value!.sId!,
                    );
                    Get.to(() => PaymentHistory());
                  },
                  radius: 10,
                  bgColor: Colors.red,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _printReceipt() {
    Get.to(
      () => Scaffold(
        appBar: AppBar(
          title: Text("${type ?? "".capitalizeFirst} Invoice".toUpperCase()),
        ),
        body: PdfPreview(
          build:
              (context) => invoiceReceipt(
                purchaseController.currentInvoice.value!,
                "${type ?? "".capitalizeFirst} Invoice".toUpperCase(),
              ),
        ),
      ),
    );
  }
}

String _chechPayment(Invoice salesModel, String? type) {
  if (salesModel.totalAmount == 0 || type == "returns") {
    return type == "returns" ? "RETURNED ITEMS" : "RETURNED";
  }
  if (type == "returns") return "RETURNED";
  if (salesModel.outstandingBalance == 0) return "CASH";
  if (salesModel.outstandingBalance! > 0) return "ON CREDIT";
  return "";
}

Color _chechPaymentColor(Invoice invoice, String? type) {
  if (invoice.totalAmount == 0 || type == "returns") return Colors.red;
  if (invoice.outstandingBalance == 0) return Colors.green;
  if (invoice.outstandingBalance! > 0) return Colors.red;
  return Colors.black;
}

void _dialog({
  Invoice? invoice,
  InvoiceItem? invoiceItem,
  bool delete = false,
}) {
  TextEditingController textEditingController = TextEditingController();
  if (delete == true || invoice != null) {
    generalAlert(
      function: () {
        Get.find<PurchaseController>().returnInvoiceItem(
          invoice!.items!
              .map((e) => InvoiceItem(quantity: e.quantity, product: e.product))
              .toList(),
          deleteReceipt: delete,
          invoiceType: invoice.invoiceType ?? '',
        );
        Get.back();
      },
      title: "Delete invoice",
      positiveText: "Yes",
      negativeText: "No",
      message: "Are you sure you want to delete this invoice?",
    );

    return;
  }
  if (invoiceItem != null) {
    textEditingController.text = invoiceItem.quantity.toString();
    showDialog(
      context: Get.context!,
      builder: (_) {
        return AlertDialog(
          title: const Text("Return Product?"),
          content: Container(
            decoration: ThemeHelper().inputBoxDecorationShaddow(),
            child: TextFormField(
              controller: textEditingController,
              decoration: ThemeHelper().textInputDecorationDesktop(
                'Quantity',
                'Enter quantity',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                "Cancel".toUpperCase(),
                style: const TextStyle(color: AppColors.mainColor),
              ),
            ),
            TextButton(
              onPressed: () {
                if (textEditingController.text.isEmpty) {
                  generalAlert(
                    title: "Error",
                    message: "Quantity cannot be empty",
                  );
                  Get.back();
                  return;
                }
                if (invoiceItem.quantity! <
                    double.parse(textEditingController.text)) {
                  generalAlert(
                    title: "Error",
                    message:
                        "You cannot return more than ${invoiceItem.quantity}",
                  );
                } else if (double.parse(textEditingController.text) <= 0) {
                  generalAlert(
                    title: "Error",
                    message: "You must atleast return 1 item",
                  );
                } else {
                  Get.back();
                  Get.find<PurchaseController>().returnInvoiceItem([
                    InvoiceItem(
                      quantity: double.parse(textEditingController.text),
                      product: invoiceItem.product,
                    ),
                  ], deleteReceipt: delete);
                }
              },
              child: Text(
                "Okay".toUpperCase(),
                style: const TextStyle(color: AppColors.mainColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

showAmountDialog(Invoice invoice) {
  SupplierController supplierController = Get.find<SupplierController>();
  showDialog(
    context: Get.context!,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          "Enter Amount to pay",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Form(
          child: TextFormField(
            controller: supplierController.amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "eg ${invoice.totalAmount}",
              hintStyle: const TextStyle(color: Colors.black),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              "Cancel".toUpperCase(),
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<PurchaseController>().paySupplierCredit(
                invoice: invoice,
                amount: supplierController.amountController.text,
              );
            },
            child: Text(
              "Pay".toUpperCase(),
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
