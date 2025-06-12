import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:pointify/services/preference_manager.dart';
import 'package:pointify/utils/constants.dart';

class DynamicLinkService {
  Future<String> generateShareLink(String groupId,
      {String? type,
      String? title = "",
      String? msg = "",
      String? imageurl = ""}) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: deepLinkUriPrefix,
      link: Uri.parse(_createLink(groupId, type!)),
      androidParameters: AndroidParameters(
        packageName: packagename,
      ),
      // NOT ALL ARE REQUIRED ===== HERE AS AN EXAMPLE =====
      iosParameters: IOSParameters(
        bundleId: packagename,
        minimumVersion: '1.0',
        appStoreId: '6456891671',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
          title: title ?? "Pointify",
          description: msg,
          imageUrl: Uri.parse(imageurl!)),
    );
    final ShortDynamicLink dynamicUrl =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return dynamicUrl.shortUrl.toString();
  }

  Future handleDynamicLinks() async {
    try {
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      if (data != null) {
        _handleDeepLink(data);
      }

      FirebaseDynamicLinks.instance.onLink.listen(
          (PendingDynamicLinkData dynamicLink) async {
        _handleDeepLink(dynamicLink);
      }, onError: (error) async {
        if (kDebugMode) {
          print("Error FirebaseDynamicLinks.instance.onLink $error");
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error FirebaseDynamicLinks.instance.onLink $e");
      }
    }
  }

  Future<void> _handleDeepLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data.link;
    if (deepLink.queryParameters['type'] == "app") {
      var groupId = deepLink.queryParameters['groupid'];
      final prefs = PreferenceManager();
      prefs.saveString('refer', groupId!);
    }
  }

  _createLink(String groupId, String type) {
    String link;

    link = '$deepLinkUriPrefix/?groupid=$groupId&type=$type';

    return link;
  }
}
