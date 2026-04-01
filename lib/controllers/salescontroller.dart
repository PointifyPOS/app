import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointify/controllers/expensecontroller.dart';
import 'package:pointify/controllers/printercontroller.dart';
import 'package:pointify/controllers/productcontroller.dart';
import 'package:pointify/controllers/reports_controller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/main.dart';
import 'package:pointify/models/analysis.dart';
import 'package:pointify/models/cashflow.dart';
import 'package:pointify/models/order.dart';
import 'package:pointify/models/payment.dart';
import 'package:pointify/models/salereturn.dart';
import 'package:pointify/screens/sales/onholdsales.dart';
import 'package:pointify/sqlite/helper.dart';
import 'package:pointify/utils/helper.dart';
import 'package:pointify/widgets/snackBars.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:share_plus/share_plus.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../models/saleitem.dart';
import '../models/salemodel.dart';
import '../models/shop.dart';
import '../screens/customers/customers_page.dart';
import '../screens/customers/wallet_page.dart';
import '../screens/receipts/pdf/sales/sales_receipt.dart';
import '../screens/receipts/view/sales_receipt.dart';
import '../services/sales_service.dart';
import '../utils/colors.dart';
import '../utils/cs50Setup.dart';
import '../utils/sunmi.dart';
import '../widgets/alert.dart';
import '../widgets/loading_dialog.dart';
import 'customercontroller.dart';

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

class HomeCard {
  final double? total;
  final String? name;
  final String? key;
  final Color? color;
  final IconData? iconData;

  HomeCard({this.total, this.name, this.key, this.color, this.iconData});
}

