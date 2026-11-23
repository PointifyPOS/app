import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reggypos/bindings.dart';
import 'package:reggypos/controllers/authcontroller.dart';
import 'package:reggypos/controllers/chat_controller.dart';
import 'package:reggypos/controllers/customercontroller.dart';
import 'package:reggypos/controllers/plancontroller.dart';
import 'package:reggypos/controllers/product_controller_new.dart';
import 'package:reggypos/controllers/productcontroller.dart';
import 'package:reggypos/controllers/purchase_controller.dart';
import 'package:reggypos/controllers/reports_controller.dart';
import 'package:reggypos/controllers/suppliercontroller.dart';
import 'package:reggypos/controllers/usercontroller.dart';
import 'package:reggypos/responsive/appbehaviour.dart';
import 'package:reggypos/screens/authentication/landing.dart';
import 'package:reggypos/services/end_points.dart';
import 'package:reggypos/services/settings.dart';
import 'package:reggypos/utils/app_config.dart';
import 'package:reggypos/utils/colors.dart';
import 'package:reggypos/utils/helper.dart';

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
  AppConfig.app_name = data['APP_NAME'] ?? "ReggyPOS";
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
      title: 'ReggyPOS:',
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
