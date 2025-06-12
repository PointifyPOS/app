import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/utils/colors.dart';
import 'package:pointify/widgets/textbutton.dart';

import '../../controllers/authcontroller.dart';
import '../../main.dart';
import '../profile/profile_update.dart';

class EmailVerificationPage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  EmailVerificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your email address is not verified.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            textBtn(
                onPressed: () {
                  userController.sendVerificationEmail();
                },
                text: 'Resend Verification Email',
                color: Colors.white,
                bgColor: AppColors.mainColor),
            const SizedBox(height: 20),
            textBtn(
                onPressed: () {
                  Get.to(() => ProfileUpdate(editemail: true));
                },
                text: 'Edit Email',
                color: Colors.white,
                bgColor: AppColors.mainColor),
            const SizedBox(height: 20),
            const Text("Or"),
            const SizedBox(height: 20),
            textBtn(
                onPressed: () {
                  authController.initUser();
                },
                text: 'Click here if you already verified',
                color: Colors.white,
                bgColor: AppColors.mainColor),
            const SizedBox(height: 20),
            textBtn(
                onPressed: () {
                  authController.logOut();
                },
                text: 'Logout',
                color: Colors.white,
                bgColor: Colors.red),
          ],
        ),
      ),
    );
  }
}
