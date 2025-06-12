import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'command_tool.dart';

class FunctionPage extends StatefulWidget {
  final BluetoothDevice device;

  const FunctionPage(this.device, {super.key});

  @override
  State<FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<FunctionPage> {
  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
    _disconnect();
  }

  void _disconnect() async {
    await BluetoothPrintPlus.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name ?? "")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton(
                onPressed: () async {
                  Uint8List? cmd = await CommandTool.escReceiptCmd(
                    items: [
                      {"name": "Apple", "qty": 2, "price": 1.50},
                      {"name": "Banana", "qty": 3, "price": 0.75},
                      {"name": "Orange", "qty": 1, "price": 1.25},
                    ],
                  );
                  await BluetoothPrintPlus.write(cmd);
                  // print("getCommand $cmd");
                },
                child: Text("text/QR_code/barcode"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
