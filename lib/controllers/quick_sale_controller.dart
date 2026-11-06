import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/customercontroller.dart';
import 'package:pointify/controllers/salescontroller.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/customer.dart';
import 'package:pointify/models/product.dart';
import 'package:pointify/models/salemodel.dart';
import 'package:pointify/models/saleitem.dart';
import 'package:pointify/screens/customers/customers_page.dart';
import 'package:pointify/screens/sales/sale_preview.dart';
import 'package:pointify/services/product_service.dart';
import 'package:pointify/widgets/snackbars.dart';

/// One row on the quick-sale screen. [product] is set when the row matches a
/// product already in the system (picked from suggestions).
class QuickLine {
  String name;
  double price;
  double qty;
  Product? product;

  QuickLine({
    required this.name,
    required this.price,
    this.qty = 1,
    this.product,
  });

  double get total => price * qty;
}

/// Sell items without stocking them first. Anything typed that isn't in the
/// system is saved as a virtual (no stock tracking) product on checkout, so
/// the next time it is suggested with its last price and can be re-used.
class QuickSaleController extends GetxController {
  final lines = <QuickLine>[].obs;
  final suggestions = <Product>[].obs;
  final searching = false.obs;
  final checkingOut = false.obs;

  /// null = walk-in customer.
  final customer = Rxn<Customer>();
  final customerType = 'Retail'.obs; // Retail | Wholesale | Dealer

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController(text: '1');

  /// Set when the cashier picked a suggestion for the row being typed.
  Product? picked;

  Timer? _debounce;
  int _searchId = 0;

  double get grandTotal => lines.fold(0, (s, l) => s + l.total);

  String? get _shopId => userController.currentUser.value?.primaryShop?.id;

  @override
  void onClose() {
    _debounce?.cancel();
    nameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    super.onClose();
  }

  // ─── suggestions ───────────────────────────────────────────────────────

  void onNameChanged(String text) {
    // Typing again after picking a suggestion means it is a different item.
    if (picked != null && picked!.name != text) picked = null;
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      suggestions.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_searchId;
    searching.value = true;
    try {
      final response = await ProductService.getProductsBySort(
        type: 'all',
        text: query,
        limit: 8,
        page: 1,
        shopId: _shopId ?? '',
        adminId: userController.currentUser.value?.id ?? '',
        useWarehouse:
            userController.currentUser.value?.primaryShop?.useWarehouse ??
                false,
        sort: '',
        reason: '',
      );
      if (id != _searchId) return; // a newer search superseded this one
      final data = response is Map ? response['data'] : null;
      suggestions.value = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList()
          : [];
    } catch (_) {
      if (id == _searchId) suggestions.clear();
    } finally {
      if (id == _searchId) searching.value = false;
    }
  }

  void pickSuggestion(Product product) {
    picked = product;
    nameController.text = product.name ?? '';
    nameController.selection =
        TextSelection.collapsed(offset: nameController.text.length);
    final price = product.sellingPrice ?? 0;
    priceController.text = price == 0 ? '' : _fmt(price);
    suggestions.clear();
  }

  // ─── customer ──────────────────────────────────────────────────────────

  void openCustomerPicker() {
    final customers = Get.find<CustomerController>();
    final sales = Get.find<SalesController>();
    customers.getCustomersInShop('all');
    // The picker checks the customer's credit limit against the open receipt.
    final draft = SaleModel(items: []);
    draft.totalWithDiscount = grandTotal;
    sales.receipt.value = draft;
    Get.to(() => Customers(
          type: 'sale',
          function: (Customer? picked) {
            if (picked != null) customer.value = picked;
          },
        ));
  }

  void clearCustomer() => customer.value = null;

  void setCustomerType(String type) => customerType.value = type;

  // ─── cart ──────────────────────────────────────────────────────────────

  /// Returns true when the row was added.
  bool addCurrent() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final qty = double.tryParse(qtyController.text.trim()) ?? 1;
    if (name.isEmpty) {
      showSnackBar(message: 'Enter the item name', color: Colors.red);
      return false;
    }
    if (price == null || price <= 0) {
      showSnackBar(message: 'Enter a price', color: Colors.red);
      return false;
    }
    if (qty <= 0) {
      showSnackBar(message: 'Quantity must be more than 0', color: Colors.red);
      return false;
    }

    // Same name typed twice → bump the existing row instead of duplicating.
    final existing = lines.indexWhere(
        (l) => l.name.toLowerCase() == name.toLowerCase() && l.price == price);
    if (existing != -1) {
      lines[existing].qty += qty;
      lines.refresh();
    } else {
      lines.add(QuickLine(
        name: name,
        price: price,
        qty: qty,
        product: picked,
      ));
    }

