class MpesaPayment {
  final String mpesaRef;
  final String payerName;
  final double amount;
  final String time;
  final bool allocated;

  MpesaPayment({
    required this.mpesaRef,
    required this.payerName,
    required this.amount,
    required this.time,
    required this.allocated,
  });

  factory MpesaPayment.fromJson(Map<String, dynamic> j) => MpesaPayment(
        mpesaRef: (j['mpesaRef'] ?? j['code'] ?? j['transID'] ?? '').toString(),
        payerName: (j['payerName'] ?? j['name'] ?? '').toString(),
        amount: double.tryParse(
                (j['amount'] ?? j['paid_amount'] ?? 0).toString()) ??
            0,
        time: (j['time'] ?? j['createdAt'] ?? j['transTime'] ?? '').toString(),
        allocated: j['allocated'] == true,
      );
}
