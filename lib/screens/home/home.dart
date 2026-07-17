import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/customercontroller.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/controllers/salescontroller.dart';
import 'package:pointify/controllers/shopcontroller.dart';
import 'package:pointify/controllers/usercontroller.dart';
import 'package:pointify/models/bank.dart';
import 'package:pointify/models/customer.dart';
import 'package:pointify/services/customer.dart';
import 'package:pointify/services/shop_services.dart';
import 'package:pointify/services/supplier_service.dart';
import 'package:pointify/sqlite/helper.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/authcontroller.dart';
import '../../controllers/homecontroller.dart';
import '../../services/cashflow.dart';
import '../../services/client.dart';
import '../../services/end_points.dart';
import '../../services/expenses.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/sales_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/helper.dart';
import '../../widgets/minor_title.dart';
import 'attendant/attendants_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FAILED SYNC-QUEUE DESCRIPTORS
// One entry per table that has a `synced` + `syncError` column. Used by
// _showFailedSyncItemsIfAny() below to render/dismiss failures generically
// instead of a hand-maintained list per table.
// ─────────────────────────────────────────────────────────────────────────────

class _FailedQueueDescriptor {
  final String table;
  final String Function(Map<String, dynamic> row) describe;
  const _FailedQueueDescriptor(this.table, this.describe);
}

String _describeSaleReturn(Map<String, dynamic> r) =>
    '• Return for sale ${r['saleId']}: ${r['syncError']}';
String _describeSalePayment(Map<String, dynamic> r) =>
    '• Payment of ${r['paymentAmount']} for sale ${r['saleId']}: ${r['syncError']}';
String _describeShopUpdate(Map<String, dynamic> r) =>
    '• Shop update: ${r['syncError']}';
String _describeCategory(Map<String, dynamic> r) =>
    '• Category "${r['name']}": ${r['syncError']}';
String _describeProductDelete(Map<String, dynamic> r) =>
    '• Delete product ${r['productId']}: ${r['syncError']}';
String _describeBarcodeUpdate(Map<String, dynamic> r) =>
    '• Barcode update for product ${r['productId']}: ${r['syncError']}';
String _describeExpenseDelete(Map<String, dynamic> r) =>
    '• Delete expense ${r['expenseId']}: ${r['syncError']}';
String _describeExpenseCategory(Map<String, dynamic> r) =>
    '• Expense category "${r['name']}": ${r['syncError']}';
String _describeExpenseCategoryUpdate(Map<String, dynamic> r) =>
    '• Rename expense category ${r['categoryId']}: ${r['syncError']}';
String _describeExpenseCategoryDelete(Map<String, dynamic> r) =>
    '• Delete expense category ${r['categoryId']}: ${r['syncError']}';
String _describeCashflowCategory(Map<String, dynamic> r) =>
    '• Cashflow category "${r['name']}": ${r['syncError']}';
String _describeCashflowCategoryUpdate(Map<String, dynamic> r) =>
    '• Rename cashflow category ${r['categoryId']}: ${r['syncError']}';
String _describeCashflowCategoryDelete(Map<String, dynamic> r) =>
    '• Delete cashflow category ${r['categoryId']}: ${r['syncError']}';
String _describeBank(Map<String, dynamic> r) =>
    '• Bank "${r['name']}": ${r['syncError']}';
String _describeBankUpdate(Map<String, dynamic> r) =>
    '• Rename bank ${r['bankId']}: ${r['syncError']}';
String _describeBankDelete(Map<String, dynamic> r) =>
    '• Delete bank ${r['bankId']}: ${r['syncError']}';
String _describeCustomerUpdate(Map<String, dynamic> r) =>
    '• Update customer ${r['customerId']}: ${r['syncError']}';
String _describeCustomerDelete(Map<String, dynamic> r) =>
    '• Delete customer ${r['customerId']}: ${r['syncError']}';

