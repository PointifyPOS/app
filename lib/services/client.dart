import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:pointify/controllers/authcontroller.dart';
import 'package:pointify/functions/functions.dart';
import 'package:pointify/services/preference_manager.dart';
import 'package:pointify/utils/isrg_root_x1.dart';

import '../widgets/snackbars.dart';

/// Debug escape hatch only: `--dart-define=ALLOW_BAD_CERTS=true` accepts any server certificate
/// (e.g. a local test server). Release builds validate certificates.
const bool _allowBadCerts =
    bool.fromEnvironment('ALLOW_BAD_CERTS', defaultValue: false);

/// API results are decoded JSON: a List for list endpoints, a Map otherwise. When a call fails
/// (offline, timeout, 4xx/5xx, HTML from a proxy) DbBase returns a Map with `error`, so a screen that
/// expects a list must not cast the result directly. `asList` returns the list, the `data` list of a
/// wrapped response, or an empty list.
List<dynamic> asList(dynamic response) {
  if (response is List) return response;
  if (response is Map && response['data'] is List) {
    return response['data'] as List;
  }
  return <dynamic>[];
}

class DbBase {
  final postRequestType = "POST";
  final getRequestType = "GET";
  final putRequestType = "PUT";
  final patchRequestType = "PATCH";
  final deleteRequestType = "DELETE";

  final Dio _dio = Dio();

  // The API enforces tokens. Because validateStatus accepts every status, a 401 arrives as normal
  // data, so detect it here and sign the user out once instead of letting screens parse an error
  // body as real data.
  static bool _handlingExpiredSession = false;

  static bool _isExpiredSession(Response r) {
    if (r.statusCode != 401) return false;
    final d = r.data;
    if (d is! Map) return false;
    final m = d["message"];
    return m == "Invalid or expired token" || m == "Access token required";
  }

  static Future<void> _onSessionExpired() async {
    if (_handlingExpiredSession) return;
    final prefs = PreferenceManager();
    if (await prefs.getString('id') == null) return; // nobody signed in
    _handlingExpiredSession = true;
    try {
      showSnackBar(
          message: "Session expired, please sign in again", color: Colors.red);
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().logOut();
      }
    } finally {
      _handlingExpiredSession = false;
    }
  }

  /// What every failed call returns instead of null / an exception. `status: false` keeps the
  /// screens that test `response["status"] == false` on their error path.
  static Map<String, dynamic> failure(String message, {int? statusCode}) => {
        "error": message,
        "message": message,
        "status": false,
        if (statusCode != null) "statusCode": statusCode,
      };

  DbBase() {
    _dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      // Validate certificates. ISRG Root X1 is bundled so that old Android versions (7.0 and
      // below), which do not trust Let's Encrypt, still validate the chain.
      final context = SecurityContext(withTrustedRoots: true);
      try {
        context.setTrustedCertificatesBytes(utf8.encode(isrgRootX1Pem));
      } catch (_) {
        // already trusted by the platform: nothing to add
      }
      final HttpClient client = HttpClient(context: context);
      if (_allowBadCerts) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
      return client;
    });

    _dio.options.validateStatus = (_) => true;
    _dio.options.headers['Connection'] = 'keep-alive';
  }

  Future databaseRequest(
    String link,
    String type, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    ResponseType responseType = ResponseType.json,
  }) async {
    try {
      final prefs = PreferenceManager();
      headers ??= {
        'Content-Type': 'application/json',
        "Authorization": "Bearer ${await prefs.getString('user_token')}",
      };

      int maxRetries = 3; // Maximum number of retry attempts
      int retryDelayInSeconds = 3; // Delay in seconds between retries

      Response response;
      debugPrintMessage(link);

      for (int retryCount = 0; retryCount < maxRetries; retryCount++) {
        try {
          switch (type) {
            case "GET":
              response = await _dio.get(link,
                  queryParameters: body,
                  options: Options(
                    headers: headers,
                    responseType: responseType,
                  ));
              break;
            case "POST":
              response = await _dio.post(link,
                  data: body,
                  options: Options(
                    headers: headers,
                    responseType: responseType,
                  ));
              break;
            case "PUT":
              response = await _dio.put(link,
                  data: body,
                  options: Options(
                    headers: headers,
                    responseType: responseType,
                  ));
              break;
            case "PATCH":
              response = await _dio.patch(link,
                  data: body,
                  options: Options(
                    headers: headers,
                    responseType: responseType,
                  ));
              break;
            case "DELETE":
              response = await _dio.delete(link,
                  data: body,
                  options: Options(
                    headers: headers,
                    responseType: responseType,
                  ));
              break;
            default:
              throw DioException(
                  requestOptions: RequestOptions(path: link),
                  error: "Invalid request type");
          }

          if (_isExpiredSession(response)) await _onSessionExpired();

          final code = response.statusCode ?? 0;
          final data = response.data;
          // A proxy/server error page (HTML or plain text) or a bytes download that failed:
          // callers expect JSON, so hand them an error Map instead of a String they would index.
          if (code >= 400 && (data is String || data is List<int>)) {
            return failure(
                code >= 500
                    ? "Server unavailable, please try again"
                    : "Request failed ($code)",
                statusCode: code);
          }
          if (data is String &&
              responseType == ResponseType.json &&
              data.trimLeft().startsWith('<')) {
            return failure("Unexpected reply from server",
                statusCode: code);
          }
          return data;
        } on DioException catch (e) {
          debugPrintMessage('Dio Error: ${e.type}');
          // Retry only for timeouts; anything else (no network, TLS, cancelled) will not recover
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            await Future.delayed(Duration(seconds: retryDelayInSeconds));
          } else {
            return failure(
                e.type == DioExceptionType.connectionError
                    ? "No internet connection"
                    : "Network error, please try again");
          }
        } catch (e) {
          debugPrintMessage('Request error: $e');
          return failure("Something went wrong, please try again");
        }
      }
      return failure("The server took too long to respond, please try again");
    } catch (e) {
      debugPrintMessage(e);
      return failure("Something went wrong, please try again");
    }
  }
}
