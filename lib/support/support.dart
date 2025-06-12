import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointify/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../utils/constants.dart';
import '../widgets/major_title.dart';
import '../widgets/minor_title.dart';
import 'chat_screen.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.mainColor,
            )),
        title: const Text(
          "Support",
          style: TextStyle(
            color: AppColors.mainColor,
          ),
        ),
      ),
      body: Column(
        children: [
          InkWell(
            onTap: () {
              Get.to(() => ChatScreen());
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Icon(Icons.live_help)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                majorTitle(
                                    title: "Live Chat",
                                    color: Colors.black,
                                    size: 16.0),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.green),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                if (int.parse(userController
                                            .messagesCount.value.isEmpty
                                        ? "0"
                                        : userController.messagesCount.value) >
                                    0)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: Center(
                                      child: Text(
                                        userController.messagesCount.value,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 5),
                            minorTitle(
                                title:
                                    "Contact our stand by team to help you 24/7",
                                color: Colors.grey)
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              String message =
                  'Hey, i would like to know more about your product';
              await launchUrl(
                Uri.parse(
                  "https://wa.me/${settingsData["contact"]}?text=$message"));
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Image(
                        image: AssetImage("assets/whatsapp_icon.png"),
                        width: 30,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            majorTitle(
                                title: "Whatsapp",
                                color: Colors.black,
                                size: 16.0),
                            const SizedBox(height: 5),
                            minorTitle(
                                title:
                                    "Someone is waiting on the call for your questions/help",
                                color: Colors.grey)
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: settingsData["contact"],
              );
              await launchUrl(launchUri);
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Icon(Icons.call)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            majorTitle(
                                title: "Call us",
                                color: Colors.black,
                                size: 16.0),
                            const SizedBox(height: 5),
                            minorTitle(
                                title:
                                    "Someone is waiting on the call for your questions/help",
                                color: Colors.grey)
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final Uri params = Uri(
                  scheme: 'mailto',
                  path: settingsData["email"],
                  queryParameters: {
                    'subject': 'Pointify Support',
                    'body': 'Kindly help me on pointify'
                  });
              String url = params.toString();
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Icon(Icons.email)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            majorTitle(
                                title: "Email us",
                                color: Colors.black,
                                size: 16.0),
                            const SizedBox(height: 5),
                            minorTitle(
                                title:
                                    "Or send as an email and we will respond as soon as possible",
                                color: Colors.grey)
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
