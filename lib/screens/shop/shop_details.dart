import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/paymentcontroller.dart';
import 'package:pointify/controllers/reports_controller.dart';
import 'package:pointify/controllers/shopcontroller.dart';
import 'package:pointify/screens/shop/edit_shop_details.dart';
import 'package:pointify/screens/shop/shop_address.dart';
import 'package:pointify/screens/usage/extend_usage.dart';
import 'package:pointify/utils/colors.dart';
import 'package:pointify/utils/helper.dart';
import 'package:pointify/widgets/alert.dart';
import 'package:pointify/widgets/textbutton.dart';

import '../../../main.dart';
import '../../controllers/salescontroller.dart';
import '../../models/shop.dart';
import '../../reports/components/summarycard.dart';
import '../../services/place_service.dart';
import '../../services/shop_services.dart';
import '../../utils/themer.dart';
import '../../widgets/delete_dialog.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/minor_title.dart';

class ShopDetails extends StatelessWidget {
  final Shop shopModel;
  ShopDetails({Key? key, required this.shopModel}) : super(key: key) {
    reportsController.getSalesReport(
      startDate: reportsController.filterStartDate.value,
      toDate: reportsController.filterEndDate.value,
      shopid: userController.currentUser.value!.primaryShop!.id!,
    );
  }

