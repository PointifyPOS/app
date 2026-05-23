import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/product.dart';
import 'package:pointify/models/shop.dart';
import 'package:pointify/utils/colors.dart';

class TransferProductsPage extends StatelessWidget {
  final Shop toShop;

  TransferProductsPage({
    super.key,
    required this.toShop,
  }) {
    productController.selectedTransferProducts.clear();
    productController.getProducts(
      type: "all",
      shop: userController.currentUser.value!.primaryShop!.id!,
    );
  }

  final ProductNewController productController =
      Get.find<ProductNewController>();

  Widget _searchWidget() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextFormField(
        controller: productController.searchProductController,
        onChanged: (value) {
          productController.getProducts(
            type: value.isEmpty ? "all" : "search",
            shop: userController.currentUser.value!.primaryShop!.id!,
            name: value,
          );
        },
        decoration: InputDecoration(
          hintText: "Search products...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.mainColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _productTile(
    ProductDisplay product,
  ) {
    return Obx(() {
      final selectedIndex =
          productController.selectedTransferProducts.indexWhere(
        (e) => e["product"] == product.sId,
      );

      final selected = selectedIndex != -1;

      int quantity = 1;

      if (selected) {
        quantity = productController.selectedTransferProducts[selectedIndex]
            ["quantity"];
      }

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? AppColors.mainColor : Colors.grey.withOpacity(.08),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(
                14,
              ),
              onTap: () {
                if ((product.quantity ?? 0) <= 0) {
                  Get.snackbar(
                    "Out of stock",
                    "This product has no stock",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );

                  return;
                }

                productController.addToList(product);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (product.quantity ?? 0) > 0
                                ? Colors.green.withOpacity(.08)
                                : Colors.red.withOpacity(.08),
                            borderRadius: BorderRadius.circular(
                              30,
                            ),
                          ),
                          child: Text(
                            "${product.quantity} in stock",
                            style: TextStyle(
                              color: (product.quantity ?? 0) > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? AppColors.mainColor : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.mainColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (quantity > 1) {
                          productController
                                  .selectedTransferProducts[selectedIndex]
                              ["quantity"]--;

                          productController.selectedTransferProducts.refresh();
                        }
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: quantity.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final entered = int.tryParse(value) ?? 1;

                          int finalQty = entered;

                          if (finalQty < 1) {
                            finalQty = 1;
                          }

                          if (finalQty > (product.quantity ?? 0)) {
                            finalQty = product.quantity?.toInt() ?? 0;
                          }

                          productController
                                  .selectedTransferProducts[selectedIndex]
                              ["quantity"] = finalQty;

                          productController.selectedTransferProducts.refresh();
                        },
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (quantity < (product.quantity ?? 0)) {
                          productController
                                  .selectedTransferProducts[selectedIndex]
                              ["quantity"]++;

                          productController.selectedTransferProducts.refresh();
                        }
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(.08),
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showTransferConfirmation() {
    final totalItems = productController.selectedTransferProducts.fold<int>(
      0,
      (sum, item) => sum + ((item["quantity"] ?? 0) as int),
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sync_alt,
                color: AppColors.mainColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Start Transfer?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$totalItems items will be transferred to ${toShop.name}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                onPressed: _startTransfer,
                child: const Text(
                  "Transfer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTransfer() async {
    Get.back();

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      final response = await productController.submitTranster(
        toShop: toShop,
        context: Get.context,
      );

      Get.back();

      Get.off(
        () => _TransferResultPage(
          transferred: response["transferred"] ?? 0,
          totalItems: response["totalItems"] ?? 0,
        ),
      );
    } catch (e) {
      Get.back();

      Get.snackbar(
        "Transfer Failed",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (_) {
        productController.selectedTransferProducts.clear();
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fb),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            "Transfer Products",
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            _searchWidget(),
            Expanded(
              child: Obx(() {
                if (productController.loading.isTrue) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (productController.productlist.isEmpty) {
                  return Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ),
                  itemCount: productController.productlist.length,
                  itemBuilder: (context, index) {
                    return _productTile(
                      productController.productlist[index],
                    );
                  },
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          final count = productController.selectedTransferProducts.length;

          if (count == 0) {
            return const SizedBox();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  onPressed: _showTransferConfirmation,
                  child: Text(
                    "Transfer $count Products",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TransferResultPage extends StatelessWidget {
  final int transferred;
  final int totalItems;

  const _TransferResultPage({
    required this.transferred,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Transfer Completed",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$transferred products transferred successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _resultCard(
                        "Products",
                        "$transferred",
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultCard(
                        "Items",
                        "$totalItems",
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
