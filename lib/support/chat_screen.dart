import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/chat_controller.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'bubble.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({Key? key}) : super(key: key) {
    chatController.loadMessages();
  }

  final ChatController chatController = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          title: const Text(
            "Live Chat",
            style: TextStyle(color: AppColors.mainColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: settingsData["contact"],
                );
                await launchUrl(launchUri);
              },
              icon: const Icon(
                Icons.call,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            InkWell(
              onTap: () async {
                String message =
                    'Hey, i would like to know more about your product';
                await launchUrl( Uri.parse(
                    "https://wa.me/${settingsData["contact"]}?text=$message"));
              },
              child: const Image(
                image: AssetImage("assets/whatsapp_icon.png"),
                width: 30,
              ),
            ),
            const SizedBox(
              width: 10,
            )
          ],
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.mainColor,
            ),
          )),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                chatController.focusNode.unfocus();
                FocusScope.of(context).unfocus();
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: Obx(
                  () => ListView.separated(
                    shrinkWrap: true,
                    reverse: true,
                    padding: const EdgeInsets.only(top: 12, bottom: 20) +
                        const EdgeInsets.symmetric(horizontal: 12),
                    separatorBuilder: (_, __) => const SizedBox(
                      height: 12,
                    ),
                    controller: chatController.scrollController,
                    itemCount: chatController.chatList.length,
                    itemBuilder: (context, index) {
                      return Bubble(chat: chatController.chatList[index]);
                    },
                  ),
                ),
              ),
            ),
          ),
          _BottomInputField(),
        ],
      ),
    );
  }
}

/// Bottom Fixed Filed
class _BottomInputField extends StatelessWidget {
  _BottomInputField({Key? key}) : super(key: key);
  final ChatController chatController = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E5EA),
            ),
          ),
        ),
        child: Stack(
          children: [
            TextField(
              focusNode: chatController.focusNode,
              onChanged: chatController.onFieldChanged,
              controller: chatController.textEditingController,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(
                  right: 42,
                  left: 16,
                  top: 18,
                ),
                hintText: 'send us a message',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            // custom suffix btn
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: chatController.onFieldSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
