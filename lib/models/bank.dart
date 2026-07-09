class BankModel {
  String? id;
  String? name;
  int? amount;

  BankModel({this.id, this.name, this.amount});

  BankModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['_id'];
    amount = json['totalAmount'];
  }
}
