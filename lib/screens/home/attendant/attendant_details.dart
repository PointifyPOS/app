import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/shopcontroller.dart';
import 'package:pointify/controllers/usercontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/responsive/responsiveness.dart';
import 'package:pointify/utils/helper.dart';
import 'package:switcher_button/switcher_button.dart';

import '../../../../utils/colors.dart';
import '../../../controllers/homecontroller.dart';
import '../../../models/usermodel.dart';
import '../../../widgets/alert.dart';
import '../../../widgets/attendant_user_inputs.dart';
import '../../../widgets/delete_dialog.dart';
import '../../../widgets/major_title.dart';
import '../../../widgets/minor_title.dart';
import 'attendants_page.dart';

class AttendantDetails extends StatelessWidget {
  final UserModel? userModel;

  AttendantDetails({Key? key, required this.userModel}) : super(key: key) {
    if (userModel != null) {
      userController.nameController.text = userModel!.username ?? "";
      userController.attendantId.text = userModel!.uniqueDigits.toString();
      userController.getRoles(userModel!);
    } else {
      userController.attendantId.text = Random().nextInt(30000).toString();
    }
  }

  final ShopController shopController = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    return Helper(
      widget: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: userDetails(context),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              if (userModel != null)
                InkWell(
                  onTap: () {
                    if (isSmallScreen(context)) {
                      Get.to(() => Permissions(userModel: userModel));
                    } else {
                      Get.find<HomeController>().selectedWidget.value =
                          Permissions(userModel: userModel);
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              majorTitle(
                                  title: "Update Permissions",
                                  color: Colors.black,
                                  size: 16.0),
                              minorTitle(
                                title: "update roles and permissions",
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.lock)
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0.0,
        titleSpacing: 0.0,
        centerTitle: false,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (isSmallScreen(context)) {
              Get.back();
            } else {
              Get.find<HomeController>().selectedWidget.value =
                  AttendantsPage();
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              majorTitle(
                  title: userModel == null
                      ? "New Attendant"
                      : userModel?.username ?? userModel?.username,
                  color: Colors.black,
                  size: 16.0),
            ],
          ),
        ),
        actions: [
          if (!isSmallScreen(context) && userModel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                  onPressed: () {
                    deleteDialog(
                        context: context,
                        onPressed: () {
                          userController.deleteAttendant(userModel: userModel);
                          Get.find<HomeController>().selectedWidget.value =
                              AttendantsPage();
                        });
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  )),
            )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: userModel == null || !isSmallScreen(context)
            ? Container(
                height: 0,
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () {
                    deleteDialog(
                        context: context,
                        onPressed: () {
                          userController.deleteAttendant(userModel: userModel);
                        });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: Center(
                      child: majorTitle(
                          title: "Remove Attendant",
                          color: Colors.red,
                          size: 16.0),
                    ),
                  ),
                )),
      ),
      floatButton: Container(),
    );
  }

  Widget userDetails(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        attendantUserInputs(
            name: "Username", controller: userController.nameController),
        const SizedBox(height: 15),
        if (userModel == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              majorTitle(title: "Password", color: Colors.black, size: 14.0),
              const SizedBox(height: 10),
              TextFormField(
                controller: userController.passwordController,
                enabled: true,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 15),
        attendantUserInputs(
            name: "User ID",
            controller: userController.attendantId, //81975
            enabled: false),
        const SizedBox(height: 15),
        if (userModel == null)
          SizedBox(
              height: 50,
              child: InkWell(
                onTap: () {
                  isSmallScreen(context)
                      ? Get.to(() => Permissions())
                      : Get.find<HomeController>().selectedWidget.value =
                          Permissions();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(width: 3, color: AppColors.mainColor),
                      borderRadius: BorderRadius.circular(40)),
                  child: Center(
                      child: majorTitle(
                          title: "Next",
                          color: AppColors.mainColor,
                          size: 18.0)),
                ),
              )),
        if (userModel != null)
          Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: majorTitle(
                              title: "Update Password",
                              color: Colors.black,
                              size: 16.0),
                          content: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                attendantUserInputs(
                                    name: "New Password",
                                    controller:
                                        userController.passwordController),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Get.back();
                                },
                                child: majorTitle(
                                    title: "Cancel",
                                    color: AppColors.mainColor,
                                    size: 13.0)),
                            TextButton(
                                onPressed: () async {
                                  if (userController
                                          .passwordController.text.length <
                                      6) {
                                    generalAlert(
                                        title: "Error",
                                        message:
                                            "password must be between 6 and 128 characters",
                                        negativeText: "");
                                    return;
                                  }
                                  await userController.updateAttendant(
                                      userModel: userModel!, type: "other");
                                },
                                child: majorTitle(
                                    title: "Okay",
                                    color: AppColors.mainColor,
                                    size: 13.0))
                          ],
                        );
                      });
                },
                child: majorTitle(
                    title: "Reset Password",
                    color: AppColors.mainColor,
                    size: 17.0),
              )),
        const SizedBox(
          height: 10,
        ),
        if (userModel != null)
          Center(
            child: SizedBox(
                height: 50,
                width: isSmallScreen(context) ? double.infinity : 200,
                child: InkWell(
                  onTap: () async {
                    await userController.updateAttendant(
                        userModel: userModel!, type: "other");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 3, color: AppColors.mainColor),
                        borderRadius: BorderRadius.circular(40)),
                    child: Center(
                        child: majorTitle(
                            title: "Update",
                            color: AppColors.mainColor,
                            size: 18.0)),
                  ),
                )),
          ),
      ],
    );
  }
}

