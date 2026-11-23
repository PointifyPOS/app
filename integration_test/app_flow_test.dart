// End-to-end smoke test for ReggyPOS.
//
// Runs the real app against a running ReggyPOS API:
//   flutter test integration_test/app_flow_test.dart \
//     --dart-define=API_BASE=http://localhost:3000/ -d <simulator-id>
//
// Each step prints "SHOT:<name>" so an external script can take screenshots.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reggypos/controllers/authcontroller.dart';
import 'package:reggypos/controllers/shopcontroller.dart';
import 'package:reggypos/main.dart' as app;
import 'package:reggypos/screens/authentication/admin/sign_up.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
  String? what,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for ${what ?? finder}');
}

Future<void> shot(WidgetTester tester, String name) async {
  // Let animations settle and give the external script time to screenshot.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  // ignore: avoid_print
  print('SHOT:$name');
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Finder fieldFor(TextEditingController c) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == c);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register owner and create first shop', (tester) async {
    app.main();
    await pumpUntil(tester, find.text('BUSINESS OWNER'), what: 'landing screen');
    await shot(tester, '01_landing');

    // Landing -> owner login
    await tester.tap(find.text('BUSINESS OWNER'));
    await pumpUntil(tester, find.text('SIGN IN'), what: 'login screen');
    await shot(tester, '02_login');

    // Open sign-up and register a new owner
    Get.to(() => SignUp());
    await pumpUntil(tester, find.text('CREATE ACCOUNT'), what: 'sign-up screen');
    final auth = Get.find<AuthController>();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.enterText(fieldFor(auth.nameController), 'Test Owner');
    await tester.enterText(fieldFor(auth.emailController), 'owner$stamp@test.local');
    await tester.enterText(fieldFor(auth.phoneController), '7${stamp % 100000000}'.padRight(9, '0'));
    await tester.enterText(fieldFor(auth.passwordController), 'Passw0rd!');
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, '03_signup_filled');

    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await pumpUntil(tester, find.text('Business type'),
        timeout: const Duration(seconds: 60), what: 'create-shop screen');
    await shot(tester, '04_create_shop');

    // Create the first shop
    final shops = Get.find<ShopController>();
    await tester.enterText(fieldFor(shops.nameController), 'Test Shop');
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded).first);
    await pumpUntil(tester, find.text('Retail Shop'), what: 'seeded business types');
    await shot(tester, '05_business_types');
    await tester.tap(find.text('Retail Shop'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Continue'));
    await pumpUntil(tester, find.text('Retail Shop'), what: 'selected business type');

    // Location: type an address and use it as-is (no Google Places key needed)
    await tester.tap(fieldFor(shops.reqionController));
    await pumpUntil(tester, find.text('Enter your address'), what: 'address search');
    await tester.enterText(find.byType(TextField).last, 'Nairobi CBD');
    await pumpUntil(tester, find.text('Use "Nairobi CBD"'), what: 'manual address option');
    await shot(tester, '06_address_manual');
    await tester.tap(find.text('Use "Nairobi CBD"'));
    await pumpUntil(tester, find.text('Business type'), what: 'back on create-shop');
    expect(shops.reqionController.text, 'Nairobi CBD');
    await shot(tester, '07_shop_filled');

    final create = find.text('Create ');
    await tester.ensureVisible(create);
    await tester.tap(create);
    // Home is reached once the create-shop form is gone.
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (find.text('Business type').evaluate().isNotEmpty &&
        DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('Business type'), findsNothing,
        reason: 'still on create-shop screen after tapping Create');
    await shot(tester, '08_home');
  });
}
