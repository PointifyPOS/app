import 'package:flutter/material.dart';

showConfirmationDialog(BuildContext context, String message,
    {String positiveResponse = "Yes",
    String negativeResponse = "No",
    Function? function}) async {
  var result = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            child: Text(
              positiveResponse,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              if (function != null) {
                function();
              } else {
                Navigator.pop(context, true);
              }
            },
          ),
          TextButton(
            child: Text(
              negativeResponse,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
  result ??= false;
  return result;
}
