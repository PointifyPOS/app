import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/main.dart';
import 'package:pointify/services/expenses.dart';
import 'package:pointify/sqlite/helper.dart';
import 'package:pointify/widgets/snackBars.dart';

import '../models/expense.dart';
import '../models/expensecategory.dart';
import '../models/expensestransaction.dart';
import '../utils/helper.dart';
import '../widgets/alert.dart';
import 'cashflowcontroller.dart';

class ExpenseController {
  RxList<ExpenseModel> expenses = RxList([]);
  TextEditingController textEditingControllerAmount = TextEditingController();
  TextEditingController textEditingControllerDate = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  TextEditingController textEditingControllerDescriotion =
      TextEditingController();
  RxList<ExpensesTransactionModel> expensesCategoryTransactions = RxList([]);
  TextEditingController textEditingControllerCategoryName =
      TextEditingController();
  RxList<ExpenseCategory> expensesCategotyWithTotals = RxList([]);
  Rxn<ExpenseCategory> selectedExpensesCategoty = Rxn(null);

  var fromDate = DateTime.now().obs;
  var toDate = DateTime.now().obs;
  RxInt totalExpenses = RxInt(0);
  RxnBool isCreatingExpense = RxnBool(false);
  RxnBool isLoadingExpense = RxnBool(false);
  RxnBool autoSave = RxnBool(false);
  RxMap selectedsaveoption = RxMap({});

  RxList autosaveoptions = RxList([
    {
      'name': 'current_date_of_month',
      'value': 'Date ${DateFormat("dd").format(DateTime.now())} of Every Month'
    },
    {'name': 'daily', 'value': 'Every day'},
    {'name': 'weekday', 'value': 'Every Monday - Friday'},
    {'name': 'weekend', 'value': 'Every Saturday - Sunday'},
    {'name': 'start_of_month', 'value': 'Every Start of Month'},
    {'name': 'end_of_month', 'value': 'Every End of Month'},
    {'name': 'yearly', 'value': 'Every End of Year'},
  ]);

  createExpenses(ExpenseCategory expenseCategory, {String? expenseId}) async {
    try {
      if (textEditingControllerAmount.text.isEmpty) {
        showSnackBar(message: 'enter amount', color: Colors.red);
        return;
      }
      isCreatingExpense.value = true;

      final data = {
        'description': textEditingControllerDescriotion.text,
        'amount': int.parse(textEditingControllerAmount.text),
        'category': expenseCategory.id,
        'autoSave': autoSave.value,
        'frequency': selectedsaveoption['name'] ?? '',
        'attendantId': userController.currentUser.value!.attendantId?.sId,
        'shopId': userController.currentUser.value!.primaryShop?.id,
      };

      final connected = await isConnected();

      if (!connected) {
        // ── offline: queue in SQLite ──
        await DatabaseHelper().insertExpenseOffline(data);
        isCreatingExpense.value = false;
        Get.back();
        Get.find<CashFlowController>().textEditingControllerName.clear();
        textEditingControllerDescriotion.clear();
        textEditingControllerAmount.clear();
        selectedExpensesCategoty.value = null;
        showSnackBar(
            message: 'Expense saved offline — will sync when connected',
            color: Colors.orange);
        // Refresh list from local DB
        await getExpenses();
        return;
      }

      var response = <String, dynamic>{};
      if (expenseId != null && expenseId.isNotEmpty) {
        data['expenseId'] = expenseId;
        response = await ExpensesServices.updateExpenses(expenseId, data);
      } else {
        response = await ExpensesServices.createExpenses(data);
      }

      if (response['error'] != null) {
        showSnackBar(message: response['error'], color: Colors.red);
        isCreatingExpense.value = false;
        return;
      }

      Get.back();
      Get.find<CashFlowController>().textEditingControllerName.clear();
      textEditingControllerDescriotion.clear();
      textEditingControllerAmount.clear();
      selectedExpensesCategoty.value = null;
      isCreatingExpense.value = false;
      getExpenses();
    } on Exception {
      isCreatingExpense.value = false;
    }
  }

