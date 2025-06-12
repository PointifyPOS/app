import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/widgets/shop_list_bottomsheet.dart';

import '../controllers/authcontroller.dart';
import '../controllers/shopcontroller.dart';
import '../controllers/usercontroller.dart';
import '../functions/functions.dart';
import '../screens/usage/extend_usage.dart';
import '../screens/usage/inapppurchases_screen.dart';
import '../utils/colors.dart';
import 'major_title.dart';
import 'minor_title.dart';

class HomeSectionView extends StatelessWidget {
  String? type = "Shop";
  HomeSectionView({super.key, this.type});
  UserController userController = Get.find<UserController>();
  final ShopController shopController = Get.find<ShopController>();
  final AuthController authController = Get.find<AuthController>();
  final DateTime now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          if (!userController.isAttendannt())
            Obx(
              () => userController.currentUser.value?.emailVerified == false
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  "Verify Your email",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "You have ${DateTime.parse(userController.currentUser.value?.emailVerificationDate ?? DateTime.now().toString()).add(const Duration(days: 1)).difference(DateTime(now.year, now.month, now.day)).inDays} days to verify your email",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                userController.sendVerificationEmail();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  "Verify now",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : userController.currentUser.value?.usertype == ""
                      ? Container()
                      : Container(),
            ),
          const SizedBox(
            height: 10,
          ),
          Obx(() => userController.internetConected.isFalse
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "You have no internet connection",
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(Icons.wifi_off, color: Colors.white)
                      ],
                    ),
                  ),
                )
              : Container()),
          Obx(
            () => shopController.checkSubscription() == false
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (shopController.checkIfTrial())
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: shopController.checkIfTrial()
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Your trial period has expired",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  if (shopController.checkDaysRemaining() > 0)
                                    Text(
                                      "${shopController.checkDaysRemaining()} days remaining",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                    ),
                                ],
                              ),
                            if (!shopController.checkIfTrial())
                              const Text(
                                "Your subscription has expired",
                                style: TextStyle(color: Colors.white),
                              ),
                            InkWell(
                              onTap: () {
                                if (Platform.isIOS) {
                                  Get.to(() => InAppPurchasesScreen());
                                } else {
                                  Get.to(() => ExtendUsage());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  "Upgrade now",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : userController.currentUser.value?.usertype == ""
                    ? Container()
                    : Container(),
          ),
          Row(
            children: [
              majorTitle(
                  title: "Current $type", color: Colors.black, size: 15.0),
              const SizedBox(
                width: 5,
              ),
              if (type == "shop")
                majorTitle(
                    title: shopController.checkSubscription() == false
                        ? "Expired"
                        : "Active",
                    color: shopController.checkSubscription()
                        ? Colors.green
                        : Colors.red,
                    size: 10.0),
              if (userController.currentUser.value?.usertype == "attendant")
                const Spacer(),
              if (userController.currentUser.value?.usertype == "attendant")
                IconButton(
                    onPressed: () async {
                      try {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Just a moment"),
                                    )
                                  ],
                                ),
                              );
                            });
                        await authController.initUser();
                        Get.back();
                      } catch (e) {
                        Get.back();
                      }
                    },
                    icon: const Icon(Icons.refresh))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                return minorTitle(
                    title: userController.currentUser.value?.primaryShop == null
                        ? ""
                        : "${userController.currentUser.value?.primaryShop!.name} ",
                    color: AppColors.mainColor);
              }),
              if (verifyPermission(category: 'shop', permission: "switch"))
                Obx(
                  () => shopController.gettingShopsLoad.isTrue
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator()),
                        )
                      : InkWell(
                          onTap: shopController.gettingShopsLoad.isTrue
                              ? null
                              : () async {
                                  await shopController.getShops();
                                  showShopModalBottomSheet(Get.context);
                                },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: AppColors.mainColor, width: 2),
                            ),
                            child: minorTitle(
                                title: "Switch Shop",
                                color: AppColors.mainColor),
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
