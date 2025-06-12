import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/main.dart';
import 'package:pointify/screens/product/components/service_card.dart';
import 'package:pointify/utils/constants.dart';
import 'package:pointify/widgets/no_items_found.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/productcontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../models/product.dart';
import '../../services/end_points.dart';
import '../../utils/colors.dart';
import '../../utils/helper.dart';
import '../../widgets/major_title.dart';
import '../../widgets/minor_title.dart';
import 'components/product_card.dart';

class ProductPage extends StatelessWidget {
  final Function? function;
  String? type;
  ProductPage({super.key, this.function, this.type = "all"}) {
    productController.searchProductController.text = "";
  }

  final ShopController createShopController = Get.find<ShopController>();
  final ProductController productController = Get.find<ProductController>();
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
                showBottomSheet(context);
              },
              icon: const Icon(
                Icons.download,
                color: AppColors.mainColor,
              )),
          IconButton(
              onPressed: () async {
                productController.getProductsBySort(type: "all");
              },
              icon: const Icon(
                Icons.refresh,
                color: AppColors.mainColor,
              )),
          IconButton(
              onPressed: () async {
                Share.share(
                  '$storeurl?shopid=${userController.currentUser.value?.primaryShop?.id}&adminid=${userController.currentUser.value?.id}',
                  subject: "Share Inventory",
                  sharePositionOrigin: Rect.fromLTWH(0, 0, 0, 0),
                );
              },
              icon: const Icon(
                Icons.share,
                color: AppColors.mainColor,
              ))
        ],
        title: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  majorTitle(
                      title: "Products", color: Colors.black, size: 16.0),
                  minorTitle(
                      title:
                          "${userController.currentUser.value?.primaryShop?.name}",
                      color: Colors.grey)
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: productController.searchProductController,
                    onChanged: (value) {
                      productController.filterProductsLocally(
                          productController.searchProductController.text);
                    },
                    decoration: InputDecoration(
                      suffixIconConstraints:
                          const BoxConstraints(maxWidth: 100),
                      suffixIcon: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              productController.getProductsBySort(
                                  type: productController
                                      .selectedSortOrder.value
                                      .toLowerCase(),
                                  text: productController
                                      .searchProductController.text,
                                  page: 1,
                                  limit: 50);
                            },
                            child: const Text(
                              "Search",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                      hintText: "Quick Search Item",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      // productController.scanQR(
                      //     type: "product", context: context);
                    },
                    icon: const Icon(Icons.qr_code))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sort List By"),
                if (userController.currentUser.value!.primaryShop!.production ==
                    true)
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) {
                            return SimpleDialog(
                              children: List.generate(
                                  Constants().productionOrder.length,
                                  (index) => SimpleDialogOption(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          productController
                                                  .selectedSortOrder.value =
                                              Constants()
                                                  .productionOrder
                                                  .elementAt(index);
                                          productController.getProductsBySort(
                                              type: productController
                                                  .selectedSortOrder.value
                                                  .toLowerCase(),
                                              text: productController
                                                  .searchProductController.text,
                                              sort: productController
                                                  .selectedSortOrderSearch
                                                  .value);
                                        },
                                        child: Text(
                                          Constants()
                                              .productionOrder
                                              .elementAt(index),
                                        ),
                                      )),
                            );
                          });
                    },
                    child: Row(
                      children: [
                        Obx(() {
                          return Text(productController.selectedSortOrder.value,
                              style:
                                  const TextStyle(color: AppColors.mainColor));
                        }),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.mainColor,
                        )
                      ],
                    ),
                  ),
                if (userController.currentUser.value!.primaryShop!.production ==
                    false)
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) {
                            return SimpleDialog(
                              children: List.generate(
                                  Constants().sortOrder.length,
                                  (index) => SimpleDialogOption(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          productController
                                                  .selectedSortOrder.value =
                                              Constants()
                                                  .sortOrder
                                                  .elementAt(index);
                                          productController
                                                  .selectedSortOrderSearch
                                                  .value =
                                              Constants()
                                                  .sortOrderList
                                                  .elementAt(index);
                                          productController.getProductsBySort(
                                              type: "",
                                              text: productController
                                                  .searchProductController.text,
                                              sort: productController
                                                  .selectedSortOrderSearch
                                                  .value);
                                        },
                                        child: Text(
                                          Constants()
                                              .sortOrder
                                              .elementAt(index),
                                        ),
                                      )),
                            );
                          });
                    },
                    child: Row(
                      children: [
                        Obx(() {
                          return Text(productController.selectedSortOrder.value,
                              style:
                                  const TextStyle(color: AppColors.mainColor));
                        }),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.mainColor,
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              return productController.loadingproducts.value
                  ? const Center(child: CircularProgressIndicator())
                  : productController.filteredProducts.isEmpty
                      ? noItemsFound(context, true)
                      : ListView.builder(
                          itemCount: productController.filteredProducts.length,
                          controller: productController.scrollController,
                          itemBuilder: ((context, index) {
                            Product productModel = productController
                                .filteredProducts
                                .elementAt(index);
                            if (productModel.type == "service") {
                              return serviceCard(
                                  type: type,
                                  product: productModel,
                                  function: (Product product) {
                                    return function!(product);
                                  });
                            }
                            return productCard(
                                product: productModel,
                                type: type,
                                function: function != null
                                    ? (Product product) {
                                        return function!(product);
                                      }
                                    : null);
                          }),
                        );
            }),
          ),
          Obx(() => productController.loadingMoreProducts.isTrue
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : const SizedBox.shrink()),
        ],
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
