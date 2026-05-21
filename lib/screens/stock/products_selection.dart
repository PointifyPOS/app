import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/controllers/stockcontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/product.dart';
import 'package:pointify/models/shop.dart';
import 'package:pointify/utils/colors.dart';

class ProductSelections extends StatelessWidget {
  final Shop toShop;

  ProductSelections({
    super.key,
    required this.toShop,
  }) {
    productController.getProducts(
      type: "all",
      shop: toShop.id!,
    );
  }

  final ProductNewController productController =
      Get.find<ProductNewController>();

  final StockController stockTransferController = Get.find<StockController>();

  Widget _searchWidget() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextFormField(
        controller: productController.searchProductController,
        onChanged: (value) {
          if (value.isEmpty) {
            productController.getProducts(
              type: "all",
              shop: toShop.id!,
            );
          } else {
            productController.getProducts(
              type: "search",
              shop: toShop.id!,
              name: value,
            );
          }
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

  Widget _modeSelector() {
    return Obx(() {
      final importAll = productController.importall.value;

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  productController.importall.value = true;

                  productController.selectedTransferProducts.clear();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: importAll ? AppColors.mainColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Import All",
                      style: TextStyle(
                        color: importAll ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  productController.importall.value = false;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color:
                        !importAll ? AppColors.mainColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Select Products",
                      style: TextStyle(
                        color: !importAll ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _allProductsCard() {
    return Obx(() {
      if (!productController.importall.value) {
        return const SizedBox();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.inventory_2,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${productController.productlist.length} Products",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "All products will be transferred",
                    style: TextStyle(
                      color: Colors.grey.shade600,
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

  Widget _productTile(
    ProductDisplay product,
  ) {
    final selected = productController.selectedTransferProducts
            .indexWhere((e) => e['product'] == product.sId) !=
        -1;

    return Obx(() {
      final importAll = productController.importall.value;

      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (importAll) {
            return;
          }

          if (product.quantity! > 0 || product.type == 'service') {
            productController.addToList(product);
          } else {
            Get.snackbar(
              "Out of stock",
              "You cannot transfer products with zero stock",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? AppColors.mainColor : Colors.grey.withOpacity(.08),
            ),
          ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (product.quantity ?? 0) > 0
                                ? Colors.green.withOpacity(.08)
                                : Colors.red.withOpacity(.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 13,
                                color: (product.quantity ?? 0) > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${product.quantity} in stock",
                                style: TextStyle(
                                  color: (product.quantity ?? 0) > 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.productCategoryId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              product.productCategoryId?.name ?? "",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!importAll)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.mainColor : Colors.transparent,
                    border: Border.all(
                      color:
                          selected ? AppColors.mainColor : Colors.grey.shade400,
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
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (val) {
        productController.selectedTransferProducts.clear();

        productController.importall.value = false;

        productController.productlist.refresh();
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fb),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            "Import Products",
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            _searchWidget(),
            _modeSelector(),
            _allProductsCard(),
            Expanded(
              child: Obx(() {
                if (productController.loading.isTrue) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (productController.productlist.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 70,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products found",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (productController.importall.value) {
                  return const SizedBox();
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
          final importAll = productController.importall.value;

          final count = importAll
              ? productController.productlist.length
              : productController.selectedTransferProducts.length;

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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          importAll
                              ? "All products selected"
                              : "$count selected",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          importAll
                              ? "Entire inventory will be transferred"
                              : "Ready for transfer",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showImportConfirmation(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showImportConfirmation() {
    final importAll = productController.importall.value;

    final totalProducts = importAll
        ? productController.productlist.length
        : productController.selectedTransferProducts.length;
    final resetQuantity = productController.resetQuantity;
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
                Icons.inventory_2_outlined,
                color: AppColors.mainColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Start Import?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$totalProducts products will be imported into ${toShop.name}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  resetQuantity.value = !resetQuantity.value;
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f7fb),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: resetQuantity.value
                              ? AppColors.mainColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: resetQuantity.value
                                ? AppColors.mainColor
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: resetQuantity.value
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reset stock quantity",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Imported products will start with 0 stock",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _startImport,
                child: const Text(
                  "Start Import",
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

  Future<void> _startImport() async {
    Get.back();

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      final List<Map<String, dynamic>> products =
          productController.importall.value
              ? <Map<String, dynamic>>[]
              : productController.selectedTransferProducts
                  .map<Map<String, dynamic>>((e) {
                  final item = e["item"] as ProductDisplay;

                  final data = item.toJson();

                  data.remove("_id");
                  data.remove("__v");

                  data["quantity"] = e["quantity"];
                  data['maxDiscount'] =
                      item.maxDiscount == 'null' ? 0 : item.maxDiscount;
                  data['minSellingPrice'] =
                      item.minSellingPrice == 'null' ? 0 : item.minSellingPrice;

                  return data;
                }).toList();

      final response = await productController.copyFromOthershop(
        products,
        userController.currentUser.value!.primaryShop!,
        toShop,
      );

      Get.back();

      Get.off(
        () => _ImportResultPage(
          imported: response["imported"] ?? 0,
          failed: response["failed"] ?? 0,
          total: response["total"] ?? 0,
        ),
      );
    } catch (e) {
      Get.back();

      Get.snackbar(
        "Import Failed",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _summaryCard(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xfff5f7fb),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
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

  Widget _progressBox(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportResultPage extends StatelessWidget {
  final int imported;
  final int failed;
  final int total;

  const _ImportResultPage({
    required this.imported,
    required this.failed,
    required this.total,
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
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Import Completed",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "$imported products imported successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                if (failed > 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      "$failed products skipped because they already exist",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _resultCard(
                        "Imported",
                        "$imported",
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultCard(
                        "Skipped",
                        "$failed",
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultCard(
                        "Total",
                        "$total",
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
              fontSize: 22,
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
