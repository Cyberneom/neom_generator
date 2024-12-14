import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';


class Neom360ViewerController extends GetxController  {

  var logger = AppUtilities.logger;
  final neomUserController = Get.find<UserController>();

  // late Video360Controller controller;
  // late Video360Controller controller2;

  RxString durationText = "".obs;
  RxString totalText = "".obs;
  RxBool isPlaying = false.obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() async {
    super.onInit();
  }

  // onVideo360ViewCreated(Video360Controller controller) {
  //   this.controller = controller;
  //   this.controller2 = controller;
  // }

  @override
  FutureOr onClose() {
    super.onClose();
  }


  Future<void> launchChromeVRView(BuildContext context, {String url = 'https://sbis04.github.io/demo360'}) async {
    try {
      await launchUrl(
        // NOTE: Replace this URL with your GitHub Pages URL.
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          // toolbarColor: Theme.of(context).primaryColor,
          urlBarHidingEnabled: true,
          showTitle: false,
          animations: CustomTabsSystemAnimations.slideIn(),
          // extraCustomTabs: const <String>[
          //   // ref.
          //   'https://play.google.com/store/apps/details?id=org.mozilla.firefox',
          //   'org.mozilla.firefox',
          //   // ref.
          //   'https://play.google.com/store/apps/details?id=com.microsoft.emmx',
          //   'com.microsoft.emmx',
          // ],
        ),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      AppUtilities.logger.e(e.toString());
    }
  }

}
