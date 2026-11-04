import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pointify/controllers/customercontroller.dart';
import 'package:pointify/controllers/quick_sale_controller.dart';
import 'package:pointify/controllers/salescontroller.dart';
import 'package:pointify/functions/functions.dart';

import '../../utils/colors.dart';

final _money = NumberFormat('#,##0.##');
const _bg = Color(0xFFF4F5F9);

/// Sell without stocking first: type name + price (+ qty), add as many rows as
/// needed, then go to payment/receipt. New items are remembered for next time.
class QuickSale extends StatefulWidget {
  const QuickSale({super.key});

  @override
  State<QuickSale> createState() => _QuickSaleState();
}

class _QuickSaleState extends State<QuickSale> {
  late final QuickSaleController c;
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    c = Get.put(QuickSaleController());
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _priceFocus.dispose();
    Get.delete<QuickSaleController>();
    // Don't leave a half-built cart behind for the normal POS screen.
    // Deferred: changing an Rx value while the tree is being finalized throws.
    final sales = Get.find<SalesController>();
    final customers = Get.find<CustomerController>();
    Future.microtask(() {
      if (sales.receipt.value?.sId == null) sales.receipt.value = null;
      sales.currentCustomer.value = null;
      sales.selectedCustomerController.clear();
      sales.selectedCustomerType.value = 'Retail';
      customers.currentCustomer.value = null;
    });
    super.dispose();
  }

  void _add() {
    if (c.addCurrent()) _nameFocus.requestFocus();
  }

  void _bumpEntryQty(double delta) {
    final current = double.tryParse(c.qtyController.text) ?? 1;
    final next = (current + delta).clamp(1, 99999).toDouble();
    c.qtyController.text =
        next == next.roundToDouble() ? next.toStringAsFixed(0) : '$next';
  }

  InputDecoration _fieldDecoration(String label,
      {String? hint, String? prefix, Widget? suffix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: _bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.mainColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.mainColor;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Quick sale',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          Obx(() => c.lines.isEmpty
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: c.reset,
                  child: const Text('Clear all'),
                )),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    _customerBar(accent),
                    const SizedBox(height: 8),
                    _entryCard(accent),
                    const SizedBox(height: 12),
                    _cart(accent),
                  ],
                ),
              ),
            ),
            _footer(accent),
          ],
        ),
      ),
    );
  }

  // ─── customer ──────────────────────────────────────────────────────────

  Widget _customerBar(Color accent) {
    return Obx(() {
      final cust = c.customer.value;
      final canPickType =
          verifyPermission(category: 'pos', permission: 'can_sell_to_dealer_&_wholesaler') == true;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded,
                size: 20, color: cust == null ? Colors.grey : accent),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: c.openCustomerPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    cust?.name ?? 'Walk-in customer · tap to choose',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight:
                            cust == null ? FontWeight.w500 : FontWeight.w700,
                        color: cust == null ? Colors.grey.shade600 : null),
                  ),
                ),
              ),
            ),
            if (cust != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: c.clearCustomer,
              ),
            if (canPickType)
              PopupMenuButton<String>(
                tooltip: 'Price type',
                onSelected: c.setCustomerType,
                itemBuilder: (_) => [
                  for (final t in const ['Retail', 'Wholesale', 'Dealer'])
                    PopupMenuItem(value: t, child: Text(t)),
                ],
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.customerType.value,
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                      Icon(Icons.arrow_drop_down, size: 18, color: accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ─── entry card ────────────────────────────────────────────────────────

  Widget _entryCard(Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: c.nameController,
            focusNode: _nameFocus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: c.onNameChanged,
            onSubmitted: (_) => _priceFocus.requestFocus(),
            decoration: _fieldDecoration(
              'Item name',
              hint: 'Type to find a saved item',
              suffix: Obx(() => c.searching.value
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const SizedBox.shrink()),
            ),
          ),
          Obx(() {
            if (c.suggestions.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final p in c.suggestions)
                    ActionChip(
                      backgroundColor: accent.withOpacity(0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      label: Text(
                        '${p.name ?? ''} · ${_money.format(p.sellingPrice ?? 0)}',
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        c.pickSuggestion(p);
                        _priceFocus.requestFocus();
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: c.priceController,
                  focusNode: _priceFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: _fieldDecoration('Price'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              _stepper(
                onMinus: () => _bumpEntryQty(-1),
                onPlus: () => _bumpEntryQty(1),
                center: SizedBox(
                  width: 36,
                  child: TextField(
                    controller: c.qtyController,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _add,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required Widget center,
  }) {
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: AppColors.mainColor),
          ),
        );
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [btn(Icons.remove, onMinus), center, btn(Icons.add, onPlus)],
      ),
    );
  }

  // ─── cart ──────────────────────────────────────────────────────────────

  Widget _cart(Color accent) {
    return Obx(() {
      if (c.lines.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.shopping_basket_outlined,
                  size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 6),
              Text('No items yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(
                'New items are saved for next time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('SALE ITEMS',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600)),
          ),
          for (var i = 0; i < c.lines.length; i++) _lineCard(i, accent),
        ],
      );
    });
  }

  Widget _lineCard(int i, Color accent) {
    final l = c.lines[i];
    return Dismissible(
      key: ObjectKey(l),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => c.removeAt(i),
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _editLine(i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(l.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        if (l.product == null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('NEW',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${_money.format(l.price)} each',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            _stepper(
              onMinus: () {
                if (l.qty > 1) c.updateLine(i, qty: l.qty - 1);
              },
              onPlus: () => c.updateLine(i, qty: l.qty + 1),
              center: SizedBox(
                width: 36,
                child: Text(_money.format(l.qty),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(_money.format(l.total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _editLine(int i) async {
    final l = c.lines[i];
    final price = TextEditingController(text: l.price.toString());
    final qty = TextEditingController(text: l.qty.toString());
    final ok = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration('Price'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration('Qty'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.mainColor),
            onPressed: () => Get.back(result: true),
            child: const Text('Save')),
      ],
    ));
    if (ok == true) {
      c.updateLine(i,
          price: double.tryParse(price.text), qty: double.tryParse(qty.text));
    }
    price.dispose();
    qty.dispose();
  }

  // ─── footer ────────────────────────────────────────────────────────────

  Widget _footer(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      c.lines.length == 1 ? '1 item' : '${c.lines.length} items',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(_money.format(c.grandTotal),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              )),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: c.checkingOut.value ? null : c.checkout,
                  icon: c.checkingOut.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.point_of_sale_rounded),
                  label: const Text('Sell',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                )),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      );
}
