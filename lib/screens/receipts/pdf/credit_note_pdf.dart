import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/shop.dart';

import '../../../models/salemodel.dart';

Future<Uint8List> creditNotePdf(SaleModel sale) async {
  final Shop shop = userController.currentUser.value!.primaryShop!;

  final pdf = Document();

  pdf.addPage(
    Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Center(
                child: Text(
                  shop.name ?? "",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 10),

              Center(
                child: Text(
                  "CREDIT NOTE",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 25),

              // CREDIT NOTE DETAILS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Credit Note No: CN-${sale.receiptNo ?? ""}",
                      ),
                      Text(
                        "Original Receipt: ${sale.receiptNo ?? ""}",
                      ),
                      Text(
                        "Date: ${DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}",
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Customer:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sale.customerId?.name ?? "Walk-in Customer",
                      ),
                      if (sale.customerId?.phoneNumber != null)
                        Text(
                          sale.customerId!.phoneNumber!,
                        ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 25),

              // ITEMS
              TableHelper.fromTextArray(
                border: TableBorder.all(
                  width: 1,
                ),
                headers: [
                  "Product",
                  "Qty",
                  "Unit Price",
                  "Amount",
                ],
                data: sale.items!.map((item) {
                  final quantity = item.quantity ?? 0;

                  final unitPrice = item.unitPrice ?? 0;

                  final amount = quantity * unitPrice;

                  return [
                    item.product?.name ?? "",
                    quantity.toString(),
                    htmlPrice(unitPrice),
                    htmlPrice(amount),
                  ];
                }).toList(),
              ),

              SizedBox(height: 20),

              // TOTAL
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Credit Amount:"),
                          Text(
                            htmlPrice(
                              sale.totalWithDiscount ?? 0,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TOTAL CREDIT:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            htmlPrice(
                              sale.totalWithDiscount ?? 0,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              Text(
                "This credit note relates to the original "
                "receipt/invoice shown above.",
              ),

              Spacer(),

              Text(
                "Issued by: "
                "${userController.currentUser.value!.username ?? ""}",
              ),

              SizedBox(height: 5),

              Text(
                "Printed on: "
                "${DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now().toLocal())}",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: 10),

              Center(
                child: Text(
                  "From: ${shop.name ?? ""} "
                  "${shop.location ?? ""}",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
