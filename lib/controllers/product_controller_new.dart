import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/product.dart';
import 'package:pointify/models/productcategory.dart';
import 'package:pointify/models/shop.dart';
import 'package:pointify/services/firestore_files_access_service.dart';
import 'package:pointify/services/product_service.dart';
import 'package:pointify/widgets/alert.dart';
import 'package:pointify/widgets/loading_dialog.dart';
import 'package:pointify/widgets/snackbars.dart';

class ProductNewController extends GetxController {
  RxList<ProductDisplay> productlist = RxList([]);

  final GlobalKey<State> _keyLoader = GlobalKey<State>();
  RxMap<String, dynamic> productmeta = RxMap({
    "count": 0,
    "totalPages": 0,
    "currentPage": 1,
  });
  TextEditingController descriptionController = TextEditingController();
  RxList<ProductDisplay> originalProducts = RxList([]);
  RxMap<String, dynamic> productStats = RxMap({});
  TextEditingController categoryName = TextEditingController();
  RxBool resetQuantity = RxBool(false);
  RxString selectedSortOrderSearch = RxString("all");
  Rxn<ProductCategory> selecteProductCategoty = Rxn(null);

  RxList<ProductCategory> productCategories = RxList([]);
  RxBool loading = RxBool(false);
RxBool isSearching = false.obs;
  RxBool loadingMore = RxBool(false);
  var filteredProducts = <ProductDisplay>[].obs;
  RxString selectedSortOrder = RxString("All");

  RxBool loadingproductCategories = RxBool(false);
  RxBool hasMore = RxBool(true);

  RxBool transferingproducts = RxBool(false);

  RxBool importall = RxBool(false);

  final ScrollController scrollController = ScrollController();

  RxList<Map<String, dynamic>> selectedTransferProducts = RxList([]);

  TextEditingController searchProductController = TextEditingController();

  RxString stockMode = RxString("instock");

  RxString selectedSort = RxString("");

  Rxn<ProductCategory> selectedCategory = Rxn(null);

  RxMap<String, dynamic> importProgressData = RxMap({
    "loading": false,
    "imported": 0,
    "failed": 0,
    "total": 0,
    "progress": 0.0,
    "currentProduct": "",
    "completed": false,
  });