const _failedQueueDescriptors = [
  _FailedQueueDescriptor('saleReturn', _describeSaleReturn),
  _FailedQueueDescriptor('salePayment', _describeSalePayment),
  _FailedQueueDescriptor('shopUpdate', _describeShopUpdate),
  _FailedQueueDescriptor('productCategoryQueue', _describeCategory),
  _FailedQueueDescriptor('productDeleteQueue', _describeProductDelete),
  _FailedQueueDescriptor('barcodeUpdateQueue', _describeBarcodeUpdate),
  _FailedQueueDescriptor('expenseDeleteQueue', _describeExpenseDelete),
  _FailedQueueDescriptor('expenseCategoryQueue', _describeExpenseCategory),
  _FailedQueueDescriptor(
      'expenseCategoryUpdateQueue', _describeExpenseCategoryUpdate),
  _FailedQueueDescriptor(
      'expenseCategoryDeleteQueue', _describeExpenseCategoryDelete),
  _FailedQueueDescriptor('cashflowCategoryQueue', _describeCashflowCategory),
  _FailedQueueDescriptor(
      'cashflowCategoryUpdateQueue', _describeCashflowCategoryUpdate),
  _FailedQueueDescriptor(
      'cashflowCategoryDeleteQueue', _describeCashflowCategoryDelete),
  _FailedQueueDescriptor('bankQueue', _describeBank),
  _FailedQueueDescriptor('bankUpdateQueue', _describeBankUpdate),
  _FailedQueueDescriptor('bankDeleteQueue', _describeBankDelete),
  _FailedQueueDescriptor('customerUpdateQueue', _describeCustomerUpdate),
  _FailedQueueDescriptor('customerDeleteQueue', _describeCustomerDelete),
];

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  HomeController homeControler = Get.put(HomeController());
  SalesController salesController = Get.put(SalesController());
  ShopController shopController = Get.put(ShopController());
  UserController userController = Get.find<UserController>();
  AuthController authController = Get.find<AuthController>();

  // List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  // final Connectivity _connectivity = Connectivity();
  // late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // // Guard so a reconnect mid-sync doesn't fire a second sync pass
  // bool _isSyncing = false;

  @override
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _connectivityPollTimer;

  // Guard so a reconnect mid-sync doesn't fire a second sync pass
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Backstop: connectivity_plus's stream can be unreliable — silent on
    // disconnect, or reporting stale values on reconnect (observed directly:
    // no event at all going offline, a stale "none" reading coming back
    // online). Poll real connectivity on a timer so the app notices a
    // change within a bounded time even if the OS never tells us.
    _connectivityPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _updateConnectionStatus(_connectionStatus),
    );

    _connectBLE();
  }

  _connectBLE() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString('saved_printer_mac') ?? '';
    if (mac.isNotEmpty) {
      await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityPollTimer?.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException {
      return;
    }
    if (!mounted) return;
    return _updateConnectionStatus(result);
  }

  // ─── connectivity gate ────────────────────────────────────────────────────

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() => _connectionStatus = result);

    // ConnectivityResult only reports interface type (is Wi-Fi/cellular
    // attached), not actual internet reachability — and it genuinely
    // flaps during transitions (none → wifi → none while the connection
    // stabilizes). Treat every stream/poll event as just a signal to
    // re-check, and use isConnected()'s real DNS lookup as the
    // authoritative answer, rather than trusting the raw stream value.
    final reallyConnected = await isConnected();

    // Edge-triggered, not level-triggered: only act when the state
    // actually *changes*. Without this, every stream event or 15-second
    // poll re-confirming "still online" would kick off a full sync pass
    // again, even though nothing changed since the last one.
    final wasConnected = userController.internetConected.value;
    if (reallyConnected == wasConnected) return;

    if (!reallyConnected) {
      // ── went offline ──
      userController.internetConected.value = false;
      homeControler.selectedIndex.value = 0;

      // Count every unsynced record so the badge is accurate
      final db = DatabaseHelper();
      final unsynced = await db.getAllUnsynced();
      final total =
          unsynced.values.fold<int>(0, (sum, list) => sum + list.length);
      salesController.offlinesales.value = total;
    } else {
      // ── came back online ──
      userController.internetConected.value = true;
      _syncAllOfflineData();
    }
  }

  // ─── master sync ─────────────────────────────────────────────────────────
  // Pushes every pending offline record to the server. Products sync first —
  // any sale/adjustment referencing an offline-created product's local id
  // needs that product to have a real server id before it can sync too.
  // Each table is independent — a failure in one does not block the others.

  Future<void> _syncAllOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final db = DatabaseHelper();

    try {
      await _syncProducts(db);
      await _syncCategories(db);
      await _syncProductDeletes(db);
      await _syncBarcodeUpdates(db);
      await _syncSales(db);
      await _syncExpenses(db);
      await _syncPurchases(db);
      await _syncStockCounts(db);
      await _syncAdjustments(db);
      await _syncCashflows(db);
      await _syncCustomers(db);
      await _syncSuppliers(db);
      await _syncWarehouseRequests(db);
      await _syncSaleReturns(db);
      await _syncSalePayments(db);
      await _syncShopUpdates(db);
      await _syncExpenseDeletes(db);
      await _syncExpenseCategories(db);
      await _syncExpenseCategoryUpdates(db);
      await _syncExpenseCategoryDeletes(db);
      await _syncCashflowCategories(db);
      await _syncCashflowCategoryUpdates(db);
      await _syncCashflowCategoryDeletes(db);
      await _syncBanks(db);
      await _syncBankUpdates(db);
      await _syncBankDeletes(db);
      await _syncCustomerUpdates(db);
      await _syncCustomerDeletes(db);
      await _mirrorSalesHistory(db);
    } finally {
      _isSyncing = false;

      // Refresh UI controllers after everything is pushed
      salesController.offlinesales.value = 0;
      Get.find<ProductController>().getProductsBySort(type: 'all');
      Get.find<CustomerController>().getCustomersInShop('');

      await _showFailedSyncItemsIfAny(db);
    }
  }
  // ── full sales history mirror ────────────────────────────────────────────
  // Incremental: only pulls sales created after the last successful sync
  // cursor, so every run after the first is cheap regardless of how much
  // history exists. Capped per run so a very large first-time backlog
  // can't block a single reconnect — it just resumes from where it left
  // off on the next one.

  Future<void> _mirrorSalesHistory(DatabaseHelper db) async {
    final shopId = userController.currentUser.value?.primaryShop?.id;
    if (shopId == null) return;

    final since = await db.getSalesSyncCursor(shopId);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    const maxPagesPerRun = 10;
    const pageSize = 500;
    String latestSeen = since;

    try {
      for (int page = 1; page <= maxPagesPerRun; page++) {
        final response = await SalesService.getSales(
          shopId: shopId,
          fromDate: since,
          toDate: today,
          status: '',
          order: '',
          paymentTag: '',
          page: page,
          limit: pageSize,
        );

        if (response == null || response['data'] == null) break;

        final data = response['data'] as List<dynamic>;
        if (data.isEmpty) break;

        await db.cacheSalesBatch(data);

        for (final sale in data) {
          final createdAt = sale['createdAt'] as String?;
          if (createdAt != null && createdAt.compareTo(latestSeen) > 0) {
            latestSeen = createdAt;
          }
        }

        final totalPages = response['totalPages'] ?? 1;
        if (page >= totalPages) break; // caught up fully this run
      }
    } catch (_) {
      // Network blip mid-mirror — keep whatever cursor progress was made;
      // the rest resumes next reconnect.
    } finally {
      if (latestSeen != since) {
        await db.setSalesSyncCursor(shopId, latestSeen);
      }
    }
  }

  // ── products ──────────────────────────────────────────────────────────────

  Future<void> _syncProducts(DatabaseHelper db) async {
    final rows = await db.getUnsyncedProducts();
    for (final row in rows) {
      try {
        final payload = {
          'name': row['name'],
          'buyingPrice': row['buyingPrice'],
          'sellingPrice': row['sellingPrice'],
          'wholesalePrice': row['wholesalePrice'],
          'dealerPrice': row['dealerPrice'],
          'minSellingPrice': row['minSellingPrice'],
          'quantity': row['quantity'],
          'maxDiscount': row['maxDiscount'],
          'reorderLevel': row['reorderLevel'],
          'productCategoryId': row['productCategoryId'],
          'measure': row['measure'],
          'taxable': row['taxable'] == 1,
          'supplierId': row['supplierId'],
          'shopId': row['shopId'],
          'description': row['description'],
          'attendantId': row['attendantId'],
          'barcode': row['barcode'],
          'productType': row['productType'],
          'manufacturer': row['manufacturer'],
        };
        final response = await ProductService().createProduct(payload);
        if (response['error'] == null && response['_id'] != null) {
          await db.rewriteProductIdReferences(
              row['id'] as String, response['_id'] as String);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncCategories(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('productCategoryQueue');
    for (final row in rows) {
      try {
        final response = await ProductService.createCategory({
          'name': row['name'],
          'admin': row['admin'],
        });
        if (response['message'] != null) {
          await db.markRowSynced('productCategoryQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'productCategoryQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncProductDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('productDeleteQueue');
    for (final row in rows) {
      try {
        final response =
            await ProductService.deleteProduct(row['productId'] as String);
        if (response == null || response['error'] == null) {
          await db.markRowSynced('productDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'productDeleteQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncBarcodeUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('barcodeUpdateQueue');
    for (final row in rows) {
      try {
        final response = await ProductService.updateBarcode(
          {'barcode': row['barcode']},
          row['productId'] as String,
        );
        if (response['error'] == null) {
          await db.markRowSynced('barcodeUpdateQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'barcodeUpdateQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── sales ─────────────────────────────────────────────────────────────────
  // Uses buildSaleSyncPayload() from helper to correctly map every field,
  // including the fields that were missing from the old _updateProduct().

  Future<void> _syncSales(DatabaseHelper db) async {
    final sales = await db.getPendingSales();
    if (sales.isEmpty) return;

    for (final row in sales) {
      try {
        final payload = db.buildSaleSyncPayload(row);
        final response = await SalesService.createSale(payload);
        if (response['error'] == null) {
          await db.deleteSale(row['id'] as int);
        } else {
          // Server actually rejected it — stop retrying silently, surface it.
          await db.markSaleFailed(row['id'] as int, response['error']);
        }
      } catch (_) {
        // Network blip — leave it (still syncError == null), retry next time.
      }
    }
  }

  // ── expenses ──────────────────────────────────────────────────────────────

  Future<void> _syncExpenses(DatabaseHelper db) async {
    final rows = await db.getUnsyncedExpenses();
    for (final row in rows) {
      try {
        final payload = {
          'description': row['description'],
          'amount': row['amount'],
          'category': row['categoryId'],
          'autoSave': row['autoSave'] == 1,
          'frequency': row['frequency'] ?? '',
          'attendantId': row['attendantId'],
          'shopId': row['shopId'],
        };
        final response = await ExpensesServices.createExpenses(payload);
        if (response['error'] == null) {
          await db.markExpenseSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── purchases ─────────────────────────────────────────────────────────────

  Future<void> _syncPurchases(DatabaseHelper db) async {
    final rows = await db.getUnsyncedPurchases();
    for (final row in rows) {
      try {
        final items = await db.getPurchaseItems(row['id'] as String);
        final payload = {
          'purchase': {
            'shopId': row['shopId'],
            'supplierId': row['supplierId'],
            'attendantId': row['attendantId'],
            'paymentType': row['paymentType'],
          },
          'purchaseItems': items
              .map((i) => {
                    'product': i['productId'],
                    'quantity': i['quantity'],
                    'unitPrice': i['unitPrice'],
                    'lineDiscount': i['lineDiscount'] ?? 0,
                    'attendantId': i['attendantId'],
                  })
              .toList(),
          'amountpaid': row['amountPaid'] ?? 0,
          'trackBatches': false,
        };
        final response = await PurchaseService.createPurchase(payload);
        if (response['error'] == null) {
          await db.markPurchaseSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── stock counts ──────────────────────────────────────────────────────────

  Future<void> _syncStockCounts(DatabaseHelper db) async {
    final rows = await db.getUnsyncedStockCounts();
    for (final row in rows) {
      try {
        final payload = {
          'shopId': row['shopId'],
          'attendantId': row['attendantId'],
          'useWarehouse':
              userController.currentUser.value?.primaryShop?.useWarehouse ??
                  false,
          'products': jsonDecode(row['products'] as String),
        };
        final response = await ProductService.countProduct(payload);
        if (response['error'] == null) {
          await db.markStockCountSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── adjustments ───────────────────────────────────────────────────────────
  // The server adjustment endpoint expects { product, shop, type, before,
  // after, adjusted } — matches exactly what helper stores.

  Future<void> _syncAdjustments(DatabaseHelper db) async {
    final rows = await db.getUnsyncedAdjustments();
    for (final row in rows) {
      try {
        // Server: PUT /product/adjust/:productId
        // Payload: { type, quantity (= adjusted amount), shop, product, before }
        final payload = {
          'type': row['type'],
          'quantity': row['adjusted'],
          'shop': row['shopId'],
          'product': row['productId'],
          'before': row['before'],
        };
        final response = await DbBase().databaseRequest(
          '${EndPoints.products}adjust/${row['productId']}',
          DbBase().putRequestType,
          body: payload,
        );
        if (response['error'] == null) {
          await db.markAdjustmentSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── cashflows ─────────────────────────────────────────────────────────────

  Future<void> _syncCashflows(DatabaseHelper db) async {
    final rows = await db.getUnsyncedCashflows();
    for (final row in rows) {
      try {
        final payload = {
          'name': row['name'],
          'amount': row['amount'],
          'category': row['categoryId'],
          'attendantId': row['attendantId'],
          'shopId': row['shopId'],
          'bank': row['bankId'],
        };
        final response = await CashFlowServices.createCashFlow(payload);
        if (response['error'] == null) {
          await db.markCashflowSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── customers ─────────────────────────────────────────────────────────────

  Future<void> _syncCustomers(DatabaseHelper db) async {
    final rows = await db.getUnsyncedCustomers();
    for (final row in rows) {
      try {
        final customerModel = Customer(
          name: row['name'],
          phoneNumber: row['phoneNumber'],
          address: row['address'],
          email: row['email'],
          wallet: (row['wallet'] as num?)?.toDouble(),
          creditLimit: (row['creditLimit'] as num?)?.toDouble(),
          shopId: row['shopId'],
          attendantId: row['attendantId'],
        );
        final response =
            await CustomerService.createCustomer(customerModel, page: null);
        if (response['error'] == null && response['_id'] != null) {
          await db.markCustomerSynced(row['id'] as String, response['_id']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncCustomerUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('customerUpdateQueue');
    for (final row in rows) {
      try {
        final patch =
            jsonDecode(row['patch'] as String) as Map<String, dynamic>;
        final response = await CustomerService.updateCustomer(
            patch, row['customerId'] as String);
        if (response['error'] == null) {
          await db.markRowSynced('customerUpdateQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'customerUpdateQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncCustomerDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('customerDeleteQueue');
    for (final row in rows) {
      try {
        final response = await CustomerService.deleteCustomer(
            customerModel: Customer(sId: row['customerId'] as String));
        if (response == null || response['error'] == null) {
          await db.markRowSynced('customerDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'customerDeleteQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── suppliers ─────────────────────────────────────────────────────────────

  Future<void> _syncSuppliers(DatabaseHelper db) async {
    final rows = await db.getUnsyncedSuppliers();
    for (final row in rows) {
      try {
        Map<String, String> payload = {
          'name': row['name'],
          'phoneNumber': row['phoneNumber'],
          'shopId': row['shopId'],
        };
        final response = await SupplierService().createSupplier(payload);
        if (response['error'] == null && response['_id'] != null) {
          await db.markSupplierSynced(row['id'] as String, response['_id']);
        }
      } catch (_) {}
    }
  }

  // ── warehouse requests ────────────────────────────────────────────────────

  Future<void> _syncWarehouseRequests(DatabaseHelper db) async {
    final rows = await db.getUnsyncedWarehouseRequests();
    for (final row in rows) {
      try {
        final payload = {
          'attendantId': userController.currentUser.value?.attendantId?.sId,
          'useWarehouse': true,
          'shopId': row['fromShopId'],
          'warehouse': row['toShopId'],
          'inventory': jsonDecode(row['products'] as String),
        };
        final response = await ProductService.productStockinRequest(payload);
        if (response['error'] == null) {
          await db.markWarehouseRequestSynced(row['id'] as String);
        }
      } catch (_) {}
    }
  }

  // ── sale returns / credit payments ───────────────────────────────────────

  Future<void> _syncSaleReturns(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('saleReturn');
    for (final row in rows) {
      try {
        final payload = {
          'saleid': row['saleId'],
          'attendantId': row['attendantId'],
          'shopId': row['shopId'],
          'items': jsonDecode(row['items'] as String),
          'reason': row['reason'],
          'deleteReceipt': row['deleteReceipt'] == 1,
        };
        final response = await SalesService.returnItem(payload);
        if (response['error'] == null) {
          await db.markRowSynced('saleReturn', row['id'] as String);
        } else {
          // Not a network problem — the server rejected it. Stop retrying
          // silently and surface it instead.
          await db.markRowFailed(
              'saleReturn', row['id'] as String, response['error']);
        }
      } catch (_) {
        // Network blip — leave it, retry next reconnect.
      }
    }
  }

  Future<void> _syncSalePayments(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('salePayment');
    for (final row in rows) {
      try {
        final payload = {
          'saleId': row['saleId'],
          'paymentAmount': row['paymentAmount'],
          'paymentType': row['paymentType'],
          'mpesaCode': row['mpesaCode'],
          'attendantId': row['attendantId'],
        };
        final response = await SalesService.payCredit(payload);
        if (response['error'] == null) {
          await db.markRowSynced('salePayment', row['id'] as String);
        } else {
          await db.markRowFailed(
              'salePayment', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── shop updates ──────────────────────────────────────────────────────────

  Future<void> _syncShopUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('shopUpdate');
    for (final row in rows) {
      try {
        final patch =
            jsonDecode(row['patch'] as String) as Map<String, dynamic>;
        final response =
            await ShopService().updateShop(row['shopId'] as String, patch);
        if (response['error'] == null) {
          await db.markRowSynced('shopUpdate', row['id'] as String);
        } else {
          await db.markRowFailed(
              'shopUpdate', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── expense deletes / categories ──────────────────────────────────────────

  Future<void> _syncExpenseDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('expenseDeleteQueue');
    for (final row in rows) {
      try {
        final response =
            await ExpensesServices.deleteExpenses(row['expenseId'] as String);
        if (response == null || response['error'] == null) {
          await db.markRowSynced('expenseDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'expenseDeleteQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncExpenseCategories(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('expenseCategoryQueue');
    for (final row in rows) {
      try {
        final response = await ExpensesServices.createExpensesCategory({
          'name': row['name'],
          'shopId': row['shopId'],
        });
        if (response['error'] == null) {
          await db.markRowSynced('expenseCategoryQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'expenseCategoryQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncExpenseCategoryUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('expenseCategoryUpdateQueue');
    for (final row in rows) {
      try {
        final response = await ExpensesServices.editExpenseCategory(
            {'name': row['name']}, row['categoryId'] as String);
        if (response['error'] == null) {
          await db.markRowSynced(
              'expenseCategoryUpdateQueue', row['id'] as String);
        } else {
          await db.markRowFailed('expenseCategoryUpdateQueue',
              row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncExpenseCategoryDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('expenseCategoryDeleteQueue');
    for (final row in rows) {
      try {
        final response = await ExpensesServices.deleteExpensesCategory(
            row['categoryId'] as String);
        if (response == null || response['error'] == null) {
          await db.markRowSynced(
              'expenseCategoryDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed('expenseCategoryDeleteQueue',
              row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── cashflow categories ───────────────────────────────────────────────────

  Future<void> _syncCashflowCategories(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('cashflowCategoryQueue');
    for (final row in rows) {
      try {
        final response = await CashFlowServices.createCashFlowCategory({
          'type': row['type'],
          'name': row['name'],
          'shopId': row['shopId'],
        });
        if (response['error'] == null) {
          await db.markRowSynced('cashflowCategoryQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'cashflowCategoryQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncCashflowCategoryUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('cashflowCategoryUpdateQueue');
    for (final row in rows) {
      try {
        final response = await CashFlowServices.updateCategory(
            row['categoryId'] as String, {'name': row['name']});
        if (response['error'] == null) {
          await db.markRowSynced(
              'cashflowCategoryUpdateQueue', row['id'] as String);
        } else {
          await db.markRowFailed('cashflowCategoryUpdateQueue',
              row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncCashflowCategoryDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('cashflowCategoryDeleteQueue');
    for (final row in rows) {
      try {
        final response = await CashFlowServices.deleteCashflowCategory(
            row['categoryId'] as String);
        if (response == null || response['error'] == null) {
          await db.markRowSynced(
              'cashflowCategoryDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed('cashflowCategoryDeleteQueue',
              row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── banks ─────────────────────────────────────────────────────────────────

  Future<void> _syncBanks(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('bankQueue');
    for (final row in rows) {
      try {
        final response = await CashFlowServices().createBank({
          'shop': row['shopId'],
          'name': row['name'],
        });
        if (response['error'] == null) {
          await db.markRowSynced('bankQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'bankQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncBankUpdates(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('bankUpdateQueue');
    for (final row in rows) {
      try {
        // BankModel's constructor only takes name/amount, not id — set the
        // public `id` field directly via cascade instead.
        final bankModel = BankModel()..id = row['bankId'] as String;
        final response =
            await CashFlowServices.updateBank(bankModel, {'name': row['name']});
        if (response == null || response['error'] == null) {
          await db.markRowSynced('bankUpdateQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'bankUpdateQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncBankDeletes(DatabaseHelper db) async {
    final rows = await db.getUnsyncedRows('bankDeleteQueue');
    for (final row in rows) {
      try {
        final response =
            await CashFlowServices.deleteBank(row['bankId'] as String);
        if (response == null || response['error'] == null) {
          await db.markRowSynced('bankDeleteQueue', row['id'] as String);
        } else {
          await db.markRowFailed(
              'bankDeleteQueue', row['id'] as String, response['error']);
        }
      } catch (_) {}
    }
  }

  // ── failed-sync surfacing ─────────────────────────────────────────────────

  Future<void> _showFailedSyncItemsIfAny(DatabaseHelper db) async {
    final failedByTable = <String, List<Map<String, dynamic>>>{};
    for (final d in _failedQueueDescriptors) {
      final rows = await db.getFailedRows(d.table);
      if (rows.isNotEmpty) failedByTable[d.table] = rows;
    }

    final failedSales = await db.getFailedSales();

    if (failedByTable.isEmpty && failedSales.isEmpty) return;
    if (!mounted) return;

    final messages = <String>[
      for (final d in _failedQueueDescriptors)
        if (failedByTable[d.table] != null)
          for (final row in failedByTable[d.table]!) d.describe(row),
      ...failedSales.map((r) =>
          '• Sale of ${r['totalWithDiscount']} on ${r['createdAt']}: ${r['syncError']}'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Some offline actions could not be synced'),
        content: SingleChildScrollView(
          child: Text(
            'These require your attention — they were rejected by the server '
            'and will not be retried automatically:\n\n${messages.join('\n')}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              for (final entry in failedByTable.entries) {
                for (final row in entry.value) {
                  await db.dismissFailedRow(entry.key, row['id'] as String);
                }
              }
              for (final row in failedSales) {
                await db.dismissFailedSale(row['id'] as int);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Dismiss'), // ← this one
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep for later'), // ← the other one
          ),
        ],
      ),
    );
  }
  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Helper(
      widget: Obx(() {
        return homeControler.pages[homeControler.selectedIndex.value];
      }),
      appBar: AppBar(
        titleSpacing: 0.0,
        leading: Icon(
          Icons.electric_bolt,
          color: AppColors.mainColor,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Obx(
              () => minorTitle(
                  title:
                      'Welcome ${userController.switcheduser.value != null ? userController.switcheduser.value!.username : userController.currentUser.value?.username}',
                  color: Colors.black,
                  size: 12.0),
            ),
            const SizedBox(height: 5),
            Obx(() {
              return userController.switcheduser.value != null
                  ? minorTitle(
                      title:
                          'logged in as ${userController.switcheduser.value?.username}',
                      color: Colors.red,
                      size: 12)
                  : userController.switcheduser.value?.usertype == 'admin'
                      ? minorTitle(
                          title: 'Switch Account', color: AppColors.mainColor)
                      : Container();
            })
          ],
        ),
        elevation: 0.2,
        backgroundColor: Colors.white,
        actions: [
          const SizedBox(width: 10),
          if (userController.currentUser.value?.usertype == 'admin')
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  Get.to(() => AttendantsPage(type: 'switch'));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Switch User', style: TextStyle(fontSize: 16)),
                    Icon(Icons.repeat_sharp, color: AppColors.mainColor),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          decoration: BoxDecoration(
              color: AppColors.lightDeepPurple,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => homeControler.selectedIndex.value = 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Icon(Icons.home,
                          color: homeControler.selectedIndex.value == 0
                              ? Colors.white
                              : Colors.black)),
                      const Text('Home'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    homeControler.selectedIndex.value = 1;
                    shopController.getShops();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Icon(Icons.shop,
                          color: homeControler.selectedIndex.value == 1
                              ? Colors.white
                              : Colors.black)),
                      const Text('Shops'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    homeControler.selectedIndex.value = 2;
                    userController.getAttendants();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Icon(Icons.people,
                          color: homeControler.selectedIndex.value == 2
                              ? Colors.white
                              : Colors.black)),
                      const Text('Attendants'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => homeControler.selectedIndex.value = 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Icon(Icons.people,
                          color: homeControler.selectedIndex.value == 3
                              ? Colors.white
                              : Colors.black)),
                      const Text('Profile'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
