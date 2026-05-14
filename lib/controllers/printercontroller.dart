import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/main.dart';
import 'package:pointify/widgets/alert.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (date.isNotEmpty) {
      bytes += generator.text(
        'Date: ${DateFormat("MMM dd yyyy hh:mm a").format(DateTime.parse(date).toUtc())}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
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
        PosColumn(
            text: name.length > 18 ? name.substring(0, 18) : name, width: 6),
        PosColumn(
            text: "$qty", width: 2, styles: PosStyles(align: PosAlign.center)),
        PosColumn(
            text: price.toStringAsFixed(0),
            width: 2,
            styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: total.toStringAsFixed(0),
            width: 2,
            styles: PosStyles(align: PosAlign.right)),
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
      size: QRSize.size5, // bigger
      cor: QRCorrection.H, // high error correction
    );
    bytes += generator.feed(1);
    bytes += generator.text(" ");

    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'System by Pointify,\nwebsite: pointifypos.com',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }

  Future<bool> ensurePrinterConnected() async {
    try {
      final bool isConnected = await PrintBluetoothThermal.connectionStatus;

      if (isConnected) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedMac = prefs.getString('saved_printer_mac');

      if (savedMac == null || savedMac.isEmpty) {
        return false;
      }

      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: savedMac,
      );

      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printIosBleBytes(List<int> bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString("ios_ble_printer_id");

      if (savedId == null || savedId.isEmpty) {
        generalAlert(
          title: "Printer Error",
          message:
              "No iPhone printer saved. Go to printer setup and connect first.",
          function: () {},
        );
        return false;
      }

      final device = BluetoothDevice.fromId(savedId);

      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );

      final services = await device.discoverServices();

      BluetoothCharacteristic? writeChar;

      for (final service in services) {
        for (final c in service.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeChar = c;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        generalAlert(
          title: "Printer Error",
          message: "Printer connected but no writable channel found.",
          function: () {},
        );
        return false;
      }

      const int chunkSize = 180;

      for (int i = 0; i < bytes.length; i += chunkSize) {
        final chunk = bytes.sublist(
          i,
          i + chunkSize > bytes.length ? bytes.length : i + chunkSize,
        );

        await writeChar.write(
          chunk,
          withoutResponse: writeChar.properties.writeWithoutResponse,
        );

        await Future.delayed(const Duration(milliseconds: 40));
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await device.disconnect();

      return true;
    } catch (e) {
      print("iOS BLE print failed: $e");
      generalAlert(
        title: "Printer Error",
        message: "iPhone printer failed: $e",
        function: () {},
      );
      return false;
    }
  }
}
