import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/main.dart';

class PrinterController extends GetxController {
  Future<List<int>> printSalesReceipt({
    String storeName = "",
    String phone = "",
    String customer = "",
    String address = "",
    String currency = "KES",
    String email = "",
    String paybill = "",
    String date = "",
    String paybillAccount = "",
    String paymentType = "",
    String receiptUrl = "",
    required List<Map<String, dynamic>> items,
  }) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.reset();
    bytes += generator.text(
      storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    if (phone.isNotEmpty) {
      bytes += generator.text(
        "Phone: $phone",
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (email.isNotEmpty) {
      bytes += generator.text(
        "Email: $email",
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (address.isNotEmpty) {
      bytes += generator.text(
        "Location: $address",
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (paybill.isNotEmpty && paybillAccount.isNotEmpty) {
      bytes += generator.text(
        'Paybill: $paybill',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (paybill.isNotEmpty && paybillAccount.isEmpty) {
      bytes += generator.text(
        'Till No.: $paybill',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (paybillAccount.isNotEmpty) {
      bytes += generator.text(
        'Account: $paybillAccount',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (customer.isNotEmpty) {
      bytes += generator.text(
        'Customer: $customer',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.text(
      'Date: ${DateFormat("MMM dd yyyy hh:mm a").format(DateTime.parse(date).toUtc())}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('-' * 32);

    bytes += generator.row([
      PosColumn(text: "Item", width: 6),
      PosColumn(text: "Qty", width: 2),
      PosColumn(text: "Cost", width: 2),
      PosColumn(text: "Total", width: 2),
    ]);
    bytes += generator.hr();

    double subtotal = 0;

    for (var item in items) {
      final name = item['name'] ?? '';
      final qty = item['qty'] ?? 0;
      final price = item['price'] ?? 0.0;
      final total = price * qty;
      subtotal += total;

      bytes += generator.row([
        PosColumn(text: name.length > 18 ? name.substring(0, 18) : name, width: 6),
        PosColumn(text: "$qty", width: 2, styles: PosStyles(align: PosAlign.center)),
        PosColumn(text: price.toStringAsFixed(0), width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: total.toStringAsFixed(0), width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.text('-' * 32);

    double vat = 0;
    double totalDue = subtotal + vat;

    bytes += generator.text(
      'Sub Total:     $currency${subtotal.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right),
    );
    bytes += generator.text(
      'VAT (${userController.currentUser.value?.primaryShop?.tax}%):     $currency${vat.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right),
    );
    bytes += generator.text(
      'TOTAL: $currency${totalDue.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.text('Payment: $paymentType');

    bytes += generator.qrcode(
      receiptUrl,
      size: QRSize.size5,           // bigger
      cor: QRCorrection.H,             // high error correction
    );
    bytes += generator.feed(1);
    bytes += generator.text(" ");

    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'System by Pointify,\ncontacts: 0791 334 234',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }
}
