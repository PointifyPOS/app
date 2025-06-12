import 'package:flutter/material.dart';

class AffiliatePage extends StatelessWidget {
  const AffiliatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Affiliate'),
        ),
        body: const Column(children: [
          Text('Affiliate Page'),
        ]));
  }
}