    picked = null;
    nameController.clear();
    priceController.clear();
    qtyController.text = '1';
    suggestions.clear();
    return true;
  }

  void removeAt(int index) => lines.removeAt(index);

  void updateLine(int index, {double? price, double? qty}) {
    final line = lines[index];
    if (price != null && price > 0) line.price = price;
    if (qty != null && qty > 0) line.qty = qty;
    lines.refresh();
  }

  void reset() {
    lines.clear();
    suggestions.clear();
    picked = null;
    customer.value = null;
    customerType.value = 'Retail';
    nameController.clear();
    priceController.clear();
    qtyController.text = '1';
  }

  // ─── checkout ──────────────────────────────────────────────────────────

  /// Saves any new items, loads the cart into the normal sales flow and opens
  /// the existing payment / receipt screen.
  Future<void> checkout() async {
    // Add whatever is still sitting in the entry fields.
    if (nameController.text.trim().isNotEmpty ||
        priceController.text.trim().isNotEmpty) {
      if (!addCurrent()) return;
    }
    if (lines.isEmpty) {
      showSnackBar(message: 'Add at least one item', color: Colors.red);
      return;
    }
    if (checkingOut.value) return;
    checkingOut.value = true;

    try {
      final resolved = <QuickLine, Product>{};
      for (final line in lines) {
        final product = await _resolveProduct(line);
        if (product == null) return; // error already shown
        // Remember it, so a retry (or coming back from payment) reuses the
        // saved product instead of creating a duplicate.
        line.product = product;
        resolved[line] = product;
      }

      final sales = Get.find<SalesController>();
      sales.receipt.value = null;
      // changeSaleItem reads the customer from CustomerController; the sale
      // payload reads it from SalesController.
      final chosen = customer.value;
      Get.find<CustomerController>().currentCustomer.value = chosen;
      sales.currentCustomer.value = chosen;
      sales.selectedCustomerController.text = chosen?.name ?? '';
      sales.selectedCustomerType.value = customerType.value;
      final shopTax = userController.currentUser.value?.primaryShop?.tax ?? 0.0;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendantId = userController.currentUser.value?.attendantId ?? '';

      // The cart keys items by product, so merge rows resolving to one product.
      final merged = <String, SaleItem>{};
      for (final entry in resolved.entries) {
        final line = entry.key;
        final product = entry.value;
        final key = product.sId ?? line.name;
        final existing = merged[key];
        if (existing != null) {
          existing.quantity = (existing.quantity ?? 0) + line.qty;
          continue;
        }
        final total = line.price * line.qty;
        merged[key] = SaleItem(
          product: product,
          quantity: line.qty,
          unitPrice: line.price,
          totalLinePrice: total,
          tax: product.taxable == true ? shopTax * total / 100 : 0,
          lineDiscount: 0,
          attendant: Attendant(sId: attendantId.toString()),
          createdAt: today,
        );
      }
      for (final item in merged.values) {
        sales.changeSaleItem(item, status: 'cashed');
      }
      sales.amountPaid.text = '0.0';

      await Get.to(() => const SalePreview());
      // Back from payment: start fresh once the sale went through.
      if (sales.receipt.value == null) reset();
    } finally {
      checkingOut.value = false;
    }
  }

  /// Existing product → keep it (and remember a changed price on virtual
  /// ones). New name → save it as a virtual product so it is found next time.
  Future<Product?> _resolveProduct(QuickLine line) async {
    final existing = line.product;
    if (existing != null) {
      if (_isQuickItem(existing) &&
          existing.sId != null &&
          (existing.sellingPrice ?? 0) != line.price) {
        // Best effort: a failure here must not block the sale.
        try {
          await ProductService.updateProduct(
              {'sellingPrice': line.price}, existing.sId!);
          existing.sellingPrice = line.price;
        } catch (_) {}
      }
      return existing;
    }

    final user = userController.currentUser.value;
    final shop = user?.primaryShop;
    if (shop?.id == null) {
      showSnackBar(message: 'No active shop', color: Colors.red);
      return null;
    }

    // The backend creates no duplicate check, so reuse an exact-name match
    // (typed without picking the suggestion) instead of saving it twice.
    final sameName = await _lookupByName(line.name);
    if (sameName != null) return sameName;

    // productType "service": the sales API skips stock, buying-price and
    // minimum-price checks for services, so no quantity is needed to sell.
    final response = await ProductService().createProduct({
      'name': line.name,
      'productType': 'service',
      'virtual': true,
      'quantity': '0',
      'manageByPrice': false,
      'bundle': false,
      'taxable': false,
      'items': [],
      'wholesalePrice': 0.0,
      'dealerPrice': 0.0,
      'buyingPrice': 0.0,
      'sellingPrice': line.price,
      'minSellingPrice': null,
      'shopId': shop!.id,
      'admin': user!.id,
      'attendantId': user.attendantId,
      'warehouse': (shop.warehouse ?? false) || (shop.useWarehouse ?? false),
      'measure': '',
      'manufacturer': '',
      'productCategoryId': null,
      'reorderLevel': 0,
      'maxDiscount': 0,
      'description': '',
      'supplierId': null,
      'expiryDate': null,
      'deleted': false,
    });

    if (response is! Map || response['error'] != null || response['_id'] == null) {
      showSnackBar(
        message: response is Map && response['error'] != null
            ? response['error'].toString()
            : 'Could not save "${line.name}"',
        color: Colors.red,
      );
      return null;
    }

    // The sales API finds inventory by product + shop, so the missing
    // inventoryId in the create response is not needed.
    return Product.fromJson(Map<String, dynamic>.from(response))
      ..virtual = true;
  }

  /// Items made through quick sale (no stock tracking).
  bool _isQuickItem(Product p) => p.type == 'service' || p.virtual == true;

  /// Exact (case-insensitive) name match among the shop's products.
  Future<Product?> _lookupByName(String name) async {
    try {
      final response = await ProductService.getProductsBySort(
        type: 'all',
        text: name,
        limit: 20,
        page: 1,
        shopId: _shopId ?? '',
        adminId: userController.currentUser.value?.id ?? '',
        useWarehouse:
            userController.currentUser.value?.primaryShop?.useWarehouse ??
                false,
        sort: '',
        reason: '',
      );
      final data = response is Map ? response['data'] : null;
      if (data is! List) return null;
      final wanted = name.trim().toLowerCase();
      for (final raw in data.whereType<Map<String, dynamic>>()) {
        if ((raw['name'] ?? '').toString().trim().toLowerCase() == wanted) {
          return Product.fromJson(raw);
        }
      }
    } catch (_) {}
    return null;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
