import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VERSION HISTORY
//   31 → original
//   32 → schema alignment pass: fixed attendant syntax error, added missing
//         fields to sales/shop/users/customer, fixed phonenumber mapping
//   33 → full offline pass: added expenses, expenseCategory, purchase,
//         purchaseItems, stockCount, adjustment, cashflow, cashflowCategory
//         tables; added getSalesByDateLocal(); fixed _updateProduct sync-back
//         to include all new fields
//   37 → cleanup pass: replaced ~90 near-identical per-table sync helper
//         methods (getUnsyncedX/getFailedX/markXSynced/markXFailed/
//         dismissFailedX) with 5 generic table-parameterized equivalents
//         (getUnsyncedRows/getFailedRows/markRowSynced/markRowFailed/
//         dismissFailedRow). No behavior change — same tables, same sync
//         logic. See bottom of file.
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  // Bump this any time the schema changes — forces a clean rebuild on device
  int newVersion = 42;

  static Database? _database;

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await _instance.deleteDb();
      await _instance.database;
    }
  }

  DatabaseHelper._internal();

  /// Converts bool, int (0/1), or null to SQLite int (0 or 1).
  static int _boolToInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v == 1 ? 1 : 0;
    if (v is bool) return v ? 1 : 0;
    return 0;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pointy_$newVersion.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── warehouse requests ──────────────────────────────────────────────────
  // NOTE: this table has no syncError column (it predates the failure-
  // surfacing work), so it keeps its own dedicated methods rather than using
  // the generic getUnsyncedRows/getFailedRows helpers.

  Future<String> insertWarehouseRequestOffline(
      Map<String, dynamic> data) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('warehouseRequest', {
      'id': id,
      'fromShopId': data['fromShopId'],
      'toShopId': data['toShopId'],
      'products': jsonEncode(data['products']),
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedWarehouseRequests() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM warehouseRequest WHERE synced = 0');
  }

  Future<void> markWarehouseRequestSynced(String id) async {
    final db = await database;
    await db.update('warehouseRequest', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SCHEMA
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    // ── sales ────────────────────────────────────────────────────────────────
    // FIX: added totalAmount, totalWithDiscount, outstandingBalance,
    //      saleDiscount, extraCharges (JSON), extraChargesTotal,
    //      mpesaTransId, orderId — all required by server createSale endpoint

    await db.execute('''
      CREATE TABLE shopUpdate (
        id        TEXT PRIMARY KEY,
        shopId    TEXT,
        patch     TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saleReturn (
        id            TEXT PRIMARY KEY,
        saleId        TEXT,
        items         TEXT,
        reason        TEXT,
        deleteReceipt INTEGER,
        shopId        TEXT,
        attendantId   TEXT,
        synced        INTEGER DEFAULT 0,
        syncError     TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE salePayment (
        id            TEXT PRIMARY KEY,
        saleId        TEXT,
        paymentAmount REAL,
        paymentType   TEXT,
        mpesaCode     TEXT,
        attendantId   TEXT,
        synced        INTEGER DEFAULT 0,
        syncError     TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        clientRef        TEXT,
        products         TEXT,
        shopId           TEXT,
        attendantId      TEXT,
        saleType         TEXT,
        createdAt        TEXT,
        status           TEXT,
        totaltax         REAL,
        salesnote        TEXT,
        duedate          TEXT,
        mpesaTotal       REAL,
        mpesaTransId     TEXT,
        bankTotal        REAL,
        amountPaid       REAL,
        paymentType      TEXT,
        paymentTag       TEXT,
        totalDiscount    REAL,
        totalAmount      REAL,
        totalWithDiscount REAL,
        outstandingBalance REAL,
        saleDiscount     REAL,
        extraCharges     TEXT,
        extraChargesTotal REAL,
        orderId          TEXT,
        customerId       TEXT,
        syncError        TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouseRequest (
        id          TEXT PRIMARY KEY,
        fromShopId  TEXT,
        toShopId    TEXT,
        products    TEXT,
        createdAt   TEXT,
        synced      INTEGER DEFAULT 0
      )
    ''');

    // ── products ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE products (
        id                TEXT PRIMARY KEY,
        name              TEXT,
        buyingPrice       REAL,
        sellingPrice      REAL,
        wholesalePrice    REAL,
        dealerPrice       REAL,
        minSellingPrice   REAL,
        quantity          INTEGER,
        lastCount         INTEGER,
        maxDiscount       REAL,
        reorderLevel      INTEGER,
        productCategoryId TEXT,
        measure           TEXT,
        deleted           INTEGER,
        taxable           INTEGER,
        supplierId        TEXT,
        shopId            TEXT,
        description       TEXT,
        attendantId       TEXT,
        lastcoundate      TEXT,
        expiryDate        TEXT,
        barcode           TEXT,
        productType       TEXT,
        date              TEXT,
        manufacturer      TEXT,
        synced            INTEGER DEFAULT 1
      )
    ''');

    // ── productCategory ───────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE productCategory (
        id   TEXT PRIMARY KEY,
        name TEXT
      )
    ''');

    // ── shop ─────────────────────────────────────────────────────────────────
    // FIX: added allownegativeselling (used in _buildSalePayload — was always
    //      null offline), warehouse, trackbatches, tax, contact,
    //      paybill_till, paybill_account, address_receipt
    await db.execute('''
      CREATE TABLE shop (
        id                  TEXT PRIMARY KEY,
        name                TEXT,
        address             TEXT,
        shopCategoryId      TEXT,
        deletewarning       INTEGER,
        affliate            TEXT,
        backupdate          TEXT,
        currency            TEXT,
        backupInterval      TEXT,
        backupemail         TEXT,
        allowBackup         INTEGER,
        allowOnlineSelling  INTEGER,
        useWarehouse        INTEGER,
        warehouse           INTEGER,
        trackbatches        INTEGER,
        allownegativeselling INTEGER,
        tax                 REAL,
        contact             TEXT,
        paybill_till        TEXT,
        paybill_account     TEXT,
        address_receipt     TEXT,
        adminId             TEXT,
        createAt            TEXT,
        coordinates_lat     REAL,
        coordinates_long    REAL,
        subscriptionId      TEXT
      )
    ''');

    // ── subscription ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE subscription (
        id         TEXT PRIMARY KEY,
        userId     TEXT,
        shop       TEXT,
        amount     REAL,
        status     INTEGER,
        commission REAL,
        paid       INTEGER,
        startDate  TEXT,
        endDate    TEXT,
        createAt   TEXT,
        packageId  TEXT
      )
    ''');

    // ── packageId ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE packageId (
        id            TEXT PRIMARY KEY,
        discount      INTEGER,
        title         TEXT,
        description   TEXT,
        durationValue INTEGER,
        durationUnit  TEXT,
        amount        INTEGER,
        type          TEXT,
        features      TEXT,
        maxShops      INTEGER,
        status        INTEGER
      )
    ''');

    // ── supplier ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE supplier (
        id          TEXT PRIMARY KEY,
        name        TEXT,
        phoneNumber TEXT,
        shopId      TEXT,
        synced      INTEGER DEFAULT 1
      )
    ''');

    // ── attendant ─────────────────────────────────────────────────────────────
    // FIX: was missing comma after "username TEXT" — crashed DB on creation
    // FIX: insertAttendant() was only saving id+username; now saves all fields
    // NEW: password (offline attendant login), permissions (offline role checks)
    await db.execute('''
      CREATE TABLE attendant (
        id          TEXT PRIMARY KEY,
        username    TEXT,
        shopId      TEXT,
        uniqueDigits INTEGER,
        password    TEXT,
        permissions TEXT
      )
    ''');

    // ── settings ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE settings (
        id                          INTEGER PRIMARY KEY,
        number_of_image_per_product TEXT,
        shop_name                   TEXT,
        android_version             TEXT,
        ios_version                 TEXT,
        address                     TEXT,
        demolink                    TEXT,
        company_name                TEXT,
        vat_number                  TEXT,
        post_code                   TEXT,
        contact                     TEXT,
        email                       TEXT,
        website                     TEXT,
        receipt_size                TEXT,
        offlineEnabled              INTEGER,
        default_currency            TEXT,
        default_time_zone           TEXT,
        default_date_format         TEXT,
        forceUpdate                 INTEGER,
        appName                     TEXT,
        discovershops               INTEGER,
        google_api_key              TEXT,
        stripe_secret_key           TEXT,
        verifyemail                 INTEGER,
        image                       TEXT,
        app_name_display            TEXT,
        app_slogan                  TEXT,
        primary_color               TEXT,
        button_color                TEXT,
        text_color                  TEXT,
        secondary_color             TEXT
      )
    ''');

    // ── users ─────────────────────────────────────────────────────────────────
    // FIX: added smscredit, autoPrint, status, syncInterval
    await db.execute('''
      CREATE TABLE users (
        id                          TEXT PRIMARY KEY,
        platform                    TEXT,
        app_version                 TEXT,
        email                       TEXT,
        usertype                    TEXT,
        username                    TEXT,
        password                    TEXT,
        phone                       TEXT,
        createdAt                   TEXT,
        last_seen                   TEXT,
        emailVerified               INTEGER,
        phoneVerified               INTEGER,
        emailVerificationDate       TEXT,
        affliate                    TEXT,
        otp                         INTEGER,
        otp_expiry                  INTEGER,
        lastSubscriptionReminder    TEXT,
        lastSubscriptionReminderCount INTEGER,
        attendantId                 TEXT,
        primaryShopId               TEXT,
        shopName                    TEXT,
        shopAddress                 TEXT,
        smscredit                   REAL,
        autoPrint                   INTEGER,
        status                      TEXT,
        syncInterval                INTEGER
      )
    ''');

    // ── customer ──────────────────────────────────────────────────────────────
    // FIX: inserCustomer() was reading 'phonenumber' (MongoDB lowercase n)
    //      but the column was phoneNumber — phone was always null offline
    // FIX: wallet changed REAL (can have decimals)
    // NEW: creditLimit (needed for offline credit sale validation)
    await db.execute('''
     CREATE TABLE customer (
        id          TEXT PRIMARY KEY,
        name        TEXT,
        totalDebt   REAL,
        wallet      REAL,
        creditLimit REAL,
        shopId      TEXT,
        attendantId TEXT,
        phoneNumber TEXT,
        customerNo  INTEGER,
        address     TEXT,
        email       TEXT,
        sId         TEXT,
        createAt    TEXT,
        synced      INTEGER DEFAULT 1
      )
    ''');

    // ── expenses ─────────────────────────────────────────────────────────────
    // NEW: full offline expense creation and listing
    await db.execute('''
      CREATE TABLE expenses (
        id          TEXT PRIMARY KEY,
        description TEXT,
        amount      REAL,
        shopId      TEXT,
        attendantId TEXT,
        categoryId  TEXT,
        autoSave    INTEGER,
        frequency   TEXT,
        createAt    TEXT,
        synced      INTEGER DEFAULT 0
      )
    ''');

    // ── expenseCategory ───────────────────────────────────────────────────────
    // NEW: needed to show/select expense categories offline
    await db.execute('''
      CREATE TABLE expenseCategory (
        id       TEXT PRIMARY KEY,
        name     TEXT,
        shopId   TEXT,
        createAt TEXT
      )
    ''');

    // ── purchase ──────────────────────────────────────────────────────────────
    // NEW: full offline purchase creation and listing
    await db.execute('''
      CREATE TABLE purchase (
        id                 TEXT PRIMARY KEY,
        shopId             TEXT,
        supplierId         TEXT,
        attendantId        TEXT,
        paymentType        TEXT,
        totalAmount        REAL,
        amountPaid         REAL,
        outstandingBalance REAL,
        createdAt          TEXT,
        synced             INTEGER DEFAULT 0
      )
    ''');

    // ── purchaseItems ─────────────────────────────────────────────────────────
    // NEW: line items for offline purchases
    await db.execute('''
      CREATE TABLE purchaseItems (
        id          TEXT PRIMARY KEY,
        purchaseId  TEXT,
        productId   TEXT,
        quantity    REAL,
        unitPrice   REAL,
        lineDiscount REAL,
        shopId      TEXT,
        attendantId TEXT,
        createdAt   TEXT
      )
    ''');

    // ── stockCount ────────────────────────────────────────────────────────────
    // NEW: offline stock count (countProduct in StockController)
    await db.execute('''
      CREATE TABLE stockCount (
        id          TEXT PRIMARY KEY,
        shopId      TEXT,
        attendantId TEXT,
        products    TEXT,
        createdAt   TEXT,
        synced      INTEGER DEFAULT 0
      )
    ''');

    // ── adjustment ────────────────────────────────────────────────────────────
    // NEW: offline stock adjustments (add/remove)
    await db.execute('''
      CREATE TABLE adjustment (
        id        TEXT PRIMARY KEY,
        productId TEXT,
        shopId    TEXT,
        type      TEXT,
        before    REAL,
        after     REAL,
        adjusted  REAL,
        createdAt TEXT,
        synced    INTEGER DEFAULT 0
      )
    ''');

    // ── cashflow ──────────────────────────────────────────────────────────────
    // NEW: offline cash-in / cash-out entries
    await db.execute('''
      CREATE TABLE cashflow (
        id          TEXT PRIMARY KEY,
        name        TEXT,
        amount      REAL,
        categoryId  TEXT,
        attendantId TEXT,
        shopId      TEXT,
        bankId      TEXT,
        createAt    TEXT,
        synced      INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE productCategoryQueue (
        id        TEXT PRIMARY KEY,
        name      TEXT,
        admin     TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE productDeleteQueue (
        id        TEXT PRIMARY KEY,
        productId TEXT,
        shopId    TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE barcodeUpdateQueue (
        id        TEXT PRIMARY KEY,
        productId TEXT,
        barcode   TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    // ── cashflowCategory ──────────────────────────────────────────────────────
    // NEW: needed to list/select categories offline
    await db.execute('''
      CREATE TABLE cashflowCategory (
        id       TEXT PRIMARY KEY,
        name     TEXT,
        shopId   TEXT,
        type     TEXT,
        createAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE expenseDeleteQueue (
        id        TEXT PRIMARY KEY,
        expenseId TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenseCategoryQueue (
        id        TEXT PRIMARY KEY,
        name      TEXT,
        shopId    TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
     CREATE TABLE expenseCategoryUpdateQueue (
        id         TEXT PRIMARY KEY,
        categoryId TEXT,
        name       TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
     CREATE TABLE expenseCategoryDeleteQueue (
        id         TEXT PRIMARY KEY,
        categoryId TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cashflowCategoryQueue (
        id        TEXT PRIMARY KEY,
        type      TEXT,
        name      TEXT,
        shopId    TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cashflowCategoryUpdateQueue (
        id         TEXT PRIMARY KEY,
        categoryId TEXT,
        name       TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cashflowCategoryDeleteQueue (
        id         TEXT PRIMARY KEY,
        categoryId TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bankQueue (
        id        TEXT PRIMARY KEY,
        name      TEXT,
        shopId    TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bankUpdateQueue (
        id        TEXT PRIMARY KEY,
        bankId    TEXT,
        name      TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bankDeleteQueue (
        id        TEXT PRIMARY KEY,
        bankId    TEXT,
        synced    INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customerUpdateQueue (
        id         TEXT PRIMARY KEY,
        customerId TEXT,
        patch      TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customerDeleteQueue (
        id         TEXT PRIMARY KEY,
        customerId TEXT,
        synced     INTEGER DEFAULT 0,
        syncError  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE productStatsCache (
        shopId      TEXT PRIMARY KEY,
        runninglow  INTEGER,
        outofstock  INTEGER,
        dormant     INTEGER,
        fastmoving  INTEGER,
        cachedAt    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE netAnalysisCache (
        shopId       TEXT PRIMARY KEY,
        totalSales   REAL,
        netProfit    REAL,
        creditTotals REAL,
        totalExpenses REAL,
        cachedAt     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE salesSyncMeta (
        shopId       TEXT PRIMARY KEY,
        lastSyncedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE salesReadCache (
        id          TEXT PRIMARY KEY,
        shopId      TEXT,
        customerId  TEXT,
        attendantId TEXT,
        status      TEXT,
        createdAt   TEXT,
        rawJson     TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAdjustmentsLocal({
    required String productId,
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;
    if (fromDate != null && toDate != null) {
      return await db.rawQuery(
        'SELECT * FROM adjustment WHERE productId = ? AND createdAt >= ? AND createdAt <= ? ORDER BY createdAt DESC',
        [productId, fromDate, '${toDate}T23:59:59.999Z'],
      );
    }
    return await db.rawQuery(
      'SELECT * FROM adjustment WHERE productId = ? ORDER BY createdAt DESC',
      [productId],
    );
  }

  Future<List<Map<String, dynamic>>> getCachedSales({
    required String shopId,
    String? fromDate,
    String? toDate,
    String? customerId,
    String? status,
  }) async {
    final db = await database;
    final where = <String>['shopId = ?'];
    final args = <dynamic>[shopId];

    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('createdAt >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('createdAt <= ?');
      args.add('${toDate}T23:59:59.999');
    }
    if (customerId != null && customerId.isNotEmpty) {
      where.add('customerId = ?');
      args.add(customerId);
    }
    if (status != null && status.isNotEmpty) {
      where.add('status = ?');
      args.add(status);
    }

    return await db.rawQuery(
      'SELECT * FROM salesReadCache WHERE ${where.join(' AND ')} ORDER BY createdAt DESC',
      args,
    );
  }

  Future<Map<String, dynamic>?> getCachedSaleById(String id) async {
    final db = await database;
    final result =
        await db.query('salesReadCache', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<String> getSalesSyncCursor(String shopId) async {
    final db = await database;
    final result = await db
        .query('salesSyncMeta', where: 'shopId = ?', whereArgs: [shopId]);
    // First-ever sync for this shop: start from a fixed, safely-old date
    // rather than "everything since the dawn of time" being ambiguous.
    return result.isNotEmpty
        ? result.first['lastSyncedAt'] as String
        : '2020-01-01';
  }

  Future<void> cacheSalesBatch(List<dynamic> sales) async {
    final db = await database;
    final batch = db.batch();
    for (final sale in sales) {
      final id = sale['_id'];
      if (id == null) continue;
      batch.insert(
        'salesReadCache',
        {
          'id': id,
          'shopId':
              sale['shopId'] is Map ? sale['shopId']['_id'] : sale['shopId'],
          'customerId': sale['customerId'] is Map
              ? sale['customerId']['_id']
              : sale['customerId'],
          'attendantId': sale['attendantId'] is Map
              ? sale['attendantId']['_id']
              : sale['attendantId'],
          'status': sale['status'],
          'createdAt': sale['createdAt'],
          'rawJson': jsonEncode(sale),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setSalesSyncCursor(String shopId, String date) async {
    final db = await database;
    await db.insert(
      'salesSyncMeta',
      {'shopId': shopId, 'lastSyncedAt': date},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheNetAnalysis(String shopId, double totalSales,
      double netProfit, double creditTotals, double totalExpenses) async {
    final db = await database;
    await db.insert(
      'netAnalysisCache',
      {
        'shopId': shopId,
        'totalSales': totalSales,
        'netProfit': netProfit,
        'creditTotals': creditTotals,
        'totalExpenses': totalExpenses,
        'cachedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedNetAnalysis(String shopId) async {
    final db = await database;
    final result = await db
        .query('netAnalysisCache', where: 'shopId = ?', whereArgs: [shopId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> cacheProductStats(
      String shopId, Map<String, dynamic> stats, int fastMovingCount) async {
    final db = await database;
    await db.insert(
      'productStatsCache',
      {
        'shopId': shopId,
        'runninglow': stats['runninglow'] ?? 0,
        'outofstock': stats['outofstock'] ?? 0,
        'dormant': stats['dormant'] ?? 0,
        'fastmoving': fastMovingCount,
        'cachedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedProductStats(String shopId) async {
    final db = await database;
    final result = await db
        .query('productStatsCache', where: 'shopId = ?', whereArgs: [shopId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getLocalProductCategories() async {
    final db = await database;
    return await db.query('productCategory');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // OFFLINE-WRITE QUEUES — insert methods only.
  // Their get/mark/dismiss counterparts were consolidated into the 5 generic
  // methods at the bottom of this file (getUnsyncedRows, getFailedRows,
  // markRowSynced, markRowFailed, _showFailedSyncItemsIfAnyFailedRow), called with the table
  // name as an argument from home.dart's sync functions.
  // ───────────────────────────────────────────────────────────────────────────

  Future<String> insertCustomerUpdateOffline(
      String customerId, Map<String, dynamic> patch) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('customerUpdateQueue', {
      'id': id,
      'customerId': customerId,
      'patch': jsonEncode(patch),
      'synced': 0,
    });
    // Reflect locally right away
    await db.update(
        'customer',
        {
          'name': patch['name'],
          'phoneNumber': patch['phonenumber'],
          'creditLimit': patch['creditLimit'],
          'email': patch['email'],
          'address': patch['address'],
        },
        where: 'id = ?',
        whereArgs: [customerId]);
    return id;
  }

  Future<String> insertCustomerDeleteOffline(String customerId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('customerDeleteQueue',
        {'id': id, 'customerId': customerId, 'synced': 0});
    await db.delete('customer', where: 'id = ?', whereArgs: [customerId]);
    return id;
  }

  Future<String> insertCashflowCategoryOffline(
      String type, String name, String shopId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('cashflowCategoryQueue',
        {'id': id, 'type': type, 'name': name, 'shopId': shopId, 'synced': 0});
    return id;
  }

  Future<String> insertCashflowCategoryUpdateOffline(
      String categoryId, String name) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('cashflowCategoryUpdateQueue',
        {'id': id, 'categoryId': categoryId, 'name': name, 'synced': 0});
    await db.update('cashflowCategory', {'name': name},
        where: 'id = ?', whereArgs: [categoryId]);
    return id;
  }

  Future<String> insertCashflowCategoryDeleteOffline(String categoryId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('cashflowCategoryDeleteQueue',
        {'id': id, 'categoryId': categoryId, 'synced': 0});
    await db
        .delete('cashflowCategory', where: 'id = ?', whereArgs: [categoryId]);
    return id;
  }

  Future<String> insertBankOffline(String name, String shopId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(
        'bankQueue', {'id': id, 'name': name, 'shopId': shopId, 'synced': 0});
    return id;
  }

  Future<String> insertBankUpdateOffline(String bankId, String name) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('bankUpdateQueue',
        {'id': id, 'bankId': bankId, 'name': name, 'synced': 0});
    return id;
  }

  Future<String> insertBankDeleteOffline(String bankId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db
        .insert('bankDeleteQueue', {'id': id, 'bankId': bankId, 'synced': 0});
    return id;
  }

  Future<String> insertExpenseDeleteOffline(String expenseId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(
        'expenseDeleteQueue', {'id': id, 'expenseId': expenseId, 'synced': 0});
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
    return id;
  }

  Future<String> insertExpenseCategoryOffline(
      String name, String shopId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('expenseCategoryQueue',
        {'id': id, 'name': name, 'shopId': shopId, 'synced': 0});
    return id;
  }

  Future<String> insertExpenseCategoryUpdateOffline(
      String categoryId, String name) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('expenseCategoryUpdateQueue',
        {'id': id, 'categoryId': categoryId, 'name': name, 'synced': 0});
    await db.update('expenseCategory', {'name': name},
        where: 'id = ?', whereArgs: [categoryId]);
    return id;
  }

  Future<String> insertExpenseCategoryDeleteOffline(String categoryId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('expenseCategoryDeleteQueue',
        {'id': id, 'categoryId': categoryId, 'synced': 0});
    await db
        .delete('expenseCategory', where: 'id = ?', whereArgs: [categoryId]);
    return id;
  }

  Future<String> insertCategoryOffline(String name, String admin) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('productCategoryQueue',
        {'id': id, 'name': name, 'admin': admin, 'synced': 0});
    return id;
  }

  Future<String> insertProductDeleteOffline(
      String productId, String shopId) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('productDeleteQueue', {
      'id': id,
      'productId': productId,
      'shopId': shopId,
      'synced': 0,
    });
    // Reflect the delete locally right away so it disappears from the list.
    await db.update('products', {'deleted': 1},
        where: 'id = ?', whereArgs: [productId]);
    return id;
  }

  Future<String> insertBarcodeUpdateOffline(
      String productId, String barcode) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('barcodeUpdateQueue', {
      'id': id,
      'productId': productId,
      'barcode': barcode,
      'synced': 0,
    });
    // Reflect locally right away.
    await db.update('products', {'barcode': barcode},
        where: 'id = ?', whereArgs: [productId]);
    return id;
  }

  Future<String> insertShopUpdateOffline(
      String shopId, Map<String, dynamic> patch) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('shopUpdate', {
      'id': id,
      'shopId': shopId,
      'patch': jsonEncode(patch),
      'synced': 0,
    });
    return id;
  }

  Future<String> insertSaleReturnOffline(Map<String, dynamic> data) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('saleReturn', {
      'id': id,
      'saleId': data['saleid'],
      'items': jsonEncode(data['items']),
      'reason': data['reason'],
      'deleteReceipt': (data['deleteReceipt'] == true) ? 1 : 0,
      'shopId': data['shopId'],
      'attendantId': data['attendantId'],
      'synced': 0,
    });
    return id;
  }

  Future<String> insertSalePaymentOffline(Map<String, dynamic> data) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('salePayment', {
      'id': id,
      'saleId': data['saleId'],
      'paymentAmount': data['paymentAmount'],
      'paymentType': data['paymentType'],
      'mpesaCode': data['mpesaCode'],
      'attendantId': data['attendantId'],
      'synced': 0,
    });
    return id;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UTILITY
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> deleteDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pointy_$newVersion.db');
    await deleteDatabase(path);
  }

  Future<String> insertCustomerOffline(Map<String, dynamic> customer) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('customer', {
      'id': id,
      'name': customer['name'],
      'totalDebt': 0,
      'wallet': customer['wallet'] ?? 0,
      'creditLimit': customer['creditLimit'],
      'shopId': customer['shopId'],
      'attendantId': customer['attendantId'],
      'phoneNumber': customer['phoneNumber'] ?? customer['phonenumber'],
      'address': customer['address'],
      'email': customer['email'],
      'sId': id,
      'createAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCustomers() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM customer WHERE synced = 0');
  }

  Future<void> markCustomerSynced(String localId, String realId) async {
    final db = await database;
    await db.update('customer', {'id': realId, 'sId': realId, 'synced': 1},
        where: 'id = ?', whereArgs: [localId]);
  }

  Future<String> insertSupplierOffline(Map<String, dynamic> supplier) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('supplier', {
      'id': id,
      'name': supplier['name'],
      'phoneNumber': supplier['phoneNumber'],
      'shopId': supplier['shopId'],
      'synced': 0,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getSuppliersLocal() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM supplier');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSuppliers() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM supplier WHERE synced = 0');
  }

  Future<void> markSupplierSynced(String localId, String realId) async {
    final db = await database;
    await db.update('supplier', {'id': realId, 'synced': 1},
        where: 'id = ?', whereArgs: [localId]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PRODUCTS
  // ───────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM products WHERE synced = 0');
  }

  // Rewrites every reference to an offline-created product's local id, once
  // that product has synced and received a real server id. Without this,
  // any sale or adjustment queued against the old local id would fail to
  // sync forever, since the server has never heard of "offline_...".
  Future<void> rewriteProductIdReferences(String oldId, String newId) async {
    final db = await database;

    final saleRows = await db.query('sales');
    for (final row in saleRows) {
      final products = jsonDecode(row['products'] as String) as List;
      var changed = false;
      for (final p in products) {
        if (p['product'] == oldId) {
          p['product'] = newId;
          changed = true;
        }
      }
      if (changed) {
        await db.update('sales', {'products': jsonEncode(products)},
            where: 'id = ?', whereArgs: [row['id']]);
      }
    }

    await db.update('adjustment', {'productId': newId},
        where: 'productId = ?', whereArgs: [oldId]);

    await db.update('products', {'id': newId, 'synced': 1},
        where: 'id = ?', whereArgs: [oldId]);
  }

  Future<void> insertProduct(Map<String, dynamic> product,
      {bool synced = true}) async {
    final db = await database;
    await db.insert(
      'products',
      {
        'id': product['_id'],
        'synced': synced ? 1 : 0,
        'name': product['name'],
        'buyingPrice': product['buyingPrice'],
        'sellingPrice': product['sellingPrice'],
        'wholesalePrice': product['wholesalePrice'],
        'dealerPrice': product['dealerPrice'],
        'minSellingPrice': product['minSellingPrice'],
        'quantity': product['quantity'],
        'lastCount': product['lastCount'],
        'maxDiscount': product['maxDiscount'],
        'reorderLevel': product['reorderLevel'],
        'productCategoryId': product['productCategoryId'] is Map
            ? product['productCategoryId']['_id']
            : product['productCategoryId'],
        'measure': product['measure'],
        'deleted': _boolToInt(product['deleted']),
        'taxable': _boolToInt(product['taxable']),
        'supplierId': product['supplierId'] is Map
            ? product['supplierId']['_id']
            : product['supplierId'],
        'shopId': product['shopId'] is Map
            ? product['shopId']['_id']
            : product['shopId'],
        'description': product['description'],
        'attendantId': product['attendantId'] is Map
            ? product['attendantId']['_id']
            : product['attendantId'],
        'lastcoundate': product['lastcoundate'],
        'expiryDate': product['expiryDate'],
        'barcode': product['barcode'],
        'productType': product['productType'],
        'date': product['date'],
        'manufacturer': product['manufacturer'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (product['productCategoryId'] is Map) {
      await db.insert(
        'productCategory',
        {
          'id': product['productCategoryId']['_id'],
          'name': product['productCategoryId']['name'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    if (product['supplierId'] is Map) {
      await db.insert(
        'supplier',
        {
          'id': product['supplierId']['_id'],
          'name': product['supplierId']['name'],
          'phoneNumber': product['supplierId']['phoneNumber'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    if (product['attendantId'] is Map) {
      await db.insert(
        'attendant',
        {
          'id': product['attendantId']['_id'],
          'username': product['attendantId']['username'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        products.*,
        productCategory.name as categoryName,
        shop.name           as shopName,
        shop.address        as shopAddress,
        supplier.name       as supplierName,
        supplier.phoneNumber as supplierPhoneNumber,
        attendant.username  as attendantUsername
      FROM products
      LEFT JOIN productCategory ON products.productCategoryId = productCategory.id
      LEFT JOIN shop     ON products.shopId     = shop.id
      LEFT JOIN supplier ON products.supplierId = supplier.id
      LEFT JOIN attendant ON products.attendantId = attendant.id
    ''');
    return result
        .where((e) =>
            e['shopId'] == userController.currentUser.value?.primaryShop?.id)
        .toList();
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<void> insertProductsBatch(List<dynamic> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        {
          'id': product['_id'],
          'name': product['name'],
          'buyingPrice': product['buyingPrice'],
          'sellingPrice': product['sellingPrice'],
          'wholesalePrice': product['wholesalePrice'],
          'dealerPrice': product['dealerPrice'],
          'minSellingPrice': product['minSellingPrice'],
          'quantity': product['quantity'],
          'lastCount': product['lastCount'],
          'maxDiscount': product['maxDiscount'],
          'reorderLevel': product['reorderLevel'],
          'productCategoryId': product['productCategoryId'] is Map
              ? product['productCategoryId']['_id']
              : product['productCategoryId'],
          'measure': product['measure'],
          'deleted': _boolToInt(product['deleted']),
          'taxable': _boolToInt(product['taxable']),
          'supplierId': product['supplierId'] is Map
              ? product['supplierId']['_id']
              : product['supplierId'],
          'shopId': product['shopId'] is Map
              ? product['shopId']['_id']
              : product['shopId'],
          'description': product['description'],
          'attendantId': product['attendantId'] is Map
              ? product['attendantId']['_id']
              : product['attendantId'],
          'lastcoundate': product['lastcoundate'],
          'expiryDate': product['expiryDate'],
          'barcode': product['barcode'],
          'productType': product['productType'],
          'date': product['date'],
          'manufacturer': product['manufacturer'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Same category/supplier/attendant side-table writes as insertProduct().
      if (product['productCategoryId'] is Map) {
        batch.insert(
          'productCategory',
          {
            'id': product['productCategoryId']['_id'],
            'name': product['productCategoryId']['name'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (product['supplierId'] is Map) {
        batch.insert(
          'supplier',
          {
            'id': product['supplierId']['_id'],
            'name': product['supplierId']['name'],
            'phoneNumber': product['supplierId']['phoneNumber'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (product['attendantId'] is Map) {
        batch.insert(
          'attendant',
          {
            'id': product['attendantId']['_id'],
            'username': product['attendantId']['username'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SALES
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    await db.insert('sales', {
      'clientRef': sale['clientRef'] ??
          'offline_${DateTime.now().millisecondsSinceEpoch}',
      'products': jsonEncode(sale['products']),
      'shopId': sale['shopId'],
      'attendantId': sale['attendantId'],
      'saleType': sale['saleType'],
      'createdAt': sale['createdAt'],
      'status': sale['status'],
      'totaltax': sale['totaltax'],
      'salesnote': sale['salesnote'],
      'duedate': sale['duedate'],
      'mpesaTotal': sale['mpesaTotal'],
      'mpesaTransId': sale['mpesaTransId'],
      'bankTotal': sale['bankTotal'],
      'amountPaid': sale['amountPaid'],
      'paymentType': sale['paymentType'],
      'paymentTag': sale['paymentTag'],
      'totalDiscount': sale['totalDiscount'],
      'totalAmount': sale['totalAmount'],
      'totalWithDiscount': sale['totalWithDiscount'],
      'outstandingBalance': sale['outstandingBalance'],
      'saleDiscount': sale['saleDiscount'],
      'extraCharges': jsonEncode(sale['extraCharges'] ?? []),
      'extraChargesTotal': sale['extraChargesTotal'],
      'orderId': sale['orderId'],
      'customerId': sale['customerId'],
    });
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM sales');
  }

  Future<List<Map<String, dynamic>>> getPendingSales() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM sales WHERE syncError IS NULL');
  }

  Future<List<Map<String, dynamic>>> getFailedSales() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM sales WHERE syncError IS NOT NULL');
  }

  Future<void> markSaleFailed(int id, String error) async {
    final db = await database;
    await db.update('sales', {'syncError': error},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> dismissFailedSale(int id) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSalesByDateLocal({
    String? fromDate,
    String? toDate,
    String? shopId,
  }) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    if (fromDate != null && toDate != null) {
      return await db.rawQuery(
        "SELECT sales.*, attendant.username as attendantUsername "
        "FROM sales LEFT JOIN attendant ON sales.attendantId = attendant.id "
        "WHERE sales.shopId = ? AND sales.createdAt >= ? AND sales.createdAt <= ? "
        "ORDER BY sales.id DESC",
        [shop, fromDate, '${toDate}T23:59:59.999Z'],
      );
    }
    return await db.rawQuery(
      "SELECT sales.*, attendant.username as attendantUsername "
      "FROM sales LEFT JOIN attendant ON sales.attendantId = attendant.id "
      "WHERE sales.shopId = ? ORDER BY sales.id DESC",
      [shop],
    );
  }

  Future<String?> getProductNameById(String id) async {
    final db = await database;
    final result = await db.query('products',
        columns: ['name'], where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first['name'] as String? : null;
  }

  Future<void> deleteSale(int id) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // buildSaleSyncPayload — maps SQLite row back to the exact shape that
  // the server's createSale endpoint expects, including the field name
  // differences (mpesaTotal → server uses 'mpesaTotal' in body, which maps
  // to mpesaNewTotal in the model via the controller logic)
  Map<String, dynamic> buildSaleSyncPayload(Map<String, dynamic> row) {
    return {
      'clientRef': row['clientRef'],
      'products': jsonDecode(row['products']),
      'shopId': row['shopId'],
      'attendantId': row['attendantId'],
      'saleType': row['saleType'],
      'createdAt': row['createdAt'],
      'status': row['status'],
      'totaltax': row['totaltax'],
      'salesnote': row['salesnote'],
      'duedate': row['duedate'],
      'mpesaTotal': row['mpesaTotal'],
      'mpesaTransId': row['mpesaTransId'] ?? '',
      'bankTotal': row['bankTotal'],
      'amountPaid': row['amountPaid'],
      'paymentType': row['paymentType'],
      'paymentTag': row['paymentTag'],
      'totalDiscount': row['totalDiscount'],
      'totalAmount': row['totalAmount'],
      'totalWithDiscount': row['totalWithDiscount'],
      'outstandingBalance': row['outstandingBalance'],
      'saleDiscount': row['saleDiscount'] ?? 0,
      'extraCharges': jsonDecode(row['extraCharges'] ?? '[]'),
      'extraChargesTotal': row['extraChargesTotal'] ?? 0,
      'orderId': row['orderId'],
      'customerId': row['customerId'],
      'allownegativeselling': false,
      'batchTrack': false,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CUSTOMERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> inserCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.insert(
      'customer',
      {
        'id': customer['_id'] ?? customer['id'],
        'phoneNumber': customer['phonenumber'] ?? customer['phoneNumber'],
        'name': customer['name'],
        'totalDebt': customer['totalDebt'] ?? 0,
        'wallet': customer['wallet'] ?? 0,
        'creditLimit': customer['creditLimit'],
        'shopId': customer['shopId'] is Map
            ? customer['shopId']['_id']
            : customer['shopId'],
        'attendantId': customer['attendantId'] is Map
            ? customer['attendantId']['_id']
            : customer['attendantId'],
        'customerNo': customer['customerNo'],
        'address': customer['address'],
        'email': customer['email'],
        'sId': customer['_id'],
        'createAt': customer['createAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM customer');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHOP
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertShop(Map<String, dynamic> shop) async {
    final db = await database;
    final shopData = {
      'id': shop['_id'],
      'name': shop['name'],
      'address': shop['address'],
      'subscriptionId': shop['subscription'] is Map
          ? shop['subscription']['_id']
          : shop['subscription'],
      'shopCategoryId': shop['shopCategoryId'].toString().length > 45
          ? shop['shopCategoryId']['_id']
          : shop['shopCategoryId'],
      'deletewarning': shop['deletewarning'],
      'affliate':
          shop['affliate'] is Map ? shop['affliate']['_id'] : shop['affliate'],
      'backupdate': shop['backupdate'],
      'currency': shop['currency'],
      'backupInterval': shop['backupInterval'],
      'backupemail': shop['backupemail'],
      'allowBackup': _boolToInt(shop['allowBackup'] ?? true),
      'allowOnlineSelling': _boolToInt(shop['allowOnlineSelling'] ?? true),
      'useWarehouse': _boolToInt(shop['useWarehouse']),
      'warehouse': _boolToInt(shop['warehouse']),
      'trackbatches': _boolToInt(shop['trackbatches']),
      // FIX: was never cached — _buildSalePayload read this as null offline
      'allownegativeselling': _boolToInt(shop['allownegativeselling']),
      'tax': shop['tax'] ?? 0,
      'contact': shop['contact'],
      'paybill_till': shop['paybill_till'],
      'paybill_account': shop['paybill_account'],
      'address_receipt': shop['address_receipt'],
      'adminId':
          shop['adminId'] is Map ? shop['adminId']['_id'] : shop['adminId'],
      'createAt': shop['createAt'],
      'coordinates_lat': shop['location']?['coordinates']?[1],
      'coordinates_long': shop['location']?['coordinates']?[0],
    };

    try {
      await db.insert('shop', shopData,
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (shop['subscription'] is Map) {
        await insertSubscription(shop['subscription']);
      }
    } catch (e) {
      print('Error inserting shop: $e');
    }
  }

  Future<dynamic> getAllShops() async {
    final db = await database;
    final result = await db.query('shop');
    final List<Map<String, dynamic>> updated = [];
    for (var shop in result) {
      final m = Map<String, dynamic>.from(shop);
      if (m['subscriptionId'] != null) {
        final sub = await getSubscriptionById(m['subscriptionId']);
        if (sub != null) m['subscription'] = sub;
      }
      m['_id'] = m['id'];
      if (m.containsKey('coordinates_long') &&
          m.containsKey('coordinates_lat')) {
        m['location'] = {
          'type': 'Point',
          'coordinates': [m['coordinates_long'], m['coordinates_lat']],
        };
      }
      updated.add(m);
    }
    return updated;
  }

  Future<Map<String, dynamic>?> getShopById(String? id) async {
    final db = await database;
    final result = await db.query('shop', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final shop = Map<String, dynamic>.from(result.first);
    final sub = await getSubscriptionById(shop['subscriptionId']);
    if (sub != null) {
      shop['subscription'] = sub;
      shop['location'] = {
        'type': 'Point',
        'coordinates': [shop['coordinates_long'], shop['coordinates_lat']],
      };
    }
    return shop;
  }

  Future updateProfilePrimaryShop(shopid) async {
    final db = await database;
    await db.update('users', {'primaryShopId': shopid},
        where: 'id = ?', whereArgs: [userController.currentUser.value!.id]);
    return getUserByEmail(email: userController.currentUser.value!.email);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ATTENDANT
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertAttendant(Map<String, dynamic> attendant) async {
    final db = await database;
    await db.insert(
      'attendant',
      {
        'id': attendant['_id'],
        'username': attendant['username'],
        'shopId': attendant['shopId'] is Map
            ? attendant['shopId']['_id']
            : attendant['shopId'],
        'uniqueDigits': attendant['uniqueDigits'],
        // NEW: needed for offline attendant login and role checks
        'password': attendant['password'],
        'permissions': attendant['permissions'] != null
            ? jsonEncode(attendant['permissions'])
            : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // USERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user['_id'],
        'platform': user['platform'],
        'app_version': user['app_version'],
        'email': user['email'],
        'username': user['username'],
        'usertype': user['usertype'],
        'password': user['password'],
        'phone': user['phone'],
        'createdAt': user['createdAt'],
        'last_seen': user['last_seen'],
        'emailVerified': _boolToInt(user['emailVerified']),
        'phoneVerified': _boolToInt(user['phoneVerified']),
        'emailVerificationDate': user['emailVerificationDate'],
        'affliate': user['affliate'],
        'otp': user['otp'],
        'otp_expiry': user['otp_expiry'],
        'lastSubscriptionReminder': user['lastSubscriptionReminder'],
        'lastSubscriptionReminderCount': user['lastSubscriptionReminderCount'],
        'attendantId': user['attendantId']?['_id'],
        'primaryShopId': user['primaryShop']?['_id'],
        'shopName': user['primaryShop']?['name'],
        'shopAddress': user['primaryShop']?['address'],
        // NEW fields
        'smscredit': user['smscredit'],
        'autoPrint': _boolToInt(user['autoPrint'] ?? true),
        'status': user['status'],
        'syncInterval': user['syncInterval'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (user['primaryShop'] != null) {
      await insertShop(user['primaryShop']);
    }
    if (user['primaryShop']?['subscription'] != null) {
      await insertSubscription(user['primaryShop']['subscription']);
    }
    if (user['primaryShop']?['subscription']?['packageId'] != null) {
      await insertPackageId(user['primaryShop']['subscription']['packageId']);
    }
    if (user['attendantId'] != null) {
      await insertAttendant(user['attendantId']);
    }
  }

  Future getPrimaryShopId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT primaryShopId FROM users');
    return result.first['primaryShopId'];
  }

  Future<Map<String, dynamic>?> getUserByEmail(
      {String? email, String? id}) async {
    final db = await database;
    List<Map<String, dynamic>> userResult = [];
    if (email != null) {
      userResult =
          await db.rawQuery('SELECT * FROM users WHERE email = ?', [email]);
    } else if (id != null) {
      userResult = await db.rawQuery('SELECT * FROM users WHERE id = ?', [id]);
    }
    if (userResult.isEmpty) return null;

    final user = Map<String, dynamic>.from(userResult.first);

    final shopResult = await db
        .rawQuery('SELECT * FROM shop WHERE id = ?', [user['primaryShopId']]);
    if (shopResult.isNotEmpty) {
      user['primaryShop'] = Map<String, dynamic>.from(shopResult.first);
      if (user['primaryShop']['subscriptionId'] != null) {
        final subResult = await db.rawQuery(
            'SELECT * FROM subscription WHERE id = ?',
            [user['primaryShop']['subscriptionId']]);
        if (subResult.isNotEmpty) {
          user['primaryShop']['subscription'] =
              Map<String, dynamic>.from(subResult.first);
          final pkgResult = await db.rawQuery(
              'SELECT * FROM packageId WHERE id = ?',
              [user['primaryShop']['subscription']['packageId']]);
          if (pkgResult.isNotEmpty) {
            user['primaryShop']['subscription']['packageId'] =
                Map<String, dynamic>.from(pkgResult.first);
          }
        }
      }
      user['primaryShop']['_id'] = user['primaryShop']['id'];
    }

    if (user['attendantId'] != null) {
      final attResult = await db.rawQuery(
          'SELECT * FROM attendant WHERE id = ?', [user['attendantId']]);
      if (attResult.isNotEmpty) {
        final att = Map<String, dynamic>.from(attResult.first);
        // Decode permissions JSON back to list for role checks
        if (att['permissions'] != null) {
          att['permissions'] = jsonDecode(att['permissions']);
        }
        user['attendantId'] = att;
      }
    }
    return user;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUBSCRIPTION
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertSubscription(Map<String, dynamic> subscription) async {
    final db = await database;
    await db.insert(
      'subscription',
      {
        'id': subscription['_id'],
        'userId': subscription['userId'],
        'shop': subscription['shop'] is Map
            ? subscription['shop']['_id']
            : subscription['shop'],
        'amount': subscription['amount'],
        'status': _boolToInt(subscription['status']),
        'commission': subscription['commission'],
        'paid': _boolToInt(subscription['paid']),
        'startDate': subscription['startDate'],
        'endDate': subscription['endDate'],
        'createAt': subscription['createAt'],
        'packageId': subscription['packageId'] == null
            ? ''
            : subscription['packageId'] is Map
                ? subscription['packageId']['_id']
                : subscription['packageId'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (subscription['packageId'] is Map) {
      await insertPackageId(subscription['packageId']);
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionById(String id) async {
    final db = await database;
    final result =
        await db.query('subscription', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final sub = Map<String, dynamic>.from(result.first);
    final pkg = await getPackageIdById(sub['packageId']);
    if (pkg != null) sub['packageId'] = pkg;
    return sub;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PACKAGE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertPackageId(Map<String, dynamic> packageId) async {
    final db = await database;
    await db.insert(
      'packageId',
      {
        'id': packageId['_id'],
        'discount': packageId['discount'],
        'title': packageId['title'],
        'description': packageId['description'],
        'durationValue': packageId['durationValue'],
        'durationUnit': packageId['durationUnit'],
        'amount': packageId['amount'],
        'type': packageId['type'],
        'features': packageId['features'] is List
            ? (packageId['features'] as List).join(',')
            : packageId['features'],
        'maxShops': packageId['maxShops'],
        'status': _boolToInt(packageId['status']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getPackageIdById(String id) async {
    final db = await database;
    final result =
        await db.query('packageId', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SETTINGS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertSettings(Map<String, dynamic> settings) async {
    final db = await database;

    // Merge with whatever's already cached — this table holds two
    // independent settings fetches (general config + theme), and a naive
    // REPLACE using only the keys passed in would wipe out whichever set
    // of fields wasn't included in this particular call.
    final existingRows =
        await db.query('settings', where: 'id = ?', whereArgs: [1]);
    final existing = existingRows.isNotEmpty
        ? Map<String, dynamic>.from(existingRows.first)
        : <String, dynamic>{};

    final merged = {
      'id': 1,
      'number_of_image_per_product': settings['number_of_image_per_product'] ??
          existing['number_of_image_per_product'],
      'shop_name': settings['shop_name'] ?? existing['shop_name'],
      'android_version':
          settings['android_version'] ?? existing['android_version'],
      'ios_version': settings['ios_version'] ?? existing['ios_version'],
      'address': settings['address'] ?? existing['address'],
      'demolink': settings['demolink'] ?? existing['demolink'],
      'company_name': settings['company_name'] ?? existing['company_name'],
      'vat_number': settings['vat_number'] ?? existing['vat_number'],
      'post_code': settings['post_code'] ?? existing['post_code'],
      'contact': settings['contact'] ?? existing['contact'],
      'email': settings['email'] ?? existing['email'],
      'website': settings['website'] ?? existing['website'],
      'receipt_size': settings['receipt_size'] ?? existing['receipt_size'],
      'default_currency':
          settings['default_currency'] ?? existing['default_currency'],
      'default_time_zone':
          settings['default_time_zone'] ?? existing['default_time_zone'],
      'default_date_format':
          settings['default_date_format'] ?? existing['default_date_format'],
      'appName': settings['appName'] ?? existing['appName'],
      'google_api_key':
          settings['google_api_key'] ?? existing['google_api_key'],
      'stripe_secret_key':
          settings['stripe_secret_key'] ?? existing['stripe_secret_key'],
      'image': settings['image'] ?? existing['image'],
      'app_name_display':
          settings['app_name_display'] ?? existing['app_name_display'],
      'app_slogan': settings['app_slogan'] ?? existing['app_slogan'],
      'primary_color': settings['primary_color'] ?? existing['primary_color'],
      'button_color': settings['button_color'] ?? existing['button_color'],
      'text_color': settings['text_color'] ?? existing['text_color'],
      'secondary_color':
          settings['secondary_color'] ?? existing['secondary_color'],
      // booleans/ints: only overwrite if explicitly provided this call
      'offlineEnabled': settings.containsKey('offlineEnabled')
          ? _boolToInt(settings['offlineEnabled'])
          : (existing['offlineEnabled'] ?? 0),
      'forceUpdate': settings.containsKey('forceUpdate')
          ? _boolToInt(settings['forceUpdate'])
          : (existing['forceUpdate'] ?? 0),
      'discovershops': settings.containsKey('discovershops')
          ? _boolToInt(settings['discovershops'])
          : (existing['discovershops'] ?? 0),
      'verifyemail': settings.containsKey('verifyemail')
          ? _boolToInt(settings['verifyemail'])
          : (existing['verifyemail'] ?? 0),
    };

    await db.insert(
      'settings',
      merged,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getOfflineSettings() async {
    final db = await database;
    final result = await db.query('settings');
    return result.isNotEmpty ? result.first : null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXPENSES
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      {
        'id': expense['_id'] ?? expense['id'],
        'description': expense['description'],
        'amount': expense['amount'],
        'shopId': expense['shopId'] is Map
            ? expense['shopId']['_id']
            : expense['shopId'],
        'attendantId': expense['attendant'] is Map
            ? expense['attendant']['_id']
            : expense['attendant'] ?? expense['attendantId'],
        'categoryId': expense['category'] is Map
            ? expense['category']['_id']
            : expense['category'],
        'autoSave': _boolToInt(expense['autoSave']),
        'frequency': expense['frequency'],
        'createAt': expense['createAt'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // insertExpenseOffline — called when offline; synced=0 marks it for push
  Future<void> insertExpenseOffline(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert('expenses', {
      'id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
      'description': expense['description'],
      'amount': expense['amount'],
      'shopId': expense['shopId'],
      'attendantId': expense['attendantId'],
      'categoryId': expense['category'],
      'autoSave': _boolToInt(expense['autoSave']),
      'frequency': expense['frequency'] ?? '',
      'createAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses({String? shopId}) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    return await db.rawQuery(
        'SELECT * FROM expenses WHERE shopId = ? ORDER BY createAt DESC',
        [shop]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM expenses WHERE synced = 0');
  }

  Future<void> markExpenseSynced(String id) async {
    final db = await database;
    await db.update('expenses', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXPENSE CATEGORIES
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertExpenseCategory(Map<String, dynamic> cat) async {
    final db = await database;
    await db.insert(
      'expenseCategory',
      {
        'id': cat['_id'] ?? cat['id'],
        'name': cat['name'],
        'shopId': cat['shopId'] is Map ? cat['shopId']['_id'] : cat['shopId'],
        'createAt': cat['createAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getExpenseCategories(
      {String? shopId}) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    return await db
        .rawQuery('SELECT * FROM expenseCategory WHERE shopId = ?', [shop]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PURCHASES
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertPurchase(Map<String, dynamic> purchase) async {
    final db = await database;
    await db.insert(
      'purchase',
      {
        'id': purchase['_id'] ?? purchase['id'],
        'shopId': purchase['shopId'] is Map
            ? purchase['shopId']['_id']
            : purchase['shopId'],
        'supplierId': purchase['supplierId'] is Map
            ? purchase['supplierId']['_id']
            : purchase['supplierId'],
        'attendantId': purchase['attendantId'] is Map
            ? purchase['attendantId']['_id']
            : purchase['attendantId'],
        'paymentType': purchase['paymentType'],
        'totalAmount': purchase['totalAmount'],
        'amountPaid': purchase['amountPaid'],
        'outstandingBalance': purchase['outstandingBalance'],
        'createdAt': purchase['createdAt'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // insertPurchaseOffline — full offline purchase; synced=0 for push later
  Future<String> insertPurchaseOffline(Map<String, dynamic> purchase) async {
    final db = await database;
    final id = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('purchase', {
      'id': id,
      'shopId': purchase['shopId'],
      'supplierId': purchase['supplierId'],
      'attendantId': purchase['attendantId'],
      'paymentType': purchase['paymentType'],
      'totalAmount': purchase['totalAmount'],
      'amountPaid': purchase['amountPaid'] ?? 0,
      'outstandingBalance': purchase['outstandingBalance'] ?? 0,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
    return id;
  }

  Future<void> insertPurchaseItem(
      String purchaseId, Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('purchaseItems', {
      'id': 'pi_${DateTime.now().millisecondsSinceEpoch}_${item['product']}',
      'purchaseId': purchaseId,
      'productId': item['product'],
      'quantity': item['quantity'],
      'unitPrice': item['unitPrice'],
      'lineDiscount': item['lineDiscount'] ?? 0,
      'shopId': item['shop'] ?? item['shopId'],
      'attendantId': item['attendantId'],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases({String? shopId}) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    return await db.rawQuery(
        'SELECT * FROM purchase WHERE shopId = ? ORDER BY createdAt DESC',
        [shop]);
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(String purchaseId) async {
    final db = await database;
    return await db.rawQuery(
        'SELECT * FROM purchaseItems WHERE purchaseId = ?', [purchaseId]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPurchases() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM purchase WHERE synced = 0');
  }

  Future<void> markPurchaseSynced(String id) async {
    final db = await database;
    await db.update('purchase', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STOCK COUNT
  // ───────────────────────────────────────────────────────────────────────────

  // insertStockCountOffline — saves the full products JSON blob for sync later
  Future<void> insertStockCountOffline(Map<String, dynamic> countData) async {
    final db = await database;
    await db.insert('stockCount', {
      'id': 'sc_${DateTime.now().millisecondsSinceEpoch}',
      'shopId': countData['shopId'],
      'attendantId': countData['attendantId'],
      'products': jsonEncode(countData['products']),
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedStockCounts() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM stockCount WHERE synced = 0');
  }

  Future<void> markStockCountSynced(String id) async {
    final db = await database;
    await db.update('stockCount', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ADJUSTMENTS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertAdjustmentOffline(Map<String, dynamic> adj) async {
    final db = await database;
    await db.insert('adjustment', {
      'id': 'adj_${DateTime.now().millisecondsSinceEpoch}',
      'productId': adj['product'],
      'shopId': adj['shop'],
      'type': adj['type'],
      'before': adj['before'],
      'after': adj['after'],
      'adjusted': adj['adjusted'],
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
    // Update local product quantity immediately
    await updateProduct({'id': adj['product'], 'quantity': adj['after']});
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAdjustments() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM adjustment WHERE synced = 0');
  }

  Future<void> markAdjustmentSynced(String id) async {
    final db = await database;
    await db.update('adjustment', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CASHFLOW
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertCashflow(Map<String, dynamic> cf) async {
    final db = await database;
    await db.insert(
      'cashflow',
      {
        'id': cf['_id'] ?? cf['id'],
        'name': cf['name'],
        'amount': cf['amount'],
        'categoryId':
            cf['category'] is Map ? cf['category']['_id'] : cf['category'],
        'attendantId': cf['attendantId'] is Map
            ? cf['attendantId']['_id']
            : cf['attendantId'],
        'shopId': cf['shopId'] is Map ? cf['shopId']['_id'] : cf['shopId'],
        'bankId': cf['bank'] is Map ? cf['bank']['_id'] : cf['bank'],
        'createAt': cf['createAt'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCashflowOffline(Map<String, dynamic> cf) async {
    final db = await database;
    await db.insert('cashflow', {
      'id': 'cf_${DateTime.now().millisecondsSinceEpoch}',
      'name': cf['name'],
      'amount': cf['amount'],
      'categoryId': cf['category'],
      'attendantId': cf['attendantId'],
      'shopId': cf['shopId'],
      'bankId': cf['bank'],
      'createAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getCashflows({String? shopId}) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    return await db.rawQuery(
        'SELECT * FROM cashflow WHERE shopId = ? ORDER BY createAt DESC',
        [shop]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCashflows() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM cashflow WHERE synced = 0');
  }

  Future<void> markCashflowSynced(String id) async {
    final db = await database;
    await db.update('cashflow', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CASHFLOW CATEGORIES
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> insertCashflowCategory(Map<String, dynamic> cat) async {
    final db = await database;
    await db.insert(
      'cashflowCategory',
      {
        'id': cat['_id'] ?? cat['id'],
        'name': cat['name'],
        'shopId': cat['shopId'] is Map ? cat['shopId']['_id'] : cat['shopId'],
        'type': cat['type'],
        'createAt': cat['createAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCashflowCategories(
      {String? shopId}) async {
    final db = await database;
    final shop = shopId ?? userController.currentUser.value?.primaryShop?.id;
    return await db
        .rawQuery('SELECT * FROM cashflowCategory WHERE shopId = ?', [shop]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SYNC HELPERS — call these from home.dart _updateProduct()
  // ───────────────────────────────────────────────────────────────────────────

  // getAllUnsynced — returns a map of every pending offline record across all
  // tables so home.dart can push them all in one place when reconnected
  Future<Map<String, List<Map<String, dynamic>>>> getAllUnsynced() async {
    return {
      'sales':
          await getSales(), // sales table has no synced col — always push & delete
      'expenses': await getUnsyncedExpenses(),
      'purchases': await getUnsyncedPurchases(),
      'stockCounts': await getUnsyncedStockCounts(),
      'adjustments': await getUnsyncedAdjustments(),
      'cashflows': await getUnsyncedCashflows(),
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GENERIC SYNC-QUEUE HELPERS
  // Replace the ~90 near-identical getUnsyncedX/getFailedX/markXSynced/
  // markXFailed/dismissFailedX methods that used to exist per table. Any
  // table with `synced` and `syncError` columns (the 18 queues added in the
  // failure-surfacing work: saleReturn, salePayment, shopUpdate,
  // productCategoryQueue, productDeleteQueue, barcodeUpdateQueue,
  // expenseDeleteQueue, expenseCategoryQueue, expenseCategoryUpdateQueue,
  // expenseCategoryDeleteQueue, cashflowCategoryQueue,
  // cashflowCategoryUpdateQueue, cashflowCategoryDeleteQueue, bankQueue,
  // bankUpdateQueue, bankDeleteQueue, customerUpdateQueue,
  // customerDeleteQueue) can use these directly with the table name as an
  // argument, from home.dart's _syncX functions.
  //
  // Tables that predate this pattern (warehouseRequest, customer, supplier,
  // products, expenses, purchase, stockCount, adjustment, cashflow) have no
  // syncError column and keep their own dedicated methods above/below.
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUnsyncedRows(String table) async {
    final db = await database;
    return await db.rawQuery(
        'SELECT * FROM $table WHERE synced = 0 AND syncError IS NULL');
  }

  Future<List<Map<String, dynamic>>> getFailedRows(String table) async {
    final db = await database;
    return await db
        .rawQuery('SELECT * FROM $table WHERE syncError IS NOT NULL');
  }

  Future<void> markRowSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markRowFailed(String table, String id, String error) async {
    final db = await database;
    await db.update(table, {'syncError': error},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> dismissFailedRow(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
