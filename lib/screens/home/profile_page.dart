import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointify/controllers/shopcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/screens/usage/extend_usage.dart';
import 'package:pointify/widgets/loading_dialog.dart';

import '../../controllers/homecontroller.dart';
import '../../printing_page.dart';
import '../../utils/colors.dart';
import '../../widgets/alert.dart';
import '../../widgets/delete_dialog.dart';
import '../../widgets/logout.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';
import '../profile/profile_update.dart';
import '../usage/inapppurchases_screen.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);
  final ShopController createShopController = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userController.currentUser.value?.usertype == "admin"
          ? null
          : AppBar(
              titleSpacing: 0.0,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Icon(Icons.clear, color: AppColors.mainColor),
              ),
            ),
      body: SafeArea(
        child: Obx(
          () => userController.profileupdateLoading.value == true
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen(context) ? 10 : 20,
                      vertical: 10,
                    ).copyWith(right: isSmallScreen(context) ? 10 : 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        majorTitle(
                          title: "User Details",
                          color: Colors.black,
                          size: 18.0,
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 3,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userController.currentUser.value?.email !=
                                        null &&
                                    userController
                                            .currentUser.value?.usertype ==
                                        "admin")
                                  Obx(() {
                                    return profileItems(
                                      title: "Email",
                                      subtitle: userController
                                          .currentUser.value?.email,
                                      icon: Icons.email,
                                    );
                                  }),
                                const SizedBox(height: 15),
                                if (userController
                                        .currentUser.value?.username !=
                                    null)
                                  Obx(() {
                                    return profileItems(
                                      title: "Username",
                                      subtitle: userController
                                              .currentUser.value?.username ??
                                          "",
                                      icon: Icons.person,
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        majorTitle(
                          title: "Settings",
                          color: Colors.black,
                          size: 18.0,
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 3,
                          child: Column(
                            children: [
                              accountCard(
                                title: "Edit Profile",
                                icon: Icons.edit,
                                onPressed: () {
                                  if (isSmallScreen(context)) {
                                    Get.to(() => ProfileUpdate());
                                  } else {
                                    Get.find<HomeController>()
                                        .selectedWidget
                                        .value = ProfileUpdate();
                                  }
                                },
                              ),
                              accountCard(
                                title: "Password Settings",
                                icon: Icons.lock,
                                onPressed: () {
                                  showPasswordResetDialog();
                                },
                              ),
                              if (userController.currentUser.value?.usertype ==
                                  "admin")
                                accountCard(
                                  showDivider: true,
                                  title: "Delete Account",
                                  icon: Icons.delete,
                                  onPressed: () {
                                    deleteDialog(
                                      context: context,
                                      message:
                                          "This action will delete all products, customers, suppliers, sales, purchases and everything else related to your account, do you want to proceed?",
                                      onPressed: () {
                                        userController.deleteAccount();
                                      },
                                    );
                                  },
                                ),
                              accountCard(
                                showDivider: false,
                                title: "Connect BLE Printer",
                                icon: Icons.print,
                                onPressed: () async {
                                  bool res = await askPermissions();
                                  if (res) {
                                    Get.to(
                                      () => const BluetoothReceiptPrinter(),
                                    );
                                  }
                                },
                              ),
                              if (userController.currentUser.value?.usertype ==
                                  "admin")
                                accountCard(
                                  showDivider: false,
                                  title: "Subscription Plans",
                                  icon: Icons.subscriptions,
                                  onPressed: () {
                                    if (Platform.isIOS) {
                                      Get.to(() => InAppPurchasesScreen());
                                    } else {
                                      Get.to(() => ExtendUsage());
                                    }
                                  },
                                ),
                              accountCard(
                                showDivider: false,
                                title: "Check for Updates",
                                icon: Icons.refresh,
                                onPressed: () async {
                                  LoadingDialog.showLoadingDialog(
                                    context: context,
                                    title: "Checking for updates",
                                    key: GlobalKey<State>(),
                                  );
                                  await authController.checkForUpdate();
                                  Get.back();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isSmallScreen(context))
                          Card(
                            elevation: 3,
                            child: accountCard(
                              title: "Logout",
                              icon: Icons.logout,
                              showDivider: false,
                              onPressed: () {
                                logoutAccountDialog(context);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget accountCard({
    required title,
    required icon,
    required onPressed,
    bool? showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: InkWell(
        onTap: () {
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  majorTitle(title: title, color: Colors.grey, size: 16.0),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (showDivider!)
                const Divider(color: Colors.black, thickness: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget accountCardDesktop({required title, required onPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 10, 0),
      child: InkWell(
        onTap: () {
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              majorTitle(title: title, color: Colors.grey, size: 16.0),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileItems({required title, required subtitle, required icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.mainColor),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            majorTitle(title: title, color: AppColors.mainColor, size: 18.0),
            const SizedBox(height: 5),
            minorTitle(title: subtitle, color: Colors.black),
          ],
        ),
      ],
    );
  }

  showPasswordResetDialog() {
    showDialog(
      context: Get.context!,
      builder: (_) {
        return AlertDialog(
          title: const Center(child: Text("Edit Password")),
          content: SizedBox(
            height: MediaQuery.of(Get.context!).size.height * 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    majorTitle(
                      title: "New Password",
                      color: Colors.black,
                      size: 16.0,
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => TextFormField(
                        controller: userController.passwordController,
                        obscureText: authController.showPassword.value,
                        decoration: InputDecoration(
                          suffix: InkWell(
                            child: Icon(
                              authController.showPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onTap: () {
                              authController.showPassword.value =
                                  !authController.showPassword.value;
                            },
                          ),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    majorTitle(
                      title: "Confirm Password",
                      color: Colors.black,
                      size: 16.0,
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => TextFormField(
                        controller: userController.confirmPassword,
                        obscureText: authController.showPassword.value,
                        decoration: InputDecoration(
                          suffix: InkWell(
                            child: Icon(
                              authController.showPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onTap: () {
                              authController.showPassword.value =
                                  !authController.showPassword.value;
                            },
                          ),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: majorTitle(
                        title: "CANCEL",
                        color: AppColors.mainColor,
                        size: 13.0,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (userController.passwordController.text == "" ||
                            userController.confirmPassword.text == "") {
                          generalAlert(
                            message: "please fill all the fields",
                            title: "Error",
                          );
                        } else if (userController.passwordController.text !=
                            userController.confirmPassword.text) {
                          generalAlert(
                            message: "Password mismatched",
                            title: "Error",
                          );
                        } else {
                          if (userController.passwordController.text
                                  .toString()
                                  .trim()
                                  .length <
                              6) {
                            generalAlert(
                              title: "Error",
                              message:
                                  "Password must be more than 6 characters",
                            );
                            return;
                          }

                          authController.showPassword.value = true;
                          Get.back();
                          await userController.profileUpdate();
                          userController.passwordController.clear();
                          userController.confirmPassword.clear();
                        }
                      },
                      child: majorTitle(
                        title: "UPDATE",
                        color: AppColors.mainColor,
                        size: 13.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  askPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();
      if (statuses[Permission.location]!.isGranted &&
          statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothAdvertise]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted) {
        return true;
      } else {
        return false;
      } //check each permission status after.
    } else {
      return true;
    }
  }
}
