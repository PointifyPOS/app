import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/main.dart';
import 'package:pointify/utils/colors.dart';
import 'package:pointify/widgets/minor_title.dart';
import 'package:pointify/widgets/shop_list_bottomsheet.dart';

import '../../controllers/plancontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../functions/functions.dart';
import '../../models/package.dart';
import '../../models/shop.dart';
import '../../widgets/major_title.dart';
import 'ShopsRenew.dart';

class ExtendUsage extends StatelessWidget {
  final Shop? shop;
  ExtendUsage({
    super.key,
    this.shop,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      userController.phoneController.text =
          userController.currentUser.value!.phone ?? "";
      planController.getPlans();
    });
  }

  final ShopController shopController = Get.find<ShopController>();
  final PlanController planController = Get.find<PlanController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.clear,
              color: AppColors.mainColor,
            )),
        title: Text(
          "Extend usage",
          style: TextStyle(color: AppColors.mainColor),
        ),
      ),
      body: Column(
        children: [
          shop != null
              ? Column(
                  children: [
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10),
                        child: Text(
                            "Extend Usage for ${shop!.name} for you to be able to switch to this shop.",
                            style: const TextStyle(
                              fontSize: 20,
                            ))),
                    const Divider(
                      thickness: 2,
                    ),
                  ],
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      majorTitle(
                          title: "Current Shop",
                          color: Colors.black,
                          size: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() {
                            return minorTitle(
                                title: userController
                                            .currentUser.value!.primaryShop ==
                                        null
                                    ? ""
                                    : userController
                                        .currentUser.value!.primaryShop!.name,
                                color: AppColors.mainColor);
                          }),
                          Obx(
                            () => InkWell(
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
                          )
                        ],
                      ),
                    ],
                  ),
                ),
          Expanded(
            child: Obx(
              () => planController.isLoadingPackages.isTrue
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemCount: planController.plans.length,
                      itemBuilder: (BuildContext c, int i) {
                        Package plan = planController.plans[i];
                        return _usageCard(plan);
                      }),
            ),
          )
        ],
      ),
    );
  }

  Widget _usageCard(Package plan) {
    return Obx(() {
      final bool isActive = shopController.isCurrentPackage(plan) &&
          shopController.checkDaysRemaining(shop: shop) > 0;

      final int daysRemaining = shopController.checkDaysRemaining(shop: shop);

      final String price = (plan.priceText ?? "").trim();
      final String displayPrice =
          price.toLowerCase().startsWith("from") ? price : "From $price";

      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive
            ? null
            : () {
                shopController.shopsRenew.clear();
                shopController.getShops();
                Get.to(() => ShopsToRenew(plan: plan, shop: shop));
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.mainColor.withOpacity(.25)
                  : Colors.black.withOpacity(.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(.12)
                          : AppColors.mainColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isActive ? "Active" : "Subscribe",
                      style: TextStyle(
                          color: isActive
                              ? Colors.green.shade700
                              : AppColors.mainColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.shopText ?? "",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(.52),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "From ",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: plan.priceText ?? "",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 6),
                Text(
                  "$daysRemaining days remaining",
                  style: TextStyle(
                    color: Colors.red.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