class Permissions extends StatelessWidget {
  final UserModel? userModel;

  Permissions({Key? key, this.userModel}) : super(key: key);
  final UserController userController = Get.find<UserController>();

  itemRow({required String key, required data, required catId}) {
    var permission = userController.permissions[catId];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          majorTitle(
              title: key.capitalize!.replaceAll("_", " "),
              color: Colors.black,
              size: 14.0),
          const Spacer(),
          Obx(
            () => SwitcherButton(
              onColor: AppColors.mainColor,
              offColor: Colors.grey,
              size: 40,
              value: userController.roles
                      .where((p0) => p0["key"] == permission["key"])
                      .toList()
                      .isNotEmpty &&
                  userController.roles
                      .where((p0) => p0["key"] == permission["key"])
                      .toList()[0]["value"]
                      .contains(key),
              onChange: (value) {
                String keyy = userController.permissions[catId]["key"];
                int i = userController.roles
                    .indexWhere((element) => element["key"] == keyy);
                if (i != -1) {
                  if (value == false) {
                    int ii = userController.roles[i]["value"]
                        .indexWhere((element) => element == key);
                    if (ii != -1) {
                      userController.roles[i]["value"].removeAt(ii);
                    }
                    if ((userController.roles[i]["value"] as List).isEmpty) {
                      userController.roles.removeAt(i);
                    }
                  } else {
                    userController.roles[i]["value"].add(key);
                  }
                } else {
                  var role = {
                    "key": keyy,
                    "value": [key]
                  };
                  userController.roles.addAll([role]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    userController.permissions = RxList([
      {
        "key": "pos",
        "value": [
          "set_sale_date",
          'can_sell',
          'can_sell_to_dealer_&_wholesaler',
          'discount',
          "edit_price",
        ],
      },
      {
        "key": "stocks",
        "value": [
          'view_products',
          'add_products',
          "view_buying_price",
          'stock_summary',
          'view_purchases',
          'add_purchases',
          'stock_count',
          'badstock',
          'transfer',
          'return',
          'delete_purchase_invoice',
        ],
      },
      {
        "key": "products",
        "value": [
          'edit',
          'delete',
          'add',
          "adjust_stock",
          "view_adjustment_history"
        ],
      },
      {
        "key": "sales",
        "value": ['view_sales', "return", "delete", "view_profit"],
      },
      {
        "key": "reports",
        "value": [
          'sales',
          "dues",
          "productsales",
          "discoutedsales",
          "debtors",
          "purchases",
          "expenses",
          "stocktake",
          "netprofit",
          'stockreport',
          "productmovement",
          "profitanalysis"
        ],
      },
      {
        "key": "purchases",
        "value": ['edit_buying_price'],
      },
      {
        "key": "accounts",
        "value": [
          'cashflow',
        ],
      },
      {
        "key": "expenses",
        "value": [
          'manage',
        ],
      },
      {
        "key": "suppliers",
        "value": ['manage']
      },
      {
        "key": "customers",
        "value": ['manage', 'deposit']
      },
      {
        "key": 'shop',
        "value": ["manage", "switch"],
      },
      {
        "key": 'attendants',
        "value": ["manage", "view"],
      },
      {
        "key": 'usage',
        "value": ["manage"],
      },
      {
        "key": 'support',
        "value": ["manage"],
      },
    ]);

    if (userController.currentUser.value!.primaryShop!.production == true) {
      userController.permissions.add({
        "key": 'production',
        "value": [
          "delete",
          "change_status",
          "edit",
          "adjust_stock",
          'view_adjustment_history'
        ],
      });
    }
    if (userController.currentUser.value!.primaryShop!.warehouse == true) {
      userController.permissions.add(
        {
          "key": "warehouse",
          "value": [
            'invoice_delete',
            "show_buying_price",
            "show_available_stock",
            "view_buying_price",
            "create_orders",
            "view_orders",
            "return",
            "accept_warehouse_orders"
          ],
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isSmallScreen(context) ? AppColors.mainColor : Colors.white,
        leading: IconButton(
            onPressed: () {
              if (isSmallScreen(context)) {
                Get.back();
              } else {
                Get.find<HomeController>().selectedWidget.value =
                    AttendantDetails(
                  userModel: userModel,
                );
              }
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: isSmallScreen(context) ? Colors.white : Colors.black,
            )),
        title: Text(
          "Permissions",
          style: TextStyle(
              color: isSmallScreen(context) ? Colors.white : Colors.black),
        ),
        elevation: 0.2,
        actions: [
          if (!isSmallScreen(context))
            InkWell(
              splashColor: Colors.transparent,
              onTap: () async {
                var all = [];
                for (var element in userController.roles) {
                  all.add({"key": element["key"], "value": element["value"]});
                }
                if (userModel == null) {
                  await userController.createAttendant(all);
                } else {
                  await userController.updateAttendant(
                      userModel: userModel!,
                      permissions: all,
                      type: "permissions");
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(5).copyWith(right: 15),
                height: kToolbarHeight,
                decoration: BoxDecoration(
                    border: Border.all(width: 3, color: AppColors.mainColor),
                    borderRadius: BorderRadius.circular(40)),
                child: Center(
                    child: majorTitle(
                        title: "Update Changes",
                        color: AppColors.mainColor,
                        size: 18.0)),
              ),
            )
        ],
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: userController.permissions.length,
          itemBuilder: (c, ii) {
            var role = userController.permissions[ii];
            var title = role["key"];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (userController.activePermission.value == title) {
                      userController.activePermission.value = "";
                    } else {
                      userController.activePermission.value = title;
                    }
                    userController.activePermission.refresh();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 10, top: 10, left: 20, right: 20),
                    child: Row(
                      children: [
                        Text(title.toString().toUpperCase()),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded)
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Obx(() => userController.activePermission.value != role["key"]
                    ? Container()
                    : Container(
                        height: double.parse(
                                (role["value"] as List).length.toString()) *
                            35,
                        margin: const EdgeInsets.only(left: 20),
                        child: ListView.builder(
                            itemCount: (role["value"] as List).length,
                            itemBuilder: (c, i) {
                              var p = role["value"][i];
                              return itemRow(
                                  key: p, data: role["value"], catId: ii);
                            }),
                      ))
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: isSmallScreen(context) ? 50 : 0,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Obx(
          () => userController.profileupdateLoading.isTrue
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : InkWell(
                  splashColor: Colors.transparent,
                  onTap: () async {
                    var all = [];
                    for (var element in userController.roles) {
                      all.add(
                          {"key": element["key"], "value": element["value"]});
                    }
                    if (userModel == null) {
                      await userController.createAttendant(all);
                    } else {
                      await userController.updateAttendant(
                          userModel: userModel!,
                          permissions: all,
                          type: "permissions");
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 3, color: AppColors.mainColor),
                        borderRadius: BorderRadius.circular(40)),
                    child: Center(
                        child: majorTitle(
                            title: "Update Changes",
                            color: AppColors.mainColor,
                            size: 18.0)),
                  ),
                ),
        ),
      ),
    );
  }
}