class SalesController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController;
  TextEditingController textEditingSellingPrice = TextEditingController();
  TextEditingController textEditingReturnProduct = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController textEditingCredit = TextEditingController();
  TextEditingController amountPaid = TextEditingController();
  TextEditingController cashPaid = TextEditingController();
  TextEditingController mpesaCashPaid = TextEditingController();
  TextEditingController bankCashPaid = TextEditingController();
  TextEditingController saleDiscount = TextEditingController();
  TextEditingController mpesaTransId = TextEditingController();
  TextEditingController bankTransId = TextEditingController();
  TextEditingController creditAmount = TextEditingController();
  TextEditingController salesnote = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController mpesaCode = TextEditingController();
  TextEditingController salesQtyController = TextEditingController();
  RxList<SaleModel> allSales = RxList([]);
  RxList<SaleModel> allSalesFiltered = RxList([]);
  RxList<SaleModel> allSalesCash = RxList([]);
  RxList<SaleModel> allSalesCashFiltered = RxList([]);
  RxList<SaleItem?> productSales = RxList([]);
  RxList<SaleModel> onholdSales = RxList([]);
  RxList<String> cashsalesfilter = RxList(['cash', 'mpesa', 'bank']);
  RxMap<String, dynamic> cashsalesfilterTotals = RxMap({
    'cash': 0,
    'mpesa': 0,
    'bank': 0,
  });
  RxString duesByDate = RxString("");
  RxList<SaleRetuns> allSalesReturns = RxList([]);
  RxList<OrderItem> orders = RxList([]);
  RxnInt allSalesTotal = RxnInt(0);
  RxMap<String, dynamic> salesPaginageSettings = RxMap({
    "page": 1,
    "limit": 100,
    "total": 0,
    "totalPages": 0,
  });
  RxDouble change = RxDouble(0);
  RxString selectedCustomerType = RxString("Retail");
  RxString changeText = RxString("Change: ");
  RxString cashsalesfilterSelected = RxString("cash");
  RxnInt netProfit = RxnInt(0);
  final GlobalKey<State> keyLoader = GlobalKey<State>();
  RxnInt totalbadStock = RxnInt(0);
  RxnInt totalSalesReturned = RxnInt(0);
  RxList<SaleModel> todaySales = RxList([]);
  final GlobalKey<State> _keyLoader = GlobalKey<State>();
  RxList<SaleItem> productSaleRceipts = RxList([]);
  RxList<Map<String, dynamic>> productMonthSales = RxList([]);
  RxList<SaleModel> salesHistory = RxList([]);
  Rxn<Customer> currentCustomer = Rxn(null);
  Rxn<String> paymentType = Rxn("Cash");
  Rxn<SaleModel> currentReceipt = Rxn(null);
  RxList<Payment> paymenHistory = RxList([]);
  RxList<SaleItem> currentReceiptReturns = RxList([]);
  RxList<SaleModel> creditSales = RxList([]);
  RxInt currentYear = RxInt(DateTime.now().year);
  var filterStartDate = DateFormat(
    "yyy-MM-dd",
  ).format(DateTime(DateTime.now().year, DateTime.now().month, 1)).obs;
  var filterEndDate = DateFormat(
    "yyy-MM-dd",
  ).format(DateTime.now().add(const Duration(days: 1))).obs;
  TextEditingController searchSaleReceiptController = TextEditingController();
  TextEditingController receiptCoutController = TextEditingController(
    text: "1",
  );
  TextEditingController selectedCustomerController = TextEditingController();
  ScrollController scrollController = ScrollController();

  final PageController pageController = PageController(
    initialPage: 1,
    viewportFraction: 0.8,
    keepPage: false,
  );
  RxInt totalSalesByDate = RxInt(0);
  RxInt salesInitialIndex = RxInt(0);
  RxInt tableInitialIndex = RxInt(0);
  RxBool showSalesDiscount = RxBool(false);
  Rxn<Product> selecteProduct = Rxn(null);
  RxBool saveSaleLoad = RxBool(false);
  RxBool showReceipt = RxBool(false);
  RxBool isVoiding = RxBool(false);
  RxBool getSalesByLoad = RxBool(false);
  RxBool getPaymentHistoryLoad = RxBool(false);
  RxBool isUpdating = RxBool(false);
  RxString range = RxString("");
  RxString salesRange = RxString("");

  RxBool salesOrderItemLoad = RxBool(false);
  RxBool salesOnCreditLoad = RxBool(false);
  RxBool loadingMoreSales = RxBool(false);
  RxBool loadingSales = RxBool(false);
  RxList paymentMethods = RxList([
    "Cash",
    "Credit",
    "Wallet",
    "Split Payment",
    "Mpesa",
    "Bank",
  ]);
  RxList customerType = RxList(["Retail", "Wholesale", "Dealer"]);
  RxList receiptpaymentMethods = RxList(["Cash", "Wallet", "Mpesa", "Bank"]);
  Rxn<SaleModel> receipt = Rxn(SaleModel(items: []));
  RxList<SalesData> salesdata = RxList([]);
  RxList<ChartData> dailySales = RxList([]);
  RxList<SalesData> expensesdata = RxList([]);
  RxList<ChartData> productsDatadata = RxList([]);
  RxList<ChartData> productSalesAnalysis = RxList([]);
  RxList<ChartData> productSalesByAttendantsAnalysis = RxList([]);
  RxList<SalesData> profitdata = RxList([]);
  RxList<HomeCard> homecards = RxList([]);
  Rxn<Analysis> analysis = Rxn(null);
  Rxn<DateTime> sellingDate = Rxn(null);

  RxString paynowMethod = RxString("Cash");
  RxString activeItem = RxString("All Sales");
  RxString filterTitle = RxString("Filter by ~");
  RxInt selectedMonth = RxInt(
    DateTime(DateTime.now().year, DateTime.now().month, 1).month,
  );

  var offlinesales = 0.obs;

  getDailySalesGraph({String? fromDate, String? toDate}) async {
    dailySales.clear();
    if (fromDate == null) {
      int y = DateTime.now().year;
      DateTime now = DateTime(y, 1);
      fromDate = DateFormat("MMM-dd").format(DateTime(now.year, now.month, 1));
      DateTime now2 = DateTime(y, 12);
      toDate = DateFormat(
        "MMM-dd",
      ).format(DateTime(now2.year, now2.month + 1, 0));
    }
    var response = await SalesService.getSales(
      shopId: userController.currentUser.value!.primaryShop!.id,
      fromDate: fromDate,
      toDate: toDate,
    );

    List<SaleModel> sales = (response["sales"] as List<dynamic>)
        .map((e) => SaleModel.fromJson(e))
        .toList();
    for (var element in sales) {
      var day = DateFormat(
        "MMM-dd",
      ).format(DateTime.parse(element.createdAt!).toUtc());
      int i = dailySales.indexWhere((element) => element.x == day);
      if (i == -1) {
        dailySales.add(ChartData(day, element.totalWithDiscount!.toDouble()));
      } else {
        dailySales[i] = ChartData(
          day,
          dailySales[i].y + element.totalWithDiscount!.toDouble(),
        );
      }
    }
  }

  getOrders({String? fromDate, String? toDate}) async {
    var response = await SalesService.getOrders(
      fromDate: fromDate,
      toDate: toDate,
      shop: userController.currentUser.value?.primaryShop?.id,
    );
    if (response == null || response["data"] == null) {
      return;
    }
    List<OrderItem> sales = (response["data"] as List<dynamic>)
        .map((e) => OrderItem.fromJson(e))
        .toList();

    orders.value = sales;
  }

  getSaleAmount({SaleModel? saleModel}) {
    String clicked = Get.find<SalesController>().cashsalesfilterSelected.value;
    if (clicked == "cash") {
      return saleModel!.amountPaid!;
    }
    if (clicked == "mpesa") {
      return saleModel!.mpesatotal!;
    }
    if (clicked == "bank") {
      return saleModel!.banktotal!;
    }
  }

  getSingleSaleById({required String id}) async {
    var response = await SalesService.getSingleSaleById(id: id);
    SaleModel saleModel = SaleModel.fromJson(response);
    currentReceipt.value = saleModel;
    currentReceipt.refresh();
    return saleModel;
  }

  getGraphSales({String? fromDate = "", String? toDate = " "}) async {
    Shop shop = userController.currentUser.value!.primaryShop!;
    var salesResponse = await SalesService.getSales(
      shopId: shop.id,
      fromDate: fromDate,
      toDate: toDate,
    );
    List salesData = salesResponse["data"];
    List<SaleModel> sales =
        salesData.map((e) => SaleModel.fromJson(e)).toList();
    salesdata.value = [
      SalesData('Jan', 0),
      SalesData('Feb', 0),
      SalesData('Mar', 0),
      SalesData('Apr', 0),
      SalesData('May', 0),
      SalesData('Jun', 0),
      SalesData('Jul', 0),
      SalesData('Aug', 0),
      SalesData('Sept', 0),
      SalesData('Oct', 0),
      SalesData('Nov', 0),
      SalesData('Dec', 0),
    ];
    for (var element in sales) {
      var month = DateFormat(
        "MMM",
      ).format(DateTime.parse(element.createdAt!).toUtc());
      int i = salesdata.indexWhere((element) => element.year == month);
      if (i == -1) {
        salesdata.add(SalesData(month, element.totalWithDiscount!.toDouble()));
      } else {
        salesdata[i] = SalesData(
          month,
          salesdata[i].sales + element.totalWithDiscount!.toDouble(),
        );
      }
    }
    salesdata.refresh();
    profitdata.value = [
      SalesData('Jan', 0),
      SalesData('Feb', 0),
      SalesData('Mar', 0),
      SalesData('Apr', 0),
      SalesData('May', 0),
      SalesData('Jun', 0),
      SalesData('Jul', 0),
      SalesData('Aug', 0),
      SalesData('Sept', 0),
      SalesData('Oct', 0),
      SalesData('Nov', 0),
      SalesData('Dec', 0),
    ];
    for (var element in sales) {
      var month = DateFormat(
        "MMM",
      ).format(DateTime.parse(element.createdAt!).toUtc());
      int i = profitdata.indexWhere((element) => element.year == month);
      double totalBuyingPrice = element.items!.fold(
        0,
        (previousValue, element) =>
            previousValue + element.product!.buyingPrice! * element.quantity!,
      );
      var totalWithDiscount = element.totalWithDiscount!;
      double total = totalWithDiscount - totalBuyingPrice;
      if (i == -1) {
        profitdata.add(SalesData(month, total.toDouble()));
      } else {
        profitdata[i] = SalesData(month, profitdata[i].sales + total);
      }
      profitdata.refresh();
    }

    List response = await ExpenseController().getExpenses(
      shop: shop.id,
      fromDate: fromDate,
      toDate: toDate,
    );
    expensesdata.value = [
      SalesData('Jan', 0),
      SalesData('Feb', 0),
      SalesData('Mar', 0),
      SalesData('Apr', 0),
      SalesData('May', 0),
      SalesData('Jun', 0),
      SalesData('Jul', 0),
      SalesData('Aug', 0),
      SalesData('Sept', 0),
      SalesData('Oct', 0),
      SalesData('Nov', 0),
      SalesData('Dec', 0),
    ];
    List<CashFlowModel> expenses =
        response.map((e) => CashFlowModel.fromJson(e)).toList();
    for (var element in expenses) {
      var month = DateFormat(
        "MMM",
      ).format(DateTime.parse(element.createAt!).toUtc());
      int i = expensesdata.indexWhere((element) => element.year == month);
      double total = double.parse(element.amount!.toString());
      if (i == -1) {
        expensesdata.add(SalesData(month, total));
      } else {
        expensesdata[i] = SalesData(month, expensesdata[i].sales + total);
      }
      int ei = profitdata.indexWhere((element) => element.year == month);
      if (ei != -1) {
        netProfit.value = SalesData(
          month,
          profitdata[ei].sales - expensesdata[i].sales,
        ).sales.toInt();
      }
    }
  }

  getSalesByAttendants({
    String? fromDate = "",
    String? toDate = "",
    String? attendantId,
  }) async {
    productSalesByAttendantsAnalysis.clear();

    List<dynamic> sales = await SalesService.getMostSellingProduct(
      shopId: userController.currentUser.value?.primaryShop!.id,
      fromDate: fromDate,
      toDate: toDate,
      attendantId: userController.currentUser.value!.attendantId?.sId,
    );
    for (var e in sales) {
      int ai = productSalesByAttendantsAnalysis.indexWhere(
        (element) => element.x == e['attendantName'],
      );
      if (ai == -1) {
        productSalesByAttendantsAnalysis.add(
          ChartData(
            e['attendantName'],
            double.parse(e['totalSales'].toString()),
          ),
        );
      } else {
        productSalesByAttendantsAnalysis[ai] = ChartData(
          e['attendantName'],
          (productSalesByAttendantsAnalysis[ai].y +
              double.parse(e['totalSales'].toString())),
        );
      }
    }
    productSalesByAttendantsAnalysis.refresh();
  }

  getProductComparison({String? fromDate = "", String? toDate = ""}) async {
    productsDatadata.clear();
    productSalesAnalysis.clear();
    List<dynamic> sales = await SalesService.getMostSellingProduct(
      shopId: userController.currentUser.value?.primaryShop!.id,
      fromDate: fromDate,
      toDate: toDate,
    );
    for (var e in sales) {
      int i = productSalesAnalysis.indexWhere(
        (element) => element.x == e["product"],
      );
      if (i == -1) {
        productSalesAnalysis.add(
          ChartData(e["product"], e['totalQuantity'].toDouble()),
        );
      } else {
        productSalesAnalysis[i] = ChartData(
          e["product"],
          (productSalesAnalysis[i].y + e['totalQuantity']).toDouble(),
        );
      }
    }
    for (var e in sales) {
      productsDatadata.add(
        ChartData(e["product"], e['totalQuantity'].toDouble()),
      );
    }
    productsDatadata.refresh();
    productSalesAnalysis.refresh();
    filterTitle.refresh();
  }

  double getProductSellingPrice(Product product) {
    if (selectedCustomerType.value == "Retail" &&
        product.sellingPrice != null &&
        product.sellingPrice! > 0) {
      return product.sellingPrice!;
    }
    if (selectedCustomerType.value == "Wholesale" &&
        product.wholesalePrice != null &&
        product.wholesalePrice! > 0) {
      return product.wholesalePrice!;
    }

    if (selectedCustomerType.value == "Dealer" &&
        product.dealerPrice != null &&
        product.dealerPrice! > 0) {
      return product.dealerPrice!;
    }
    return product.sellingPrice!;
  }

  void addToCart(Product product, {double qty = 1, double lineDiscount = 0}) {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = formatter.format(now);
    double total = getProductSellingPrice(product) * qty;
    SaleItem re = SaleItem(
      product: product,
      tax: product.taxable == true
          ? (userController.currentUser.value?.primaryShop?.tax ?? 0.0) *
              total /
              100
          : 0,
      quantity: qty,
      attendant: Attendant(
        sId: userController.currentUser.value?.attendantId?.sId ?? "",
      ),
      lineDiscount: lineDiscount,
      totalLinePrice: total,
      createdAt: formatted,
      unitPrice: getProductSellingPrice(product),
    );
    Get.back();

    changeSaleItem(re, status: "cashed");
  }

  refreshCart() {
    if (receipt.value != null) {
      List<SaleItem>? saleitems = receipt.value!.items;
      saleitems?.forEach((element) {
        changeSaleItem(element);
      });
    }
  }

  changeSaleItem(
    SaleItem value, {
    String? status =
        "onHold" /*this status is only for not incrementing qty when user is coming from on hold page*/,
  }) {
    var index = -1;
    if (receipt.value != null) {
      index = receipt.value!.items!.indexWhere(
        (element) => element.product!.sId == value.product!.sId,
      );
    }

    if (index == -1) {
      if (receipt.value == null) {
        receipt.value = SaleModel(
          items: [value],
          paymentType: paymentType.value?.toLowerCase(),
          customerId: Get.find<CustomerController>().currentCustomer.value,
        );
      } else {
        receipt.value = SaleModel(
          items: [...?receipt.value!.items, value],
          customerId: Get.find<CustomerController>().currentCustomer.value,
          paymentType: paymentType.value?.toLowerCase(),
        );
      }
      index = receipt.value!.items!.indexWhere(
        (element) => element.product?.sId == value.product?.sId,
      );
      receipt.value!.items![index].id = receipt.value?.sId;
      // receipt.value!.items![index].product!.quantity =
      //     receipt.value!.items![index].product!.quantity! - 1;
    } else {
      //get this specific product from the receipt items
      SaleItem receiptItem = receipt.value!.items![index];
      if (status != "onHold") {
        //increment receipt items qty if its not from on hold page
        double newqty = receipt.value!.items![index].quantity! + 1;

        if (receiptItem.product!.quantity! == 0) {
          return;
        }
        // receipt.value!.items![index].product!.quantity =
        //     receipt.value!.items![index].product!.quantity! - 1;

        receipt.value?.items![index].quantity = newqty;
      }
    }
    calculateAmount(
      index,
      totalDiscount: receipt.value!.items![index].lineDiscount!,
    );
    receipt.refresh();
    refresh();
  }

  decrementItem(index) {
    if (receipt.value!.items![index].quantity == 1) {
      return;
    }

    receipt.value!.items![index].quantity =
        receipt.value!.items![index].quantity! - 1;
    // receipt.value!.items![index].product!.quantity =
    //     receipt.value!.items![index].product!.quantity! + 1;
    receipt.refresh();
    calculateAmount(
      index,
      totalDiscount: receipt.value!.items![index].lineDiscount!,
    );
  }

  incrementItem(index) {
    if (receipt.value!.items![index].product!.quantity! == 0 &&
        receipt.value!.items![index].product?.type == 'product') {
      return;
    }
    receipt.value!.items![index].quantity =
        receipt.value!.items![index].quantity! + 1;

    receipt.refresh();

    calculateAmount(
      index,
      totalDiscount: receipt.value!.items![index].lineDiscount!,
    );
  }

  getTotalCredit() {
    double amountTotalPaid = 0;
    if (paymentType.value == "Split Payment") {
      amountTotalPaid =
          (double.parse(cashPaid.text.isEmpty ? "0" : cashPaid.text) +
              double.parse(
                mpesaCashPaid.text.isEmpty ? "0" : mpesaCashPaid.text,
              ) +
              double.parse(
                bankCashPaid.text.isEmpty ? "0" : bankCashPaid.text,
              ));
      amountPaid.text = amountTotalPaid.toStringAsFixed(2);
    }

    if (paymentType.value == "Cash" ||
        paymentType.value == "Mpesa" ||
        paymentType.value == "Bank") {
      amountTotalPaid = (double.parse(
        amountPaid.text.isEmpty ? "0" : amountPaid.text,
      ));
    }
    if (amountTotalPaid > 0) {
      receipt.value!.outstandingBalance =
          receipt.value!.totalWithDiscount! - amountTotalPaid;
    } else {
      receipt.value!.outstandingBalance = receipt.value!.totalWithDiscount;
    }
    change.value = amountTotalPaid - receipt.value!.totalWithDiscount!;
    creditAmount.text =
        change.value > 0 ? "0" : change.value.abs().toStringAsFixed(2);
    if (receipt.value!.totalWithDiscount! < amountTotalPaid) {
      changeText.value = "Change: ";
      receipt.value!.outstandingBalance = 0;
    } else {
      changeText.value = "Balance Remaining: ";
    }
  }

  calculateAmount(index, {required double totalDiscount}) {
    receipt.value!.totalWithDiscount = 0;
    receipt.value!.outstandingBalance = 0;

    if (selectedCustomerType.value == "Wholesale") {
      receipt.value!.items?.forEach((element) {
        element.unitPrice =
            element.product?.wholesalePrice ?? element.product?.wholesalePrice;
      });
    }

    if (selectedCustomerType.value == "Dealer") {
      receipt.value!.items?.forEach((element) {
        element.unitPrice =
            element.product?.dealerPrice ?? element.product?.dealerPrice;
      });
    }

    receipt.value!.totaltax = receipt.value!.items!.fold(
      0,
      (previousValue, element) =>
          element.product?.taxable == true ? previousValue! + element.tax! : 0,
    );

    double? unitPrice = totalDiscount == 0
        ? receipt.value!.items![index].unitPrice! > 0
            ? receipt.value!.items![index].unitPrice! - totalDiscount
            : getProductSellingPrice(receipt.value!.items![index].product!)
        : getProductSellingPrice(receipt.value!.items![index].product!);

    receipt.value!.items![index].unitPrice = unitPrice - totalDiscount;
    receipt.value?.items![index].lineDiscount = totalDiscount;

    receipt.value!.totalWithDiscount = receipt.value!.items!.fold(
      0,
      (previousValue, element) =>
          previousValue! + (element.unitPrice! * element.quantity!),
    );
    getTotalCredit();
    if (index == -1) {
      return;
    }

    receipt.value?.items![index].totalLinePrice =
        (receipt.value!.items![index].unitPrice! *
            receipt.value!.items![index].quantity!);

    receipt.refresh();
  }

  removeDiscount(index) {
    receipt.value?.items![index].unitPrice =
        receipt.value!.items![index].unitPrice! +
            receipt.value!.items![index].lineDiscount!;
    calculateAmount(index, totalDiscount: 0);
    receipt.refresh();
  }

  removeFromList(index) {
    calculateAmount(
      index,
      totalDiscount: receipt.value!.items![index].lineDiscount!,
    );
    receipt.value?.items!.removeAt(index);
    receipt.value!.totalWithDiscount = receipt.value!.items!.fold(
      0,
      (previousValue, element) =>
          previousValue! +
          (element.unitPrice! - element.lineDiscount!) * element.quantity!,
    );

    receipt.refresh();
  }

  saveSale({screen, status}) async {
    if (paymentType.value == "Credit") {
      if (currentCustomer.value == null) {
        generalAlert(
          title: "Error!",
          message: "You need to select a customer to sell on credit to",
          function: () {
            Get.find<CustomerController>().getCustomersInShop("all");
            Get.to(() => Customers(type: "sale"));
          },
        );
        return;
      }
      showSaleDatePicker();
    } else {
      await saveReceipt(status: status);
    }
  }

  Future updateSaleReceipt({
    required Map<String, dynamic> data,
    SaleModel? salesModel,
    OrderItem? orderItem,
  }) async {
    LoadingDialog.showLoadingDialog(
      context: Get.context!,
      title: "Please wait...",
      key: _keyLoader,
    );
    isUpdating.value = true;
    var response = await SalesService.updateSale(data, salesModel!.sId!);
    isUpdating.value = false;
    if (response["error"] != null) {
      generalAlert(
        message: response["error"],
        title: "Error",
        function: () {
          Get.back();
        },
        positiveText: "Okay",
      );
      return;
    }

    receipt.value = null;
    receipt.value?.items = [];
    selectedCustomerType.value = "Retail";
    amountPaid.clear();
    receipt.refresh();
    selectedCustomerController.clear();

    Get.back();
    if (salesModel.saleType != "Order") {
      Get.to(() => SalesReceipt(salesModel: salesModel, type: ""));
      getSalesByDate(
        type: "today",
        shop: userController.currentUser.value!.primaryShop!.id!,
        status: "hold",
      );
      getNetAnalysis(
        type: "today",
        shopId: userController.currentUser.value!.primaryShop!.id!,
      );
    }
  }

  Future<void> saveReceipt({String? page, String? status}) async {
    SaleModel saleModel = receipt.value!;
    try {
      cashPaid.text = cashPaid.text.isEmpty ? "0.0" : cashPaid.text;
      mpesaCashPaid.text =
          mpesaCashPaid.text.isEmpty ? "0.0" : mpesaCashPaid.text;
      bankCashPaid.text = bankCashPaid.text.isEmpty ? "0.0" : bankCashPaid.text;
      creditAmount.text = creditAmount.text.isEmpty ? "0.0" : creditAmount.text;
      double amountTotalPaid = 0;
      if (paymentType.value == "Split Payment" || paymentType.value == "Cash") {
        if (paymentType.value == "Cash") {
          amountTotalPaid = double.parse(
            amountPaid.text.isEmpty ? "0.0" : amountPaid.text,
          );
        } else if (paymentType.value == "Split Payment") {
          amountTotalPaid = (double.parse(cashPaid.text));
        }
        amountPaid.text = amountTotalPaid.toStringAsFixed(2);
      }
      SaleModel receiptData = receipt.value!;
      var sale = {
        "products": receiptData.items?.map((e) => e.toJson()).toList(),
        "shopId": userController.currentUser.value?.primaryShop?.id ?? "",
        "attendantId": userController.currentUser.value?.attendantId?.sId,
        "saleType": selectedCustomerType.value,
        "createdAt": sellingDate.value == null
            ? DateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
              ).format(DateTime.now())
            : DateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
              ).format(sellingDate.value!),
        "status": status ?? receiptData.status,
        "totaltax": receiptData.totaltax,
        "salesnote": salesnote.text,
        'orderId': receiptData.orderId,
        "duedate": receipt.value!.dueDate,
        "batchTrack":
            userController.currentUser.value?.primaryShop?.allowbatchtracking ??
                false,
        'allownegativeselling': userController
                .currentUser.value?.primaryShop?.allownegativeselling ??
            false,
        "mpesaTransId": mpesaTransId.text.isNotEmpty ? mpesaTransId.text : "",
        'mpesaTotal': paymentType.value == "Mpesa" ||
                (paymentType.value == "Split Payment" &&
                    mpesaCashPaid.text.isNotEmpty)
            ? double.parse(
                mpesaCashPaid.text.isEmpty ? "0.0" : mpesaCashPaid.text,
              )
            : 0.0,
        'bankTotal': paymentType.value == "Bank" ||
                (paymentType.value == "Split Payment" &&
                    bankCashPaid.text.isNotEmpty)
            ? double.parse(
                bankCashPaid.text.isEmpty ? "0.0" : bankCashPaid.text,
              )
            : 0.0,
        "amountPaid":
            amountPaid.text.isEmpty ? 0.0 : double.parse(amountPaid.text),
        "outstandingBalance": receipt.value!.outstandingBalance,
        "paymentType": amountTotalPaid >= receipt.value!.totalWithDiscount! ||
                paymentType.value == "Split Payment"
            ? "cash"
            : paymentType.value?.toLowerCase(),
        "paymentTag": paymentType.value == "Split Payment"
            ? "split"
            : paymentType.value?.toLowerCase(),
        "totalDiscount": receiptData.items?.fold(
          0.0,
          (previousValue, element) => previousValue + element.lineDiscount!,
        ),
        "customerId": currentCustomer.value?.sId,
        'saleDiscount':
            saleDiscount.text.isEmpty ? 0.0 : double.parse(saleDiscount.text),
      };
      if (sale["paymentTag"] == "split") {
        if (receipt.value!.outstandingBalance! > 0) {
          generalAlert(
            title: "Error",
            message:
                "Split payment must be paid in full, balance is ${htmlPrice(receipt.value!.outstandingBalance)}",
            function: () {
              Get.back();
            },
          );
          return;
        }
      }
      Get.back();
      saveSaleLoad.value = true;
      LoadingDialog.showLoadingDialog(
        context: Get.context!,
        title: "Please wait...",
        key: _keyLoader,
      );
      var response = {};
      if (receiptData.sId != null) {
        response = await SalesService.updateSale(sale, receiptData.sId!);
      } else {
        if (!await isConnected()) {
          generalAlert(
            title: "There is no internet connection, proceed with cash sale?",
            function: () {
              saveOfflinesale(sale, receiptData);
            },
          );
          return;
        } else {
          response = await SalesService.createSale(sale);
        }
      }
      Get.back();

      saveSaleLoad.value = false;

      if (response["error"] != null) {
        generalAlert(
          message: response["error"],
          title: "Error",
          function: () {
            if (receiptData.customerId != null) {
              Get.find<CustomerController>().currentCustomer.value =
                  receiptData.customerId!;
              Get.to(() => WalletPage());
            }
          },
          positiveText: "Okay",
        );
        return;
      }

      if (status == "hold") {
        showSnackBar(message: "sale put on hold", color: Colors.green);
        getSalesByDate(
          shop: userController.currentUser.value!.primaryShop!.id!,
          status: "hold",
        );
        Get.to(() => OnHoldSales());
        refresh();
      } else {
        Get.back();
      }
      receipt.value = null;
      _clearAfterSale();
    } catch (e) {
      showSnackBar(message: e.toString(), color: Colors.red);
      saveSaleLoad.value = false;
    } finally {
      getSalesByDate(
        type: "today",
        shop: userController.currentUser.value!.primaryShop!.id!,
      );

      getNetAnalysis(
        type: "today",
        shopId: userController.currentUser.value!.primaryShop!.id!,
      );
      // if (saleModel.sId != null) {
      _printReceipt(saleModel);
      // }
      Get.find<ProductController>().getProductsBySort(type: 'all');
      sellingDate.value = null;
    }
  }

  void _clearAfterSale() {
    currentCustomer.value = null;
    receipt.value?.items = [];
    saleDiscount.clear();
    paymentType.value = "Cash";
    mpesaCashPaid.clear();
    bankCashPaid.clear();
    creditAmount.clear();
    textEditingSellingPrice.clear();
    cashPaid.clear();
    selectedCustomerType.value = "Retail";
    salesnote.clear();
    amountPaid.clear();
    receipt.refresh();
    selectedCustomerController.clear();
  }

  _printReceipt(SaleModel saleModel) {
    return showDialog(
      context: Get.context!,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Print Receipt?",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("How many receipts to print?"),
              const SizedBox(height: 5),
              TextFormField(
                controller: receiptCoutController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: Text(
                "No".toUpperCase(),
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                Get.back();
                reprintReceipt(
                  saleModel: saleModel,
                );
              },
              child: Text(
                "Yes print".toUpperCase(),
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  saveOfflinesale(Map<String, dynamic> sale, SaleModel receiptData) async {
    Get.back();
    DatabaseHelper().insertSale(sale);
    receiptData.items?.forEach((element) {
      DatabaseHelper().updateProduct({
        'id': element.product?.sId,
        'quantity': element.product!.quantity,
      });
    });
    offlinesales.value += 1;
    Get.find<ProductController>().getProductsBySort(type: 'all');
    saveSaleLoad.value = false;
    receipt.value = null;
    currentCustomer.value = null;
    receipt.value?.items = [];
    paymentType.value = "Cash";
    mpesaCashPaid.clear();
    bankCashPaid.clear();
    creditAmount.clear();
    textEditingSellingPrice.clear();
    cashPaid.clear();
    selectedCustomerType.value = "Retail";
    salesnote.clear();
    amountPaid.clear();
    receipt.refresh();
    selectedCustomerController.clear();
    Get.back();
    Get.back();
  }

  showSaleDatePicker() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        color: Colors.white,
        margin: const EdgeInsets.only(left: 0),
        height: MediaQuery.of(context).copyWith().size.height * 0.50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Text(
                "Select Due date".capitalize!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).copyWith().size.height * 0.3,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (value) {
                  receipt.value!.dueDate = value.toIso8601String();
                  receipt.refresh();
                },
                initialDateTime: DateTime.now(),
                minimumYear: 2022,
                maximumYear: 2050,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel".toUpperCase(),
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Get.back();
                    if (receipt.value!.dueDate == null) {
                      receipt.value!.dueDate =
                          DateFormat('MMMM/dd/yyyy hh:mm a')
                              .parse(
                                DateFormat(
                                  'MMMM/dd/yyyy hh:mm a',
                                ).format(DateTime.now()),
                              )
                              .toIso8601String();
                    }

                    Get.back();
                    await saveReceipt(status: "cashed");
                  },
                  child: Text(
                    "Ok".toUpperCase(),
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  // Timer? _timer;
  //
  @override
  void onClose() {
    // _timer?.cancel(); // Cancel the timer before disposing of the controller
    pageController
        .dispose(); // Dispose of the controller when the page is closed
    super.onClose();
  }

  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this);
    scrollController.addListener(_scrollListener);
    super.onInit();
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !loadingMoreSales.value) {
      print("Load more data");
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (salesPaginageSettings['totalPages'] == salesPaginageSettings['page']) {
      return;
    }
    print("Load more data 2");
    salesPaginageSettings["page"] = salesPaginageSettings["page"] + 1;

    getSalesByDate(
      shop: userController.currentUser.value!.primaryShop!.id!,
      fromDate: Get.find<ReportsController>().filterStartDate.value,
      toDate: Get.find<ReportsController>().filterEndDate.value,
      loadMore: true,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  //
  returnSale({
    String? saledId,
    List<dynamic>? returnItems,
    bool deleteReceipt = false,
    String from = "sales",
  }) async {
    try {
      LoadingDialog.showLoadingDialog(
        context: Get.context!,
        title: deleteReceipt == true
            ? "Deleting receipt..."
            : "Returning receipt...",
        key: _keyLoader,
      );
      int i = allSales.indexWhere((element) => element.sId == saledId);
      if (i != -1) {
        allSales.removeAt(i);
      }
      var returnData = {
        "saleid": saledId,
        "attendantId": userController.currentUser.value?.attendantId?.sId,
        "shopId": userController.currentUser.value?.primaryShop?.id,
        "items": returnItems,
        "reason": "test",
        "deleteReceipt": deleteReceipt,
      };
      print(returnData);
      var response = await SalesService.returnItem(returnData);
      if (currentReceipt.value != null) {
        var itemsQty = returnItems!.fold(
          0.0,
          (previousValue, element) => previousValue + element["quantity"],
        );
        double totalitemsQty = currentReceipt.value!.items!.fold(
          0.0,
          (previousValue, element) => previousValue + element.quantity!,
        );

        if (itemsQty == totalitemsQty) {
          Get.back();
        }
      }
      if (response["error"] != null) {
        Get.back();
        generalAlert(title: "Error", message: response["error"]);
        return;
      }
      if (from == "customerpage") {
        Get.back();
      }
      if (from == "productsales") {
        Get.back();
        Get.find<ReportsController>().productsWisereport(
          fromDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          toDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          shop: userController.currentUser.value!.primaryShop!.id!,
          showLoader: false,
        );
        return;
      } else {
        getSalesByDate(
          type: Get.find<ReportsController>().activeFilter.value,
          fromDate: filterStartDate.value,
          toDate: filterEndDate.value,
          status: "cashed",
          shop: userController.currentUser.value!.primaryShop!.id!,
        );
        getNetAnalysis(
          type: Get.find<ReportsController>().activeFilter.value,
          fromDate: filterStartDate.value,
          toDate: filterEndDate.value,
          shopId: userController.currentUser.value!.primaryShop!.id!,
        );
      }
      if ((deleteReceipt == true || response["deleteReceipt"] != null) &&
          from != 'productsales') {
        Get.back();
      } else {
        if (response["deleted"] != null) {
          if (response["deleted"] == true) {
            Get.back();
            return;
          }
        }
        currentReceipt.value = SaleModel.fromJson(response["saleReturn"]);
        currentReceipt.refresh();
        Get.back();
      }
      generalAlert(
        title: "Return receipt",
        message: "receipt returned successfully",
      );
    } catch (e) {
      Get.back();
      showSnackBar(message: e.toString(), color: Colors.red);
    } finally {
      Get.find<ProductController>().getProductsBySort(type: 'all');
    }
  }

  payCredit({required SaleModel salesBody, required int amount}) async {
    var paymentData = {
      "saleId": salesBody.sId,
      "paymentAmount": amount,
      "paymentType": paynowMethod.value,
      "mpesaCode": mpesaCode.text,
      "attendantId": userController.currentUser.value?.attendantId?.sId,
    };

    var response = await SalesService.payCredit(paymentData);
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
      return;
    }
    currentReceipt.value?.outstandingBalance = toDouble(
      response["outstandingBalance"],
    );

    currentReceipt.refresh();
    amountController.clear();
  }

  getSalesByDate({
    String? fromDate = "",
    String? toDate = "",
    String? dueDate = "",
    String? paymentTag = "",
    String? type = "",
    String? order = "",
    String? status = "",
    String? paymentType = "",
    String? receiptNo = "",
    String? saleType = "",
    bool? production = false,
    bool? loadMore = false,
    String? customerid = "",
    String? shop = "",
  }) async {
    loadingSales.value = false;
    if (loadingSales.value == true) {
      return;
    }
    if (loadMore == true) {
      loadingMoreSales.value = true;
    } else {
      salesPaginageSettings["page"] = 1;
      loadingSales.value = true;
      allSalesFiltered.clear();
      allSales.clear();
      if (status == "hold") {
        onholdSales.clear();
        refresh();
      } else {
        todaySales.clear();
        creditSales.clear();
      }
    }
    if (type == "today") {
      fromDate = DateFormat("yyy-MM-dd").format(DateTime.now());
      toDate = DateFormat("yyy-MM-dd").format(DateTime.now());
    }
    var response = await SalesService.getSales(
      fromDate: fromDate,
      saleType: saleType,
      dueDate: dueDate,
      toDate: toDate,
      paymentTag: paymentTag,
      order: order,
      production: production,
      receiptNo: receiptNo,
      status: status,
      shopId: shop,
      paymentType: paymentType,
      customerId: customerid,
      page: salesPaginageSettings["page"] ?? 1,
      limit: 50,
    );
    loadingMoreSales.value = false;
    loadingSales.value = false;
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
      return;
    }
    List<SaleModel> salesObjects = [];
    List<dynamic> sales = response["data"];
    salesObjects = sales.map((e) => SaleModel.fromJson(e)).toList();

    if (loadMore == true) {
      allSales.addAll(salesObjects);
    } else {
      allSales.value = salesObjects;
    }
    allSalesFiltered.value = allSales;
    // allSalesFiltered.addAll(allSales);
    salesPaginageSettings["total"] = response["total"];
    salesPaginageSettings["page"] = response["currentPage"];
    salesPaginageSettings["totalPages"] = response["totalPages"];
    if (status == "hold") {
      onholdSales.addAll(salesObjects);
    } else {
      creditSales.addAll(
        salesObjects
            .where(
              (p0) => p0.paymentType == "credit" && p0.outstandingBalance! > 0,
            )
            .toList(),
      );
    }
    // getSalesByCashSaleFilter(type: cashsalesfilterSelected.value);
    // getfilterTotals();
  }

  getProductSales({
    String? fromDate = "",
    String? toDate = "",
    String? product = "",
  }) async {
    loadingSales.value = true;
    productSaleRceipts.clear();
    var response = await SalesService.getProductSales(
      fromDate: fromDate,
      toDate: toDate,
      product: product,
    );
    loadingSales.value = false;
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
      return;
    }
    List<dynamic> sales = response["sales"];
    productSaleRceipts.addAll(sales.map((e) => SaleItem.fromJson(e)).toList());
    productSaleRceipts.refresh();
  }

  getNetAnalysis({
    required String shopId,
    String? fromDate = "",
    String? toDate = "",
    String? type,
    String? duesales = "",
  }) async {
    if (type == "today") {
      fromDate = DateFormat("yyy-MM-dd").format(DateTime.now());
      toDate = DateFormat("yyy-MM-dd").format(DateTime.now());
    }
    var response = await SalesService.netAnalysis(
      fromDate: fromDate,
      toDate: toDate,
      shopId: userController.currentUser.value?.primaryShop?.id,
      type: type,
      duesales: duesales,
    );
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
    }
    homecards.clear();
    if (response["totalProfitAndSalesValue"] != null) {
      Map<String, dynamic> data = response["totalProfitAndSalesValue"];
      Map<String, dynamic> expensedata = response["totalExpenses"];
      Map<String, dynamic> badstockdata = response["badStockValue"];
      homecards.add(
        HomeCard(
          total: double.parse(data['totalSales'].toString()),
          name: "Today Sales",
          key: 'sales',
          color: AppColors.secondary_color,
          iconData: Icons.auto_graph_rounded,
        ),
      );
      if (verifyPermission(category: 'sales', permission: 'view_profit')) {
        homecards.add(
          HomeCard(
            total: (double.parse(response['net'].toStringAsFixed(2)) +
                double.parse(response['totalTaxes'].toStringAsFixed(2))),
            name: "Today Profit",
            key: 'profit',
            color: AppColors.button_color,
            iconData: Icons.auto_graph_rounded,
          ),
        );
      }
      homecards.add(
        HomeCard(
          total: double.parse(response['creditTotals'].toString()),
          name: "Today Dues",
          key: 'dues',
          color: AppColors.mainColor,
          iconData: Icons.auto_graph_rounded,
        ),
      );
      if (verifyPermission(category: 'expenses', permission: 'view')) {
        homecards.add(
          HomeCard(
            total: double.parse(expensedata['totalExpenses'].toString()),
            name: "Today Expenses",
            key: 'expenses',
            color: AppColors.secondary_color,
            iconData: Icons.auto_graph_rounded,
          ),
        );
      }

      analysis.value = Analysis(
        totalExpenses: expensedata['totalExpenses'],
        totalPurchases: data['totalPurchases'] ?? 0,
        totalSales: data['totalSales'],
        debtPaid: response['debtPaid'] ?? 0,
        totalCashSales: data['totalCashSales'] ?? 0,
        creditTotals: response['creditTotals'] ?? 0,
        totalTaxes: isInteger(data['totalTaxes'])
            ? data['totalTaxes'].toDouble()
            : data['totalTaxes'] ?? 0.0,
        gross: response['gross'],
        net: isInteger(response['net'])
            ? response['net'].toDouble()
            : response['net'] ?? 0.0,
        profitOnSales: data['totalProfit'],
        badStockValue: badstockdata['badStockValue'],
      );
    }
  }

  bool isInteger(num value) => value is int || value == value.roundToDouble();

  Future<void> getReturns({
    Customer? customerModel,
    SaleModel? salesModel,
    Product? product,
    String? fromDate,
    required String shopid,
    String? type,
    String? toDate,
  }) async {
    currentReceiptReturns.clear();
    allSalesReturns.clear();
    if (loadingSales.value == true) {
      return;
    }
    loadingSales.value = true;
    List<dynamic> response = await SalesService.getSalesRetuns(
      salesModel: salesModel,
      customerModel: customerModel,
      product: product,
      type: type,
      fromDate: fromDate,
      shopid: shopid,
      toDate: toDate,
    );
    loadingSales.value = false;
    allSalesReturns.addAll(
      response.map((e) => SaleRetuns.fromJson(e)).toList(),
    );
    allSalesReturns.refresh();
  }

  Future<void> deleteSaleReturn(String saleReturnId) async {
    allSalesReturns.removeAt(
      allSalesReturns.indexWhere((element) => element.sId == saleReturnId),
    );
    Get.back();
    await SalesService.deleteSaleReturn(saleReturnId);
  }

  getSalesByProductId({
    Product? product,
    String? fromDate,
    String? toDate,
  }) async {
    productMonthSales.clear();

    if (fromDate == null) {
      fromDate = DateFormat("yyy-MM-dd").format(DateTime.now());
      toDate = DateFormat(
        "yyy-MM-dd",
      ).format(DateTime.now().add(const Duration(days: 1)));
    }

    var response = await SalesService.getProductSalesGroupedByMonth(
      startDate: fromDate,
      endDate: toDate,
      product: product!.sId,
      shopId: userController.currentUser.value!.primaryShop!.id,
    );
    List sales = response;
    productMonthSales.addAll(
      sales
          .map(
            (e) => {
              "month": e["month"],
              "sales": e["sales"],
              "count": e["count"],
              "totalQuantity": e["totalQuantity"],
            },
          )
          .toList(),
    );
    productMonthSales.refresh();
    return;
  }

  Future<void> voidReceipt(SaleModel salesModel) async {
    LoadingDialog.showLoadingDialog(
      context: Get.context!,
      title: "Voiding receipt...",
      key: _keyLoader,
    );
    isVoiding.value = true;
    var response = await SalesService.voidSale(salesModel.sId!);
    Get.back();
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
      return;
    }

    isVoiding.value = false;
    if (onholdSales.indexWhere((element) => element.sId == salesModel.sId) !=
        -1) {
      showSnackBar(message: response["message"], color: Colors.green);
      onholdSales.removeAt(
        onholdSales.indexWhere((element) => element.sId == salesModel.sId),
      );
      onholdSales.refresh();
    } else {
      Get.back();
    }
  }

  Future<void> sharePdf(SaleModel salesModel) async {
    var f = salesReceipt(salesModel, "");
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/${salesModel.sId!}.pdf';

    await File(path).writeAsBytes(await f);
    Share.shareXFiles([XFile(path)], text: 'Poinitify receipt');
  }

  void sendReportEmail({
    String? fromDate = "",
    String? toDate = "",
    String? email = "",
    String? shop = "",
    String? paymentTag = "",
    String? status = "",
  }) async {
    LoadingDialog.showLoadingDialog(
      context: Get.context!,
      title: "Please wait...",
      key: _keyLoader,
    );
    var response = await SalesService.sendReportEmail(
      fromDate: fromDate,
      toDate: toDate,
      email: email,
      shop: shop,
      paymentTag: paymentTag,
      status: status,
    );
    Get.back();
    Get.back();
    generalAlert(message: response["message"], title: "Success");
    print(response);
  }

  void deleteOrder(OrderItem salesModel) async {
    orders.removeAt(
      orders.indexWhere((element) => element.sId == salesModel.sId),
    );
    await SalesService.deleteOrder(salesModel.sId!);
  }

  Future<void> reprintReceipt({required SaleModel saleModel}) async {
    for (int i = 0; i < int.parse(receiptCoutController.text); i++) {
      Sunmi printer = Sunmi();
      printer.printReceipt(
        saleModel: saleModel,
        receiptTitle: "Cash Sale Receipt",
      );

      Cs50PrinterSetup().printReceipt(
          saleModel: saleModel, receiptTitle: "Cash Sale Receipt");

      var items = saleModel.items!
          .map(
            (e) => {
              "name": "${e.product?.name} ${e.product?.measureUnit ?? ""}",
              "qty": e.quantity,
              "price": e.unitPrice,
            },
          )
          .toList();
      List<int> ticket = await Get.find<PrinterController>().printSalesReceipt(
          items: items,
          storeName: saleModel.shopId?.name ?? "Pointify",
          phone: saleModel.shopId?.contact ?? "",
          email: saleModel.shopId?.receiptemail ?? "",
          address: saleModel.shopId?.addressReceipt ?? "",
          paybill: saleModel.shopId?.paybillTill ?? "",
          paybillAccount: saleModel.shopId?.paybillAccount ?? "",
          paymentType: saleModel.paymentType ?? "Cash",
          customer: saleModel.customerId?.name ?? "",
          date: saleModel.createdAt ?? "",
          receiptUrl: "https://store.pointifypos.com");
      await PrintBluetoothThermal.writeBytes(ticket);
    }
  }

  Future<void> getDuesByDate(
      {required String shop, required String dueDate}) async {
    var response =
        await SalesService.getDuesByDate(shop: shop, dueDate: dueDate);
    if (response["error"] != null) {
      showSnackBar(message: response["error"], color: Colors.red);
      return;
    }
    duesByDate.value = response["dues"];
    duesByDate.refresh();
  }
}