  @override
  void onInit() {
    scrollController.addListener(
      _scrollListener,
    );

    super.onInit();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        loadingMore.isFalse &&
        hasMore.isTrue) {
      loadMoreProducts();
    }
  }

  Future<Map<String, dynamic>> updateBarcode({
    required String productId,
    required String barcode,
  }) async {
    try {
      var response = await ProductService.updateBarcode(
        {
          "barcode": barcode,
        },
        productId,
      );

      if (response["error"] != null) {
        return {
          "success": false,
          "message": response["error"],
        };
      }

      int index = productlist.indexWhere(
        (e) => e.sId == productId,
      );

      if (index != -1) {
        productlist[index].barcode = barcode;
      }

      int filteredIndex = filteredProducts.indexWhere(
        (e) => e.sId == productId,
      );

      if (filteredIndex != -1) {
        filteredProducts[filteredIndex].barcode = barcode;
      }

      productlist.refresh();
      filteredProducts.refresh();

      return {
        "success": true,
        "message": "Barcode updated successfully",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Failed to update barcode",
      };
    }
  }

  deleteProduct({required Product product}) async {
    var i = productlist.indexWhere((element) => element.sId == product.sId);
    productlist.removeAt(i);
    await ProductService.deleteProduct(product.sId!);
    if (product.images != null && product.images!.isNotEmpty) {
      for (int i = 0; i < product.images!.length; i++) {
        FirestoreFilesAccess().deleteFileFromPath("${product.sId!}_$i");
      }
    }
  }

  void addToList(
    ProductDisplay productModel, {
    type = "",
  }) {
    var index = selectedTransferProducts.indexWhere(
      (element) => element["product"] == productModel.sId,
    );

    if (index == -1) {
      selectedTransferProducts.add({
        "product": productModel.sId,
        "quantity": type == "import" ? productModel.quantity : 1,
        "name": productModel.name,
        "item": productModel
      });
    } else {
      selectedTransferProducts.removeAt(index);
    }

    productlist.refresh();

    selectedTransferProducts.refresh();
  }

  Future<void> getProductStats(
    String shop,
  ) async {
    try {
      var response = await ProductService.getProductStats(shop);
      if (response == null) return;
      productStats.value = response["stats"] ?? {};

      productStats["fastmoving"] = response["fastmoving"] ?? [];
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> refreshProducts({
    required String shop,
  }) async {
    hasMore.value = true;

    await getProducts(
      shop: shop,
      refresh: true,
    );
  }

  void createCategory() async {
    LoadingDialog.showLoadingDialog(
      context: Get.context!,
      title: "Adding please wait...",
      key: _keyLoader,
    );
    if (categoryName.text.isEmpty) {
      showSnackBar(message: "enter category name", color: Colors.red);
      return;
    }
    var response = await ProductService.createCategory({
      "name": categoryName.text,
      "admin": userController.currentUser.value!.id!
    });
    Get.back();
    if (response["message"] != null) {
      generalAlert(
          title: "Success",
          message: response["message"],
          negativeCallback: () {
            Get.back();
          },
          function: () {
            Get.back();
          });
      getProductCategiories();
    } else {
      showSnackBar(message: response["error"], color: Colors.red);
    }
  }

  void adjustStock(
      {required Product product, required int quantity, required String type}) {
    LoadingDialog.showLoadingDialog(
      context: Get.context!,
      title: "Please wait...",
      key: _keyLoader,
    );
    ProductService.adjustStock(
        product: product, quantity: quantity, type: type);
    Get.back();
    showSnackBar(message: "Stock adjusted successfully", color: Colors.green);
    getProducts(
        type: "all",
        name: "",
        page: 1,
        limit: 50,
        stockMode: stockMode.value,
        shop: userController.currentUser.value!.primaryShop!.id!,
        refresh: false);
  }

  Future<void> loadMoreProducts() async {
    if (loadingMore.isTrue || hasMore.isFalse) {
      return;
    }

    loadingMore.value = true;

    final nextPage = (productmeta["currentPage"] ?? 1) + 1;

    await getProducts(
      shop: userController.currentUser.value?.primaryShop?.id ?? "",
      page: nextPage,
      append: true,
      name: searchProductController.text,
      sort: selectedSort.value,
      category: selectedCategory.value,
      stockMode: stockMode.value,
    );

    loadingMore.value = false;
  }

  submitTranster({
    required Shop toShop,
    required context,
  }) async {
    var transferData = {
      "attendantId": userController.currentUser.value?.attendantId?.sId,
      "fromShopId": userController.currentUser.value?.primaryShop?.id,
      "toShopOwner": userController.currentUser.value?.primaryShop?.id,
      "toShopId": toShop.id,
      'useWarehouse':
          (userController.currentUser.value?.primaryShop?.warehouse == true) ||
              (userController.currentUser.value?.primaryShop?.useWarehouse ==
                  true),
      "products": selectedTransferProducts
          .map(
            (element) => {
              "product": element["product"],
              "quantity": element["quantity"]
            },
          )
          .toList(),
    };

    try {
      transferingproducts.value = true;

      var respose = await ProductService().transferProduct(
        transferData,
      );

      transferingproducts.value = false;

      if (respose["error"] != null) {
        generalAlert(
          title: "Error",
          message:
              "${(respose["failedChecks"] as List)[0]['name']} - ${(respose["failedChecks"] as List)[0]['error']}",
        );
      }

      return respose;
    } catch (e) {
      transferingproducts.value = false;

      importall.value = false;
    }

    selectedTransferProducts.clear();
  }

  Future<void> getProductCategiories() async {
    loadingproductCategories.value = true;
    productCategories.clear();
    List<dynamic> productCategoriesResponse = await ProductService()
        .getProductCategories(userController.currentUser.value!.id!);
    productCategories.addAll(productCategoriesResponse
        .map((e) => ProductCategory.fromJson(e))
        .toList());
    loadingproductCategories.value = false;
  }

  void filterProductsLocally(String query) {
    if (query.isEmpty) {
      productlist.value = originalProducts;
      return;
    }

    final q = query.toLowerCase();

    productlist.value = originalProducts.where((product) {
      final name = product.name?.toLowerCase() ?? '';

      final barcode = product.barcode?.toLowerCase() ?? '';

      return name.contains(q) || barcode.contains(q);
    }).toList();
  }

  Future<void> getProducts({
    required String shop,
    String? type,
    String name = "",
    String sort = "",
    String stockMode = "instock",
    ProductCategory? category,
    int page = 1,
    int limit = 40,
    String reason = "",
    String productid = "",
    String barcodeId = "",
    bool refresh = false,
    bool append = false,
  }) async {
    try {
      if (append == false) {
        loading.value = true;
      }

      if (refresh == true) {
        productlist.clear();
      }

      final response = await ProductService.getProducts(
        shop: shop,
        type: type,
        name: name,
        sort: sort,
        category: category,
        page: page,
        limit: limit,
        reason: reason,
        productid: productid,
        barcodeId: barcodeId,
        stockMode: stockMode,
      );

      if (response != null) {
        List products = response["data"] ?? [];

        final parsedProducts = products
            .map(
              (e) => ProductDisplay.fromJson(
                e,
              ),
            )
            .toList();

        if (append == true) {
          productlist.addAll(
            parsedProducts,
          );
          originalProducts.addAll(parsedProducts);
        } else {
          originalProducts.value = parsedProducts;
          productlist.value = parsedProducts;
        }

        productmeta.value = {
          "count": response["count"] ?? 0,
          "totalPages": response["totalPages"] ?? 0,
          "currentPage": response["currentPage"] ?? page,
        };

        hasMore.value = page < (response["totalPages"] ?? 0);

        productlist.refresh();
        originalProducts.refresh();
      }
    } catch (e) {
      generalAlert(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;

      loadingMore.value = false;
    }
  }

  Future copyFromOthershop(
    List<Map<String, dynamic>> value,
    toShop,
    fromShop,
  ) async {
    try {
      importProgressData.value = {
        "loading": true,
        "imported": 0,
        "failed": 0,
        "total": importall.value ? productmeta["count"] ?? 0 : value.length,
        "progress": 0.0,
        "currentProduct": "Preparing import...",
        "completed": false,
      };

      final response = await ProductService.transferProducts(
        value,
        toShop,
        fromShop,
        importall.value,
        resetQuantity.value,
      );

      final imported = response["imported"] ?? 0;

      final failed = response["failed"] ?? 0;

      final total = response["total"] ?? 0;

      importProgressData.value = {
        "loading": false,
        "imported": imported,
        "failed": failed,
        "total": total,
        "progress": 1.0,
        "currentProduct": "Import completed",
        "completed": true,
      };

      selectedTransferProducts.clear();

      transferingproducts.value = false;

      productlist.refresh();

      importall.value = false;

      resetQuantity.value = false;

      return response;
    } catch (e) {
      importProgressData.value = {
        ...importProgressData,
        "loading": false,
        "currentProduct": "Import failed",
      };

      generalAlert(
        title: "Error",
        message: e.toString(),
      );
    }
  }
}
