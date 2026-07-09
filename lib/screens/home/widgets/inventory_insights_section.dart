import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/screens/product/product_insightful.dart';
import 'package:pointify/screens/product/products_page.dart';
import 'package:pointify/utils/colors.dart';

// ignore: must_be_immutable
class InventoryInsightsMinimal extends StatelessWidget {
  final int runningLow;
  final int outOfStock;
  final int dormant;
  final int fastMovingCount;
  final VoidCallback? onTapFastMoving;

  InventoryInsightsMinimal({
    super.key,
    required this.runningLow,
    required this.outOfStock,
    required this.dormant,
    required this.fastMovingCount,
    this.onTapFastMoving,
  });
  ProductNewController productNewController = Get.find<ProductNewController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Inventory Insights ",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainColor,
                  ),
                ),
                TextSpan(
                  text: "(click to view more)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _item("Running low", runningLow, Colors.orange),
                const SizedBox(width: 8),
                _item("Out of stock", outOfStock, Colors.red),
                const SizedBox(width: 8),
                _item("Fast moving", fastMovingCount, Colors.green),
                const SizedBox(width: 8),
                _item("Dormant", dormant, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    String title,
    int value,
    Color color,
  ) {
    return InkWell(
      onTap: () async {
        String type = "";
        String stockMode = "";

        // FAST MOVING
        if (title == "Fast moving") {
          type = "fastmoving";

          productNewController.selectedSortOrderSearch.value = type;

          productNewController.getProducts(
              type: type,
              shop: userController.currentUser.value?.primaryShop?.id ?? "",
              page: 1,
              limit: 40,
              refresh: true);

          Get.to(
            () => ProductInsightPage(
              type: type,
            ),
          );

          return;
        }

        // DORMANT
        if (title == "Dormant") {
          type = "dormant";

          productNewController.selectedSortOrderSearch.value = type;

          productNewController.getProducts(
              type: type,
              shop: userController.currentUser.value?.primaryShop?.id ?? "",
              page: 1,
              limit: 40,
              refresh: true);

          Get.to(
            () => ProductInsightPage(
              type: type,
            ),
          );

          return;
        }

        // OUT OF STOCK
        if (title == "Out of stock") {
          stockMode = "outofstock";
        }

        // RUNNING LOW
        if (title == "Running low") {
          stockMode = "runninglow";
        }

        productNewController.stockMode.value = stockMode;

        productNewController.getProducts(
            stockMode: stockMode,
            shop: userController.currentUser.value?.primaryShop?.id ?? "",
            page: 1,
            limit: 40,
            refresh: true);

        Get.to(() => ProductPage());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(
            30,
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: "$value ",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
