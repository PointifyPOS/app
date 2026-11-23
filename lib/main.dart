import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:pointify/bindings.dart';
import 'package:pointify/controllers/authcontroller.dart';
import 'package:pointify/controllers/chat_controller.dart';
import 'package:pointify/controllers/customercontroller.dart';
import 'package:pointify/controllers/plancontroller.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/controllers/purchase_controller.dart';
import 'package:pointify/controllers/reports_controller.dart';
import 'package:pointify/controllers/suppliercontroller.dart';
import 'package:pointify/controllers/usercontroller.dart';
import 'package:pointify/responsive/appbehaviour.dart';
import 'package:pointify/screens/authentication/landing.dart';
import 'package:pointify/services/end_points.dart';
import 'package:pointify/services/settings.dart';
import 'package:pointify/utils/app_config.dart';
import 'package:pointify/utils/colors.dart';
import 'package:pointify/utils/constants.dart';
import 'package:pointify/utils/helper.dart';

import 'controllers/cashflowcontroller.dart';
import 'controllers/ordercontroller.dart';
import 'controllers/paymentcontroller.dart';
import 'controllers/printercontroller.dart';
import 'controllers/shopcontroller.dart';
import 'controllers/stockcontroller.dart';
import 'firebase_options.dart';

final AuthController authController = Get.put(AuthController());
UserController userController = Get.put<UserController>(UserController());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Theme/branding is optional: fall back to defaults if the API is unreachable
  // or has no theme saved yet, instead of failing before runApp().
  Map data = {};
  try {
    final response = await SettingsApi.getThemes();
    if (response is Map) data = response;
  } catch (e) {
    debugPrint("Could not load theme, using defaults: $e");
  }

  final logoPath = (data['image'] ?? "").toString();
  AppConfig.app_logo =
      logoPath.isEmpty ? "" : apiEndPoint + logoPath.replaceFirst("/", "");
  AppConfig.app_name = data['APP_NAME'] ?? "Pointify";
  AppConfig.app_slogan = data['APP_SLOGAN'] ?? "";

  // Keep the built-in colours unless the theme provides a valid one.
  Color themeColor(dynamic hex, Color fallback) {
    if (hex is! String || hex.trim().isEmpty) return fallback;
    try {
      return parseColor(hex.trim());
    } catch (_) {
      return fallback;
    }
  }

  AppColors.mainColor = themeColor(data["PRIMARY_COLOR"], AppColors.mainColor);
  AppColors.button_color =
      themeColor(data["BUTTON_COLOR"], AppColors.button_color);
  AppColors.text_color = themeColor(data["TEXT_COLOR"], AppColors.text_color);
  AppColors.secondary_color =
      themeColor(data["SECONDARY_COLOR"], AppColors.secondary_color);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AuthController authController = Get.put<AuthController>(AuthController());

  PlanController planController = Get.put<PlanController>(PlanController());

  ShopController shopController = Get.put<ShopController>(ShopController());

  ProductController productController = Get.put<ProductController>(
    ProductController(),
  );
  ProductNewController productNewController = Get.put<ProductNewController>(
    ProductNewController(),
  );

  CustomerController customerController = Get.put<CustomerController>(
    CustomerController(),
  );

  SupplierController supplierController = Get.put<SupplierController>(
    SupplierController(),
  );

  PurchaseController purchaseController = Get.put<PurchaseController>(
    PurchaseController(),
  );

  PaymentController paymentController = Get.put<PaymentController>(
    PaymentController(),
  );

  PrinterController printerController = Get.put<PrinterController>(
    PrinterController(),
  );
  StockController stockController = Get.put<StockController>(StockController());

  CashFlowController cashFlowController = Get.put<CashFlowController>(
    CashFlowController(),
  );

  ReportsController reportsController = Get.put<ReportsController>(
    ReportsController(),
  );

  OrderController orderController = Get.put<OrderController>(OrderController());
  ChatController chatController = Get.put<ChatController>(ChatController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pointify:',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        primaryColor: AppColors.mainColor,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      initialBinding: AuthBinding(),
      home: const Landing(),
    );
  }
}
