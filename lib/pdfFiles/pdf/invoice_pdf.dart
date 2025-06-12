import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/models/invoice.dart';

Future<Uint8List> invoiceReceipt(Invoice invoice, type) async {
  final pdf = Document();
  final imageLogo = MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());
  pdf.addPage(
    Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Image(imageLogo),
                  ),
                  Column(
                    children: [
                      Text(invoice.shopId!.name!,
                          style: const TextStyle(fontSize: 21)),
                      Text(invoice.shopId?.location ?? "",
                          style: const TextStyle(fontSize: 21))
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ],
              ),
              Center(
                  child: Text(type,
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(children: [
                  Text(
                      "Date ${DateFormat("yyy-MM-dd").format(DateTime.parse(invoice.createdAt!).toUtc())}")
                ]),
                Row(children: [
                  Text("No:"),
                  Text(invoice.purchaseNo!.toUpperCase(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ])
              ]),
              SizedBox(height: 20),
              if (invoice.supplierId != null)
                Row(children: [
                  Text("No:"),
                  Text(invoice.supplierId!.name!.toUpperCase(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ]),
              SizedBox(height: 20),
              Expanded(
                  child: TableHelper.fromTextArray(
                      border: TableBorder.all(width: 1), //table border
                      headers: [
                        "Qty",
                        "Description",
                        "Price",
                      ],
                      data: invoice.items!
                          .map((e) => [
                                e.quantity,
                                "${e.product!.name}",
                                htmlPrice(e.unitPrice),
                              ])
                          .toList())),
              SizedBox(height: 10),
              if (invoice.outstandingBalance! > 0)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                      width: 200,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Unpaid ${htmlPrice(invoice.outstandingBalance!)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Divider(
                                thickness: 1,
                                color: const PdfColor.fromInt(0xFF000000))
                          ])),
                ),
              if (invoice.outstandingBalance! > 0)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                      width: 200,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Total paid ${htmlPrice(invoice.totalAmount! - invoice.outstandingBalance!)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Divider(
                                thickness: 1,
                                color: const PdfColor.fromInt(0xFF000000))
                          ])),
                ),
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                    width: 200,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Totals ${htmlPrice(invoice.totalAmount!)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Divider(
                              thickness: 1,
                              color: const PdfColor.fromInt(0xFF000000))
                        ])),
              ),
              SizedBox(height: 10),
              Text("Served by : ${invoice.attendantId!.username ?? ""}"),
              Spacer(),
              Align(
                  alignment: Alignment.center,
                  child:
                      Text("Thank you!", style: const TextStyle(fontSize: 28)))
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}
