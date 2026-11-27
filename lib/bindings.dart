import 'package:get/get.dart';
import 'package:reggypos/controllers/homecontroller.dart';
import 'package:reggypos/controllers/usercontroller.dart';

import 'controllers/authcontroller.dart';
import 'controllers/printercontroller.dart';
import 'controllers/shopcontroller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.put<ShopController>(ShopController(), permanent: true);
    Get.put<PrinterController>(PrinterController(), permanent: true);
  }
}
