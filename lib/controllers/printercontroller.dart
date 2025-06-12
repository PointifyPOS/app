import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:get/get.dart';

class PrinterController extends GetxController {
  Future<List<int>> printSalesReceipt({
    String storeName = "",
    String phone = "",
    String customer = "",
    String address = "",
    String currency = "KES",
    String email = "",
    String paybill = "",
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
        height: PosTextSize.size2,
        width: PosTextSize.size2,
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
      'Date: ${DateTime.now().toLocal()}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('-' * 32);

    bytes += generator.text(
      'Item        Qty  Price   Total',
      styles: const PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text('-' * 32);

    double subtotal = 0;

    for (var item in items) {
      final name = item['name'] ?? '';
      final qty = item['qty'] ?? 0;
      final price = item['price'] ?? 0.0;
      final total = qty * price;
      subtotal += total;

      // Format fields to exact widths
      final nameStr = name.toString().padRight(12).substring(0, 12);
      final qtyStr = qty.toString().padLeft(3);
      final priceStr = price.toStringAsFixed(2).padLeft(7);
      final totalStr = total.toStringAsFixed(2).padLeft(10);

      // Concatenate with no extra spaces
      final line = '$nameStr$qtyStr$priceStr$totalStr';
      bytes += generator.text(line);
    }

    bytes += generator.text('-' * 32);

    double vat = 0;
    double totalDue = subtotal + vat;

    bytes += generator.text(
      'Sub Total:     $currency${subtotal.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right),
    );
    bytes += generator.text(
      'VAT (16%):     $currency${vat.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right),
    );
    bytes += generator.text(
      'TOTAL: $currency${totalDue.toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.text('Payment: $paymentType');

    // QR Code
    bytes += generator.qrcode(receiptUrl);

    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'System by Pointify,\ncontacts: 0720044055',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }
}
