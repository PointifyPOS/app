import 'package:pointify/main.dart';

import '../models/package.dart';
import 'client.dart';
import 'end_points.dart';

class PlansService {
  createPackage(Package packages) async {}

  getPlans() async {
    String url =
        "${EndPoints.packages}?id=${userController.currentUser.value?.id}";
    var response = await DbBase().databaseRequest(url, DbBase().getRequestType);
    return response;
  }
}