  getExpenses(
      {String? shop = '', String? fromDate = '', String? toDate = ''}) async {
    if (fromDate!.isEmpty) {
      fromDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      toDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    final connected = await isConnected();

    if (!connected) {
      // ── offline: read from SQLite ──
      final rows = await DatabaseHelper().getExpenses(
          shopId: userController.currentUser.value?.primaryShop?.id);
      expenses.value = rows
          .map((e) => ExpenseModel.fromJson({
                '_id': e['id'],
                'description': e['description'],
                'amount': e['amount'],
                'createAt': e['createAt'],
                'category': {'_id': e['categoryId']},
              }))
          .toList();
      return;
    }

    // ── online: fetch from server and cache ──
    final raw = await ExpensesServices.getExpenses(
        shop: userController.currentUser.value?.primaryShop!.id,
        fromDate: fromDate,
        toDate: toDate);
    // Guard: returns null when server is unreachable
    if (raw == null || raw is! List) return;
    List response = raw;
    expenses.value = response.map((e) => ExpenseModel.fromJson(e)).toList();

    // Cache each expense in SQLite for offline display
    for (final e in response) {
      await DatabaseHelper().insertExpense(e);
    }
  }

  deleteExpenses(String expenseId) async {
    expenses.removeAt(expenses.indexWhere((e) => e.id == expenseId));

    if (!await isConnected()) {
      if (!hasSyncedServerId(expenseId)) {
        showSnackBar(
            message:
                "This expense hasn't synced yet — connect to the internet before deleting it",
            color: Colors.orange);
        return;
      }
      await DatabaseHelper().insertExpenseDeleteOffline(expenseId);
      showSnackBar(
          message: "Delete saved offline — will sync when connected",
          color: Colors.orange);
      return;
    }

    await ExpensesServices.deleteExpenses(expenseId);
  }

  getExpensesCategorytransactions(String s) async {
    expensesCategoryTransactions.clear();
    final raw2 = await ExpensesServices.getExpensestransactions(s);
    if (raw2 == null || raw2 is! List) return;
    List<dynamic> response = raw2;
    expensesCategoryTransactions.addAll(
        response.map((e) => ExpensesTransactionModel.fromJson(e)).toList());
    expensesCategoryTransactions.refresh();
  }

  createExpensesCategory() async {
    final shopId = userController.currentUser.value?.primaryShop?.id;

    if (!await isConnected()) {
      await DatabaseHelper().insertExpenseCategoryOffline(
          textEditingControllerCategoryName.text, shopId!);
      textEditingControllerCategoryName.clear();
      showSnackBar(
          message: "Category saved offline — will sync when connected",
          color: Colors.orange);
      return;
    }

    final data = {
      'name': textEditingControllerCategoryName.text,
      'shopId': shopId,
    };
    final respose = await ExpensesServices.createExpensesCategory(data);
    if (respose['error'] != null) {
      generalAlert(message: respose['error']);
      return;
    }
    textEditingControllerCategoryName.clear();
    getExpenseCategoryWithTotals();
  }

  getExpenseCategoryWithTotals({
    String? fromDatee = '',
    String? toDatee = '',
  }) async {
    expensesCategotyWithTotals.clear();
    if (fromDatee!.isEmpty) {
      fromDatee = DateFormat('yyyy-MM-dd')
          .format(DateTime(fromDate.value.year, fromDate.value.month, 1));
      toDatee = DateFormat('yyyy-MM-dd').format(toDate.value);
    }
    isLoadingExpense.value = true;

    final connected = await isConnected();

    if (!connected) {
      final rows = await DatabaseHelper().getExpenseCategories(
          shopId: userController.currentUser.value?.primaryShop?.id);
      expensesCategotyWithTotals.addAll(rows
          .map((e) => ExpenseCategory.fromJson({
                '_id': e['id'],
                'name': e['name'],
              }))
          .toList());
      isLoadingExpense.value = false;
      return;
    }

    final rawCat = await ExpensesServices.getExpensesCategoryWithTotals(
        userController.currentUser.value?.primaryShop?.id, fromDatee, toDatee!);
    isLoadingExpense.value = false;
    if (rawCat == null || rawCat is! List) return;
    List<dynamic> response = rawCat;
    expensesCategotyWithTotals
        .addAll(response.map((e) => ExpenseCategory.fromJson(e)).toList());

    for (final cat in response) {
      await DatabaseHelper().insertExpenseCategory(cat);
    }
  }

  Future editExpenseCategory(ExpenseCategory expenseCategory) async {
    if (!await isConnected()) {
      if (!hasSyncedServerId(expenseCategory.id)) {
        showSnackBar(
            message:
                "This category hasn't synced yet — connect to the internet before editing it",
            color: Colors.orange);
        return;
      }
      await DatabaseHelper().insertExpenseCategoryUpdateOffline(
          expenseCategory.id!, textEditingControllerCategoryName.text);
      textEditingControllerCategoryName.clear();
      showSnackBar(
          message: "Update saved offline — will sync when connected",
          color: Colors.orange);
      getExpenseCategoryWithTotals();
      return;
    }

    final data = {'name': textEditingControllerCategoryName.text};
    final respose =
        await ExpensesServices.editExpenseCategory(data, expenseCategory.id!);
    if (respose['error'] != null) {
      generalAlert(message: respose['error']);
      return;
    }
    textEditingControllerCategoryName.clear();
    getExpenseCategoryWithTotals();
  }

  Future<void> deleteExpenseCategory(ExpenseCategory expenseCategory) async {
    if (!await isConnected()) {
      if (!hasSyncedServerId(expenseCategory.id)) {
        showSnackBar(
            message:
                "This category hasn't synced yet — connect to the internet before deleting it",
            color: Colors.orange);
        return;
      }
      await DatabaseHelper()
          .insertExpenseCategoryDeleteOffline(expenseCategory.id!);
      showSnackBar(
          message: "Delete saved offline — will sync when connected",
          color: Colors.orange);
      getExpenseCategoryWithTotals();
      getExpenses();
      return;
    }

    await ExpensesServices.deleteExpensesCategory(expenseCategory.id!);
    getExpenseCategoryWithTotals();
    getExpenses();
  }
}
