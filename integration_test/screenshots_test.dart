// Walks through the main screens of a shop that already has data, for store
// screenshots. Needs a running API with a seeded owner account:
//   flutter test integration_test/screenshots_test.dart \
//     --dart-define=API_BASE=http://localhost:3000/ \
//     --dart-define=DEMO_EMAIL=demo@example.com --dart-define=DEMO_PASSWORD=secret \
//     -d <simulator-id>
//
// Each step prints "SHOT:<name>" so an external script can take screenshots.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reggypos/controllers/authcontroller.dart';
import 'package:reggypos/main.dart' as app;
import 'package:reggypos/reports/reports.dart';
import 'package:reggypos/screens/customers/customers_page.dart';
import 'package:reggypos/screens/product/products_page.dart';
import 'package:reggypos/screens/sales/all_sales.dart';
import 'package:reggypos/screens/sales/create_sale.dart';
import 'package:reggypos/screens/stock/stock_page.dart';
import 'package:reggypos/utils/date_filter.dart';

const demoEmail = String.fromEnvironment('DEMO_EMAIL');
const demoPassword = String.fromEnvironment('DEMO_PASSWORD');

Future<void> pumpUntil(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 45), String? what}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for ${what ?? finder}');
}

Future<void> settle(WidgetTester tester, [int quarterSeconds = 16]) async {
  for (var i = 0; i < quarterSeconds; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  await settle(tester, 12);
  // ignore: avoid_print
  print('SHOT:$name');
  await settle(tester, 16);
}

Finder fieldFor(TextEditingController c) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == c);

Future<void> open(WidgetTester tester, Widget Function() page, String name) async {
  Get.to(page);
  await settle(tester, 20); // let the screen load its data
  await shot(tester, name);
  Get.back();
  await settle(tester, 6);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshots of a shop with data', (tester) async {
    expect(demoEmail, isNotEmpty, reason: 'pass --dart-define=DEMO_EMAIL=...');
    app.main();
    await pumpUntil(tester, find.text('BUSINESS OWNER'), what: 'landing screen');
    await shot(tester, '01_landing');

    await tester.tap(find.text('BUSINESS OWNER'));
    await pumpUntil(tester, find.text('SIGN IN'), what: 'login screen');
    final auth = Get.find<AuthController>();
    await tester.enterText(fieldFor(auth.emailController), demoEmail);
    await tester.enterText(fieldFor(auth.passwordController), demoPassword);
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, '02_login');
    await tester.tap(find.text('SIGN IN'));
    await pumpUntil(tester, find.text('Home'),
        timeout: const Duration(seconds: 60), what: 'home screen');
    await settle(tester, 24);
    await shot(tester, '03_home');

    await open(tester, () => CreateSale(), '04_sell');
    await open(tester, () => ProductPage(), '05_products');
    await open(tester, () => const AllSalesPage(page: ""), '06_sales');
    await open(tester, () => StockPage(), '07_stock');
    await open(tester, () => CustomersPage(), '08_customers');
    await open(tester, () => Reports(), '09_reports');
    await open(tester, () => DateFilter(from: "AllSalesPage", function: (_) {}),
        '10_date_filter');
  });
}
