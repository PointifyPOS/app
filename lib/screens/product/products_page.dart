import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/controllers/product_controller_new.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/productcategory.dart';
import 'package:pointify/screens/product/barcode_scanner.dart';
import 'package:pointify/screens/product/components/service_card.dart';
import 'package:pointify/utils/constants.dart';
import 'package:pointify/widgets/no_items_found.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/shopcontroller.dart';
import '../../models/product.dart';
import '../../services/end_points.dart';
import '../../utils/colors.dart';
import '../../utils/helper.dart';
import '../../widgets/major_title.dart';
import 'components/product_card.dart';

class ProductTopSection extends StatelessWidget {
  final ProductNewController productController;
  final String? type;
  final VoidCallback onCategoryTap;
  final VoidCallback onQrTap;

  const ProductTopSection({
    super.key,
    required this.productController,
    required this.type,
    required this.onCategoryTap,
    required this.onQrTap,
  });
  Widget categoryMiniChip({
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.mainColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 15,
              color: AppColors.mainColor,
            ),
            const SizedBox(width: 5),
            Text(
              "Categories",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        4,
      ),
      child: Column(
        children: [
          // SEARCH
          TextFormField(
            controller: productController.searchProductController,
            onChanged: (value) async {
              productController.filterProductsLocally(value);

              if (productController.productlist.isEmpty &&
                  value.trim().isNotEmpty) {
                await productController.getProducts(
                  type: "all",
                  name: value,
                  shop: userController.currentUser.value?.primaryShop?.id ?? "",
                  page: 1,
                  limit: 40,
                );
              }
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.mainColor,
                ),
              ),

              // SEARCH + QR
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  if (type != "salemodule")
                    IconButton(
                      onPressed: onQrTap,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FILTERS + STATS
          SizedBox(
            height: 30,
            child: Obx(
              () => Center(
                child: Row(
                  children: [
                    Expanded(
                      child: categoryMiniChip(
                        onTap: onCategoryTap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: inventoryMiniStat(
                        title: "Available",
                        value:
                            "${productController.productStats['instock'] ?? 0}",
                        color: Colors.green,
                        selected:
                            productController.stockMode.value == "instock",
                        onTap: () async {
                          if (productController.stockMode.value == "instock") {
                            productController.stockMode.value = "";
                          } else {
                            productController.stockMode.value = "instock";
                          }

                          await productController.getProducts(
                            refresh: true,
                            shop: userController
                                    .currentUser.value?.primaryShop?.id ??
                                "",
                            stockMode: productController.stockMode.value,
                            page: 1,
                            limit: 40,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: inventoryMiniStat(
                        title: "Out",
                        value:
                            "${productController.productStats['outofstock'] ?? 0}",
                        color: Colors.red,
                        selected:
                            productController.stockMode.value == "outofstock",
                        onTap: () async {
                          if (productController.stockMode.value ==
                              "outofstock") {
                            productController.stockMode.value = "";
                          } else {
                            productController.stockMode.value = "outofstock";
                          }

                          await productController.getProducts(
                            refresh: true,
                            shop: userController
                                    .currentUser.value?.primaryShop?.id ??
                                "",
                            stockMode: productController.stockMode.value,
                            page: 1,
                            limit: 40,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inventoryMiniStat({
    required String title,
    required String value,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? color : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterChip({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.mainColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ProductPage extends StatelessWidget {
  final Function? function;
  String? type;
  bool? refetch;
  ProductPage({super.key, this.function, this.type = "all", this.refetch}) {
    productController.searchProductController.text = "";
    productController.getProductCategiories();
    if (refetch == true) {
      productController.getProducts(
        shop: userController.currentUser.value?.primaryShop?.id ?? "",
        stockMode: "instock",
        page: 1,
        limit: 40,
      );
    }
  }

  final ShopController createShopController = Get.find<ShopController>();
  final ProductNewController productController =
      Get.put(ProductNewController());

  void showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Obx(() {
                  List<ProductCategory> categories = [
                    ProductCategory(name: "All"),
                    ...productController.productCategories,
                  ];

                  return GridView.builder(
                    itemCount: categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 60,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, index) {
                      final category = categories[index];

                      final isSelected =
                          productController.selectedCategory.value == category;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Get.back();

                          productController.selectedCategory.value = category;

                          productController.getProducts(
                            type: 'all',
                            category: category,
                            page: 1,
                            limit: 50,
                            shop: userController
                                    .currentUser.value?.primaryShop?.id ??
                                "",
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.mainColor
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.mainColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category.name ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void showSortDialog(BuildContext context) {
    final titles = Constants().sortOrder;
    final values = Constants().sortOrderList;

    final itemCount =
        titles.length > values.length ? values.length : titles.length;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sort Products",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: List.generate(
                      itemCount,
                      (index) {
                        final title = titles[index];

                        final value = values[index];

                        final isSelected =
                            productController.selectedSortOrder.value == title;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: isSelected
                              ? AppColors.mainColor.withOpacity(0.1)
                              : null,
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                isSelected ? AppColors.mainColor : Colors.grey,
                          ),
                          title: Text(title),
                          onTap: () {
                            Get.back();

                            productController.selectedSortOrder.value = title;

                            productController.selectedSortOrderSearch.value =
                                value;

                            productController.getProducts(
                              type: "",
                              name: productController
                                  .searchProductController.text,
                              shop: userController
                                      .currentUser.value?.primaryShop?.id ??
                                  "",
                              sort: value,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget statItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0.3,
        titleSpacing: 0.0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Get.back();
            productController.filterProductsLocally('');
            productController.searchProductController.clear();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                productController.getProducts(
                    type: "all",
                    shop:
                        userController.currentUser.value?.primaryShop?.id ?? "",
                    stockMode: productController.stockMode.value);
              },
              icon: Icon(
                Icons.refresh,
                color: AppColors.mainColor,
              )),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.mainColor,
            ),
            onSelected: (value) async {
              if (value == "sort") {
                showSortDialog(context);
              } else if (value == "download") {
                showBottomSheet(context);
              } else if (value == "share") {
                Share.share(
                  '$storeurl?shopid=${userController.currentUser.value?.primaryShop?.id}&adminid=${userController.currentUser.value?.id}',
                  subject: "Share Inventory",
                  sharePositionOrigin: const Rect.fromLTWH(0, 0, 0, 0),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "sort",
                child: Row(
                  children: [
                    Icon(Icons.swap_vert),
                    SizedBox(width: 10),
                    Text("Sort"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "download",
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 10),
                    Text("Download"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "share",
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 10),
                    Text("Share"),
                  ],
                ),
              ),
            ],
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              majorTitle(title: "Products", color: Colors.black, size: 16.0),
              Text(
                "${userController.currentUser.value?.primaryShop?.name}",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          ProductTopSection(
            productController: productController,
            type: type,
            onCategoryTap: () {
              showCategorySheet(context);
            },
            onQrTap: () async {
              Get.to(
                () => BarcodeScannerPage(
                  popAfterScan: true,
                  onScanned: (barcode) async {
                    await productController.getProducts(
                      type: "search",
                      barcodeId: barcode,
                      page: 1,
                      shop: userController.currentUser.value?.primaryShop?.id ??
                          "",
                      limit: 50,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (productController.loading.value &&
                  productController.productlist.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (productController.productlist.isEmpty) {
                return noItemsFound(context, true);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await productController.getProducts(
                    type: "all",
                    page: 1,
                    limit: 40,
                    shop:
                        userController.currentUser.value?.primaryShop?.id ?? "",
                  );
                },
                child: ListView.builder(
                  controller: productController.scrollController,
                  itemCount: productController.productlist.length + 1,
                  itemBuilder: (context, index) {
                    // LOADING MORE
                    if (index == productController.productlist.length) {
                      return Obx(() => productController.loadingMore.isTrue
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox.shrink());
                    }

                    final productModel = productController.productlist[index];

                    if (productModel.type == "service") {
                      return serviceCard(
                        type: type,
                        product: productModel.toProduct(),
                        function: function != null
                            ? (Product p) => function!(p)
                            : null,
                      );
                    }

                    return productCard(
                      product: productModel.toProduct(),
                      type: type,
                      function:
                          function != null ? (Product p) => function!(p) : null,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget filterButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.mainColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  showBottomSheet(
    BuildContext context,
  ) {
    return showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        builder: (_) {
          return Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height * 0.5,
            margin: EdgeInsets.only(
              left: 0,
            ),
            child: Column(
              children: [
                Container(
                  color: AppColors.mainColor.withOpacity(0.1),
                  width: double.infinity,
                  child: const ListTile(
                    title: Text("Choose what to download"),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  onTap: () async {
                    Get.back();
                    generateReportAlert(context, 'all');
                  },
                  title: const Text("All"),
                ),
                ListTile(
                  leading: const Icon(Icons.hourglass_empty),
                  onTap: () async {
                    generateReportAlert(context, 'outofstock');
                  },
                  title: const Text("Out of stock"),
                ),
                ListTile(
                  leading: const Icon(Icons.downhill_skiing_sharp),
                  onTap: () async {
                    generateReportAlert(context, 'runninglow');
                  },
                  title: const Text("Running Low on Stock"),
                ),
                ListTile(
                  leading: const Icon(Icons.data_exploration),
                  onTap: () async {
                    generateReportAlert(context, 'expired');
                  },
                  title: const Text("Expired"),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.clear,
                    color: Colors.red,
                  ),
                  onTap: () {
                    Get.back();
                  },
                  title: const Text("Cancel "),
                ),
              ],
            ),
          );
        });
  }
}
