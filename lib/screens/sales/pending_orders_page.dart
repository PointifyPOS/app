// lib/screens/sales/pending_orders_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/main.dart';

import '../../controllers/salescontroller.dart';
import '../../controllers/shopcontroller.dart';
import '../../models/salemodel.dart';
import '../../models/saleitem.dart';
import '../../utils/colors.dart';
import '../../widgets/major_title.dart';
import '../../widgets/no_items_found.dart';
import 'sale_preview.dart';

/// Restaurant-mode cashier queue: lists sales that a waiter sent to the
/// kitchen (status = "hold") and are waiting for the cashier to take payment.
/// Reuses the existing hold-sale → cash-sale mechanism.
class PendingOrdersPage extends StatefulWidget {
  const PendingOrdersPage({super.key});

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  final SalesController salesController = Get.find<SalesController>();
  final ShopController shopController = Get.find<ShopController>();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    await salesController.getSalesByDate(
      shop: userController.currentUser.value?.primaryShop?.id ?? '',
      status: 'hold',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.3,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: majorTitle(
            title: "Pending Orders", color: Colors.black, size: 16.0),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: Obx(
        () => salesController.loadingSales.isTrue
            ? const Center(child: CircularProgressIndicator())
            : salesController.onholdSales.isEmpty
                ? Center(child: noItemsFound(context, false))
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      itemCount: salesController.onholdSales.length,
                      itemBuilder: (context, index) {
                        final SaleModel sale =
                            salesController.onholdSales.elementAt(index);
                        return _pendingOrderCard(context, sale);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _pendingOrderCard(BuildContext context, SaleModel sale) {
    final items = sale.items ?? <SaleItem>[];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: order number + waiter + time
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Order #${sale.receiptNo ?? ''}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  (sale.createdAt ?? '').length >= 16
                      ? sale.createdAt!.substring(11, 16)
                      : '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (sale.attendant?.username != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  "Waiter: ${sale.attendant!.username}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
            const Divider(height: 16),
            // Items with accompaniment notes
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${item.quantity?.toStringAsFixed(0) ?? '1'} x "
                              "${item.product?.name ?? 'Item'}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            (item.totalLinePrice ?? 0).toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if ((item.salesnote ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            item.salesnote!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.purple[700]),
                          ),
                        ),
                    ],
                  ),
                )),
            const Divider(height: 16),
            // Total + collect payment
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Total: ${userController.currentUser.value?.primaryShop?.currency ?? ''} "
                    "${(sale.totalWithDiscount ?? sale.totalAmount ?? 0).toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _collectPayment(sale),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text("Collect Payment"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _collectPayment(SaleModel sale) {
    salesController.receipt.value = sale;
    salesController.amountPaid.clear();
    salesController.selectedCustomerController.clear();
    salesController.receipt.refresh();

    Get.to(() => SalePreview(page: "admin"))?.then((_) => _loadOrders());
  }
}