  final ReportsController reportsController = Get.find<ReportsController>();
  final PaymentController paymentController = Get.find<PaymentController>();
  final SalesController salesController = Get.find<SalesController>();
  final ShopController shopController = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    if (shopModel.backupInterval == null) {
      shopController.selectedbackupsendinterval["value"] = shopController
          .backupsendinterval
          .where((p0) => p0["name"] == shopModel.backupInterval)
          .first["value"];
    }
    if (shopModel.backupemail != null) {
      shopController.backupemail.text = shopModel.backupemail!;
    } else {
      shopController.backupemail.text =
          userController.currentUser.value!.email!;
    }
    shopController.shopLocation.value = shopModel.location!;
    shopController.allowOnlineSelling.value = shopModel.allowOnlineSelling!;
    shopController.productionEnabled.value = shopModel.production!;
    shopController.allowBackup.value = shopModel.allowBackup!;
    shopController.useWarehouse.value = shopModel.useWarehouse!;
    return Helper(
      widget: ListView(
        children: [
          Card(
            elevation: 5,
            child: Container(
              padding: const EdgeInsets.all(15.0),
              width: double.infinity,
              child: Obx(
                () => ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      summaryCard(
                          title: "Shop Settings",
                          description: "Shop settings",
                          widget: const Icon(
                            Icons.arrow_forward_ios_rounded,
                          ),
                          onPressed: (key) {
                            Get.to(() => EditShopDetails(shopModel: shopModel));
                          }),
                      summaryCard(
                          title: "Backup settings",
                          description:
                              "Data back is automated by default but you can download it instantly as well",
                          widget: Icon(
                            shopController.showbackupsettings.isTrue
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                          ),
                          // key: "end",
                          onPressed: (key) {
                            shopController.showbackupsettings.value =
                                !shopController.showbackupsettings.value;

                            shopController.onlinesellingsettings.value = false;
                          }),
                      if (shopController.showbackupsettings.isTrue)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Card(
                            elevation: 5,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Allow Backup?",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 18),
                                      ),
                                      CupertinoSwitch(
                                        value: shopController.allowBackup.value,
                                        activeColor: AppColors.mainColor,
                                        onChanged: (value) {
                                          shopModel.allowBackup = value;
                                          shopController.allowBackup.value =
                                              value;
                                          shopController.updateShop(
                                            shop: shopModel,
                                            allowBackup: shopModel.allowBackup!,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  if (shopController.allowBackup.isTrue)
                                    Column(
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    shopController.backupemail,
                                                decoration: ThemeHelper()
                                                    .textInputDecoration(
                                                        "Email to receive backup files",
                                                        "Enter your name",
                                                        Icons.email, () {
                                                  shopController.updateShop(
                                                      shop: shopModel,
                                                      backupemail:
                                                          shopController
                                                              .backupemail
                                                              .text);
                                                }),
                                                onChanged: (v) {
                                                  shopController
                                                      .updateEmail.value = true;
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            if (shopController
                                                .updateEmail.isTrue)
                                              InkWell(
                                                onTap: () {
                                                  if (!validateEmail(
                                                      shopController
                                                          .backupemail.text)) {
                                                    generalAlert(
                                                      title: "Error",
                                                      message:
                                                          "Please enter a valid email",
                                                    );
                                                    return;
                                                  }

                                                  shopController.updateShop(
                                                      shop: shopModel,
                                                      backupemail:
                                                          shopController
                                                              .backupemail
                                                              .text);
                                                  shopController.updateEmail
                                                      .value = false;
                                                  FocusScope.of(Get.context!)
                                                      .requestFocus(
                                                          FocusNode());
                                                },
                                                child:  Text(
                                                  "Update",
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.mainColor),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        TextFormField(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Select an option'),
                                                  content: SizedBox(
                                                    width: double.maxFinite,
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount: shopController
                                                          .backupsendinterval
                                                          .length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        return ListTile(
                                                          title: Text(shopController
                                                                  .backupsendinterval[
                                                              index]["value"]),
                                                          onTap: () {
                                                            // Handle option selection here
                                                            Navigator.pop(
                                                                context,
                                                                shopController
                                                                        .backupsendinterval[
                                                                    index]);
                                                            shopController
                                                                .selectedbackupsendinterval
                                                                .value = shopController
                                                                    .backupsendinterval[
                                                                index];
                                                            shopController.updateShop(
                                                                shop: shopModel,
                                                                backup: shopController
                                                                        .selectedbackupsendinterval[
                                                                    "name"]);
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          controller: TextEditingController(
                                              text: shopController
                                                      .selectedbackupsendinterval[
                                                  "value"]),
                                          readOnly: true,
                                          decoration: ThemeHelper()
                                              .textInputDecoration(
                                                  "Backup Send Interval",
                                                  "Select your backup send interval",
                                                  Icons.watch_later_outlined,
                                                  () {}),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        shopController.isBacking.isTrue
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : textBtn(
                                                text: "Download Backup Now",
                                                hPadding: 40,
                                                vPadding: 10,
                                                bgColor: Colors.amber,
                                                onPressed: () {
                                                  if (shopController
                                                          .checkSubscription() ==
                                                      false) {
                                                    generalAlert(
                                                        title: "Error",
                                                        message:
                                                            "Please upgrade your shop subscription to download backup",
                                                        function: () {
                                                          Get.to(() =>
                                                              ExtendUsage());
                                                        });
                                                  } else {
                                                    return showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                              title: const Text(
                                                                  "What you will get"),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                      "✅ Product Sales Report 📃"),
                                                                  const Text(
                                                                      "✅ Products Report 📃"),
                                                                  const Text(
                                                                      "✅ Customers 📃"),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  textBtn(
                                                                      text:
                                                                          "Backup Now ⬇️",
                                                                      hPadding:
                                                                          80,
                                                                      vPadding:
                                                                          10,
                                                                      bgColor:
                                                                          Colors
                                                                              .amber,
                                                                      onPressed:
                                                                          () {
                                                                        shopController.backupNow(
                                                                            shopModel:
                                                                                shopModel);
                                                                        Get.back();
                                                                      })
                                                                ],
                                                              ));
                                                        });
                                                  }
                                                }),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (shopModel.warehouse == false)
                        summaryCard(
                            title: "Online Selling Settings",
                            description:
                                "Click to set up online selling options",
                            widget: Icon(
                              shopController.onlinesellingsettings.isTrue
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                            ),
                            onPressed: (key) {
                              shopController.onlinesellingsettings.value =
                                  !shopController.onlinesellingsettings.value;
                              shopController.showbackupsettings.value = false;
                            }),
                      if (shopController.onlinesellingsettings.isTrue)
                        Card(
                          elevation: 5,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Allow Online Selling?",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 13),
                                    ),
                                    CupertinoSwitch(
                                      value: shopController
                                          .allowOnlineSelling.value,
                                      activeColor: AppColors.mainColor,
                                      onChanged: (value) {
                                        shopModel.allowOnlineSelling = value;
                                        shopController
                                            .allowOnlineSelling.value = value;
                                        shopController.updateShop(
                                          shop: shopModel,
                                          allowOnlineSelling:
                                              shopModel.allowOnlineSelling!,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                if (shopController.allowOnlineSelling.isTrue)
                                  InkWell(
                                    onTap: () async {
                                      final Suggestion? result =
                                          await showSearch(
                                        context: context,
                                        delegate: AddressSearch("details"),
                                      );
                                      if (result != null) {
                                        shopModel.location = result.description;
                                        shopController.reqionController.text =
                                            result.description;
                                        shopController.shopLocation.value =
                                            result.description;

                                        locationFromAddress(result.description)
                                            .then((value) {
                                          shopController.updateShop(
                                            shop: shopModel,
                                            location: result.description,
                                            latitude:
                                                value.first.latitude.toString(),
                                            longitude: value.first.longitude
                                                .toString(),
                                          );
                                        });
                                        shopController.shopLocation.refresh();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: AppColors.mainColor,
                                          )),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                 Text(
                                                    "Pick Current location",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.mainColor,
                                                    )),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                    shopController
                                                        .shopLocation.value,
                                                    style:  TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          AppColors.mainColor,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.location_on_outlined,
                                              size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      summaryCard(
                          title: "Receipt Customization",
                          description: "Show shop shop details on the receipts",
                          widget: Icon(
                            shopController.showReportssettings.isTrue
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                          ),
                          // key: "end",
                          onPressed: (key) {
                            shopController.showReportssettings.value =
                                !shopController.showReportssettings.value;

                            shopController.onlinesellingsettings.value = false;
                            shopController.showbackupsettings.value = false;
                          }),
                      if (shopController.showReportssettings.isTrue)
                        Card(
                          elevation: 5,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                minorTitle(title: "Email", color: Colors.black),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  child: TextFormField(
                                    keyboardType: TextInputType.text,
                                    controller: shopController.emailController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                minorTitle(
                                    title: "Contact", color: Colors.black),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  child: TextFormField(
                                    keyboardType: TextInputType.phone,
                                    controller:
                                        shopController.contactController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                minorTitle(
                                    title: "Mpesa paybill/Till number",
                                    color: Colors.black),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    controller: shopController.paybillTill,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                minorTitle(
                                    title: "Paybill account number ",
                                    color: Colors.black),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  child: TextFormField(
                                    controller: shopController.paybillAcc,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                minorTitle(
                                    title: "Address", color: Colors.black),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  child: TextFormField(
                                    controller: shopController.address,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey, width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: textBtn(
                                      text: "Save",
                                      hPadding: 40,
                                      vPadding: 10,
                                      bgColor: Colors.amber,
                                      onPressed: () async {
                                        try {
                                          LoadingDialog.showLoadingDialog(
                                              context: context,
                                              title: "Updating Shop...",
                                              key: salesController.keyLoader);
                                          await ShopService()
                                              .updateShop(shopModel.id!, {
                                            "contact": shopController
                                                .contactController.text,
                                            "paybill_till":
                                                shopController.paybillTill.text,
                                            "paybill_account":
                                                shopController.paybillAcc.text,
                                            "address_receipt":
                                                shopController.address.text,
                                            "receiptemail": shopController
                                                .emailController.text,
                                          });
                                          Get.back();
                                        } catch (e) {
                                          Get.back();
                                        }
                                      }),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      summaryCard(
                          title: "Delete Shop Data",
                          description: "Erase All shop Data",
                          widget: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: (key) {
                            deleteDialog(
                                context: context,
                                message:
                                    "Are you sure you want to delete this shop data? This option is irreversible and it will erase all your shops data and you cannot recover them again.",
                                onPressed: () async {
                                  await shopController.deleteShopData(
                                      shop: shopModel);
                                });
                          }),
                      const SizedBox(height: 20),
                      summaryCard(
                          title: "Delete This Shop",
                          description: "Erase All shop Data",
                          key: "end",
                          widget: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: (key) {
                            deleteDialog(
                                context: context,
                                message:
                                    "Are you sure you want to delete this shop? This option is irreversible and it will erase all your shops data and you cannot recover them again.",
                                onPressed: () async {
                                  await shopController.deleteShop(
                                      shop: shopModel);
                                });
                          }),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          shopModel.name!,
          style:  TextStyle(color: AppColors.mainColor),
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon:  Icon(
            Icons.clear,
            color: AppColors.mainColor,
          ),
        ),
      ),
    );
  }
}

validateEmail(String email) {
  return RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(email);
}
