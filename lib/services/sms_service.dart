import 'package:reggypos/main.dart';
import 'package:reggypos/services/client.dart';
import 'package:reggypos/services/end_points.dart';

class SmsService {
  static Future topUpCredits(
      {required String phone, required double amount}) async {
    String url = "${EndPoints.topUp}?phone=$phone&shop=$amount";
    var response = await DbBase().databaseRequest(url, DbBase().postRequestType,
        body: {
          "phone": phone,
          "amount": amount,
          "userid": userController.currentUser.value!.id
        });
    return response;
  }
}
