import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/inapp_purchases.dart';
import 'package:pointify/controllers/shopcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/package.dart';
import 'package:pointify/models/shop.dart';
import 'package:pointify/widgets/major_title.dart';

import '../../functions/functions.dart';
import '../../utils/colors.dart';
import '../../utils/themer.dart';
import '../../widgets/alert.dart';
import '../../widgets/minor_title.dart';

class ShopsToRenew extends StatelessWidget {
  Package plan;
  Shop? shop;
  ShopsToRenew({super.key, required this.plan, this.shop});
  ShopController shopController = Get.find<ShopController>();
  InappPurchasesController inappPurchasesController =
      Get.find<InappPurchasesController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Choose Shops/Branches To Renew',
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(children: [
            Expanded(
              child: Obx(() {
                return shopController.gettingShopsLoad.isTrue
                    ? const Center(child: CircularProgressIndicator())
                    : shopController.expiredShops.isEmpty
                        ? Center(
                            child: majorTitle(
                                title: "You do not have expired shops yet",
                                color: Colors.black,
                                size: 16.0),
                          )
                        : Column(
                            children: [
                              Center(
                                child: Text(
                                  "Maximum number of shops: ${plan.maxShops}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                    itemCount:
                                        shopController.expiredShops.length,
                                    itemBuilder: (context, index) {
                                      Shop shopBody = shopController
                                          .expiredShops
                                          .elementAt(index);
                                      return InkWell(
                                        onTap: () {
                                          if (shopController.shopsRenew
                                                  .indexWhere((element) =>
                                                      element.id ==
                                                      shopBody.id) ==
                                              -1) {
                                            if (shopController
                                                    .shopsRenew.length >=
                                                plan.maxShops!) {
                                              generalAlert(
                                                title: "Error",
                                                message:
                                                    "Maximum number of shops reached",
                                              );
                                              return;
                                            }
                                            shopController.shopsRenew
                                                .add(shopBody);
                                          } else {
                                            shopController.shopsRenew.removeAt(
                                                shopController.shopsRenew
                                                    .indexWhere((element) =>
                                                        element.id ==
                                                        shopBody.id));
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            elevation: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        majorTitle(
                                                            title:
                                                                "${shopBody.name}",
                                                            color: Colors.black,
                                                            size: 16.0),
                                                        const SizedBox(
                                                            height: 10),
                                                        Text(
                                                          "Location: ${shopBody.location}",
                                                          maxLines: 2,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Obx(
                                                    () => Checkbox(
                                                        value: shopController
                                                                    .shopsRenew
                                                                    .indexWhere((element) =>
                                                                        element
                                                                            .id ==
                                                                        shopBody
                                                                            .id) !=
                                                                -1
                                                            ? true
                                                            : false,
                                                        onChanged: (value) {}),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ],
                          );
              }),
            )
          ]),
        ),
        bottomNavigationBar: Obx(() => BottomAppBar(
              color: Colors.white,
              height: shopController.shopsRenew.isEmpty ||
                      MediaQuery.of(context).size.width > 600
                  ? 0
                  : kBottomNavigationBarHeight * 1.8,
              child: Obx(() {
                return shopController.shopsRenew.isEmpty ||
                        MediaQuery.of(context).size.width > 600
                    ? Container(
                        height: 0,
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          onTap: (shopController.isCurrentPackage(plan) &&
                                  shopController.checkDaysRemaining(
                                          shop: shop) >
                                      0)
                              ? null
                              : () {
                                  if (Platform.isIOS) {
                                    inappPurchasesController
                                        .buyNonConsumableProduct(plan.id!);
                                  } else {
                                    showModalBottomSheet(
                                        context: Get.context!,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        builder: (context) => Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom),
                                              child: Container(
                                                color: Colors.white,
                                                height: MediaQuery.of(context)
                                                        .copyWith()
                                                        .size
                                                        .height *
                                                    0.50,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Center(
                                                      child: Text(
                                                        "Pay to extend ${shop != null ? shop?.name : userController.currentUser.value!.primaryShop!.name} usage",
                                                        style: const TextStyle(
                                                            fontSize: 21),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "Package details",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          userController
                                                                      .currentUser
                                                                      .value
                                                                      ?.primaryShop!
                                                                      .currency !=
                                                                  "KES"
                                                              ? " Amount : USD ${plan.amountusd!}"
                                                              : " Amount : ${htmlPrice(plan.amount)}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          "Duration : ${plan.durationValue} days",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                        ),
                                                        if (userController
                                                                .currentUser
                                                                .value
                                                                ?.primaryShop!
                                                                .currency ==
                                                            "KES")
                                                          RadioListTile(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            title: Row(
                                                              children: [
                                                                Image.asset(
                                                                  "assets/images/mpesalogo.png",
                                                                  width: 50,
                                                                ),
                                                                const Text(""),
                                                              ],
                                                            ),
                                                            value: "mpesa",
                                                            groupValue: "mpesa",
                                                            onChanged:
                                                                (value) {},
                                                          ),
                                                        if (userController
                                                                .currentUser
                                                                .value
                                                                ?.primaryShop!
                                                                .currency !=
                                                            "KES")
                                                          RadioListTile(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            title: const Row(
                                                              children: [
                                                                Text(
                                                                    "Pay with Stripe"),
                                                                Text(""),
                                                              ],
                                                            ),
                                                            value: "mpesa",
                                                            groupValue: "mpesa",
                                                            onChanged:
                                                                (value) {},
                                                          ),
                                                        if (userController
                                                                .currentUser
                                                                .value
                                                                ?.primaryShop!
                                                                .currency ==
                                                            "KES")
                                                          TextFormField(
                                                            controller:
                                                                userController
                                                                    .phoneController,
                                                            validator: (value) {
                                                              if (value ==
                                                                      null ||
                                                                  value
                                                                      .isEmpty) {
                                                                return 'Please enter mpesa number';
                                                              }
                                                              return null;
                                                            },
                                                            keyboardType:
                                                                TextInputType
                                                                    .emailAddress,
                                                            decoration: ThemeHelper()
                                                                .textInputDecorationDesktop(
                                                                    'Mpesa Phone Number',
                                                                    'Enter mpesa number'),
                                                          ),
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Center(
                                                          child: Obx(
                                                            () => shopController
                                                                    .subscribing
                                                                    .isTrue
                                                                ? const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  )
                                                                : InkWell(
                                                                    onTap: () {
                                                                      Shop? shopp = shop ??
                                                                          userController
                                                                              .currentUser
                                                                              .value
                                                                              ?.primaryShop;

                                                                      var currency = shopp?.currency ==
                                                                              "KES"
                                                                          ? "mpesa"
                                                                          : "stripe";
                                                                      shopController.subscribe(
                                                                          shopp!,
                                                                          package:
                                                                              plan,
                                                                          type:
                                                                              currency);
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              25,
                                                                          vertical:
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .amber,
                                                                        borderRadius:
                                                                            BorderRadius.circular(50),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.amber,
                                                                            width: 2),
                                                                      ),
                                                                      child: minorTitle(
                                                                          title:
                                                                              "Pay now",
                                                                          color:
                                                                              AppColors.mainColor),
                                                                    )),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ));
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 3, color: AppColors.mainColor),
                                borderRadius: BorderRadius.circular(40)),
                            child: Center(
                              child: Platform.isIOS &&
                                      inappPurchasesController.loading.isTrue
                                  ? minorTitle(
                                      title: "Please wait...",
                                      color: AppColors.mainColor,
                                      size: 18.0)
                                  : Platform.isIOS &&
                                          inappPurchasesController
                                              .loading.isFalse
                                      ? minorTitle(
                                          title: "Proceed",
                                          color: AppColors.mainColor,
                                          size: 18.0)
                                      : majorTitle(
                                          title: "Proceed",
                                          color: AppColors.mainColor,
                                          size: 18.0),
                            ),
                          ),
                        ),
                      );
              }),
            )));
  }
}
