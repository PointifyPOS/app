import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/paymentcontroller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/models/payment.dart';
import 'package:pointify/widgets/textbutton.dart';
import 'package:printing/printing.dart';

import '../../../controllers/homecontroller.dart';
import '../../../models/salemodel.dart';
import '../../../responsive/responsiveness.dart';
import '../../../utils/colors.dart';
import '../../../widgets/alert.dart';
import '../../../widgets/major_title.dart';
import '../../../widgets/normal_text.dart';
import '../../receipts/pdf/cash_receipt_pdf.dart';
import '../wallet_page.dart';

class CashReceipt extends StatelessWidget {
  final Payment? receipt;

  CashReceipt({Key? key, required this.receipt}) : super(key: key);
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
            if (isSmallScreen(context)) {
              Get.back();
            } else {
              Get.find<HomeController>().selectedWidget.value = WalletPage();
            }
          },
          icon: const Icon(Icons.clear),
        ),
        title: Text(
          "Receipt#${receipt!.recieptNumber}".toUpperCase(),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Get.to(() => Scaffold(
                      appBar: AppBar(
                        title: const Text("Cash Receipt"),
                      ),
                      body: PdfPreview(
                          build: (context) =>
                              cashReceiptPdf([receipt!], "CASH RECEIPT")),
                    ));
              },
              icon: const Icon(
                Icons.picture_as_pdf,
                color: AppColors.mainColor,
              )),
          IconButton(
              onPressed: () {
                generalAlert(
                    title: "Warning",
                    positiveText: "Yes",
                    negativeText: "Not now",
                    message: "Are you sure you want to delete receipt?",
                    function: () {
                      Get.back();
                      paymentController.deleteReceiptById(receipt!.sId!);
                    });
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ))
        ],
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (receipt!.customerId != null)
                Row(
                  children: [
                    Text(
                      "Customer: ${receipt!.customerId!.name!}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        normalText(
                            title: "Date:", color: Colors.black, size: 14.0),
                        const SizedBox(
                          width: 5,
                        ),
                        majorTitle(
                            title: DateFormat("yyyy/MM/dd hh:mm")
                                .format(DateTime.parse(receipt!.date!)),
                            color: Colors.grey,
                            size: 11.0)
                      ],
                    )
                  ],
                ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      normalText(
                          title: "Total", color: Colors.black, size: 14.0),
                      const SizedBox(
                        height: 10,
                      ),
                      majorTitle(
                          title: htmlPrice(receipt!.amount),
                          color: Colors.black,
                          size: 18.0)
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    child: const Text(
                      "CASH RECEIPT",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey,
              ),
              Expanded(
                child: Column(
                  children: [
                    Table(children: [
                      TableRow(children: [
                        Text(
                          receipt!.type!,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          htmlPrice(receipt!.amount!),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                htmlPrice(receipt!.amount),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ]),
                    const Divider(
                      color: Colors.black,
                    ),
                    Expanded(
                      flex: 3,
                      child: Table(children: [
                        TableRow(children: [
                          const Text(
                            "",
                            style: TextStyle(fontSize: 16),
                          ),
                          const Text(
                            "",
                            style: TextStyle(fontSize: 16),
                          ),
                          Column(
                            children: [
                              Text(
                                htmlPrice(receipt!.amount),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Divider(
                                thickness: 3,
                                color: Colors.black,
                              )
                            ],
                          ),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        normalText(
                            title: "Date", color: Colors.black, size: 14.0),
                        const SizedBox(
                          height: 10,
                        ),
                        if (receipt!.date != null)
                          majorTitle(
                              title: DateFormat("yyyy-MM-dd HH:mm").format(
                                  DateTime.parse(receipt!.date!).toLocal()),
                              color: Colors.black,
                              size: 18.0)
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        normalText(
                            title: "Served by",
                            color: Colors.black,
                            size: 14.0),
                        const SizedBox(
                          height: 10,
                        ),
                        majorTitle(
                            title: receipt!.attendantId!.username,
                            color: Colors.black,
                            size: 18.0)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: textBtn(
                    onPressed: () {
                      Get.to(() => Scaffold(
                            appBar: AppBar(
                              title: const Text("Cash Receipt"),
                            ),
                            body: PdfPreview(
                                build: (context) =>
                                    cashReceiptPdf([receipt!], "CASH RECEIPT")),
                          ));
                    },
                    hPadding: 20,
                    text: "Print",
                    radius: 10,
                    bgColor: AppColors.mainColor,
                    color: Colors.white),
              ),
            ],
          )),
    );
  }
}

onCredit(SaleModel salesModel) => salesModel.outstandingBalance! > 0;
