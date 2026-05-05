import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pointify/models/salemodel.dart';

Future<void> downloadSalesItemsPdf(
  List<SaleModel> sales, {
  String? statusFilter,
  DateTime? startDateFilter,
  DateTime? endDateFilter,
}) async {
  final regularFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
  );

  final boldFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
  );

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    ),
  );

  final shop = sales.isNotEmpty ? sales.first.shopId : null;
  final customer = sales.isNotEmpty ? sales.first.customerId : null;

  final bool hasStatusFilter =
      statusFilter != null && statusFilter.trim().isNotEmpty;

  final bool hasDateFilter = startDateFilter != null || endDateFilter != null;

  final currency = shop?.currency ?? "KES";

  String money(num value) {
    return "$currency ${NumberFormat("#,##0.00").format(value)}";
  }

  final totalSales = sales.fold<num>(
    0,
    (sum, sale) => sum + (sale.totalWithDiscount ?? sale.totalAmount ?? 0),
  );

  final totalItems = sales.fold<int>(
    0,
    (sum, sale) =>
        sum +
        (sale.items ?? []).fold<int>(
          0,
          (itemSum, item) => itemSum + ((item.quantity ?? 0).toInt()),
        ),
  );

  num paymentTotal(String type) {
    return sales
        .where((sale) => (sale.paymentType ?? "").toLowerCase() == type)
        .fold<num>(
          0,
          (sum, sale) =>
              sum + (sale.totalWithDiscount ?? sale.totalAmount ?? 0),
        );
  }

  final cashTotal = paymentTotal("cash");
  final mpesaTotal = paymentTotal("mpesa");
  final walletTotal = paymentTotal("wallet");
  final bankTotal = sales.fold<num>(
    0,
    (sum, sale) => sum + (sale.banktotal ?? 0),
  );

  final headers = <String>[
    if (!hasDateFilter) "Date",
    "Receipt",
    "Item",
    "Qty",
    "Unit",
    "Total",
    if (!hasStatusFilter) "Payment",
    "Attendant",
  ];

  final rows = sales.expand((sale) {
    return (sale.items ?? []).map((item) {
      final qty = item.quantity ?? 0;
      final unitPrice = item.unitPrice ?? 0;
      final lineTotal = qty * unitPrice;

      return [
        if (!hasDateFilter)
          sale.createdAt == null
              ? ""
              : DateFormat("dd-MM-yyyy")
                  .format(DateTime.parse(sale.createdAt!)),
        sale.receiptNo ?? "",
        item.product?.name ?? "",
        qty.toString(),
        money(unitPrice),
        money(lineTotal),
        if (!hasStatusFilter) sale.paymentType ?? "",
        sale.attendant?.username ?? "",
      ];
    });
  }).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(14),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              shop?.name ?? "Pointify",
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ),
      build: (context) {
        return [
          _header(
            shopName: shop?.name ?? "Sales Report",
            address: shop?.addressReceipt ?? shop?.location ?? "",
            contact: shop?.contact ?? "",
            paybillTill: shop?.paybillTill ?? "",
            paybillAccount: shop?.paybillAccount ?? "",
            title: "Customer Sales Items Report",
          ),
          pw.SizedBox(height: 6),
          _customerAndFilterBox(
            customerName: customer?.name ?? "Walk-in Customer",
            customerNo: customer?.customerNo?.toString() ?? "",
            generatedAt:
                DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now()),
            status: hasStatusFilter ? statusFilter : null,
            startDate: startDateFilter,
            endDate: endDateFilter,
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _summaryBox("Sales", sales.length.toString()),
              pw.SizedBox(width: 5),
              _summaryBox("Items", totalItems.toString()),
              pw.SizedBox(width: 5),
              _summaryBox("Total", money(totalSales)),
            ],
          ),
          pw.SizedBox(height: 6),
          _paymentSummary(
            cash: money(cashTotal),
            mpesa: money(mpesaTotal),
            wallet: money(walletTotal),
            bank: money(bankTotal),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            "Sold Items",
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          if (rows.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                "No sales items found.",
                style: const pw.TextStyle(fontSize: 8),
              ),
            )
          else
            pw.Table.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.3,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.deepPurple,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              cellStyle: pw.TextStyle(fontSize: 6.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                "Grand Total: ${money(totalSales)}",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ];
      },
    ),
  );

  final dir = await getTemporaryDirectory();

  final file = File(
    "${dir.path}/customer_sales_items_${DateTime.now().millisecondsSinceEpoch}.pdf",
  );

  await file.writeAsBytes(await pdf.save(), flush: true);

  await OpenFile.open(file.path);
}

pw.Widget _header({
  required String shopName,
  required String address,
  required String contact,
  required String paybillTill,
  required String paybillAccount,
  required String title,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(
      color: PdfColors.deepPurple,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (address.isNotEmpty)
                pw.Text(
                  address,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7.5,
                  ),
                ),
              if (contact.isNotEmpty)
                pw.Text(
                  "Contact: $contact",
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7.5,
                  ),
                ),
              if (paybillTill.isNotEmpty || paybillAccount.isNotEmpty)
                pw.Text(
                  "Payment: Till/Paybill $paybillTill  Account $paybillAccount",
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7.5,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _customerAndFilterBox({
  required String customerName,
  required String customerNo,
  required String generatedAt,
  String? status,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final hasStatus = status != null && status.trim().isNotEmpty;
  final hasDate = startDate != null || endDate != null;

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(5),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Customer",
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                customerName,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (customerNo.isNotEmpty)
                pw.Text(
                  "No: $customerNo",
                  style: const pw.TextStyle(fontSize: 7),
                ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Filters",
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (!hasStatus && !hasDate)
                pw.Text(
                  "None",
                  style: const pw.TextStyle(fontSize: 7),
                ),
              if (hasStatus)
                pw.Text(
                  "Status: ${_capitalize(status!)}",
                  style: const pw.TextStyle(fontSize: 7),
                ),
              if (hasDate)
                pw.Text(
                  "Date: ${startDate == null ? "Start" : DateFormat("dd MMM yyyy").format(startDate)} - ${endDate == null ? "Today" : DateFormat("dd MMM yyyy").format(endDate)}",
                  style: const pw.TextStyle(fontSize: 7),
                ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              "Generated",
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              generatedAt,
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _summaryBox(String title, String value) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _paymentSummary({
  required String cash,
  required String mpesa,
  required String wallet,
  required String bank,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(5),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _paymentItem("Cash", cash),
        _paymentItem("M-Pesa", mpesa),
        _paymentItem("Wallet", wallet),
        _paymentItem("Bank", bank),
      ],
    ),
  );
}

pw.Widget _paymentItem(String title, String value) {
  return pw.Container(
    width: 90,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 6.5,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return "${value[0].toUpperCase()}${value.substring(1)}";
}
