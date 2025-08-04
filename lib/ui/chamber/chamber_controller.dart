import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/neom/chamber.dart';
import 'package:neom_core/domain/use_cases/chamber_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/owner_type.dart';

import '../../data/firestore/chamber_firestore.dart';
import '../../utils/constants/generator_translation_constants.dart';

class ChamberController extends GetxController implements ChamberService {
  
  final userServiceImpl = Get.find<UserService>();

  Chamber currentChamber = Chamber();

  TextEditingController newChamberNameController = TextEditingController();
  TextEditingController newChamberDescController = TextEditingController();

  final RxMap<String, Chamber> chambers = <String, Chamber>{}.obs;
  final RxList<Chamber> addedChambers = <Chamber>[].obs;

  AppProfile profile = AppProfile();
  Band? band;
  String ownerId = '';
  String ownerName = '';
  OwnerType ownerType = OwnerType.profile;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  final RxBool isPublicNewChamber = true.obs;
  final RxString errorMsg = "".obs;

  RxString itemName = "".obs;
  RxInt itemNumber = 0.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("onInit Chamber Controller");

    try {
      userServiceImpl.itemlistOwnerType = OwnerType.profile;
      profile = userServiceImpl.profile;
      ownerId = profile.id;
      ownerName = profile.name;

      if(Get.arguments != null) {
        if(Get.arguments.isNotEmpty && Get.arguments[0] is Band) {
          band = Get.arguments[0];
          userServiceImpl.band = band!;
        }

        if(band != null) {
          ownerId = band!.id;
          ownerName = band!.name;
          ownerType = OwnerType.band;
          userServiceImpl.itemlistOwnerType = OwnerType.band;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.t('Chambers being loaded from ${ownerType.name}');
    if(ownerType == OwnerType.profile) {
      chambers.value = profile.chambers ?? {};
    } else if(ownerType == OwnerType.band){
      chambers.value = band?.chambers ?? {};
    }

    if(chambers.isEmpty) {
      chambers.value = await ChamberFirestore().fetchAll(ownerId: ownerId, ownerType: ownerType);
    }
    isLoading.value = false;
    update([AppPageIdConstants.chamber]);
  }


  void clear() {
    chambers.value = <String, Chamber>{};
    currentChamber = Chamber();
  }

  @override
  void clearNewChamber() {
    newChamberNameController.clear();
    newChamberDescController.clear();
  }


  @override
  Future<void> createChamber() async {
    AppConfig.logger.d("Start ${newChamberNameController.text} and ${newChamberDescController.text}");

    try {
      errorMsg.value = '';
      if((isPublicNewChamber.value && newChamberNameController.text.isNotEmpty && newChamberDescController.text.isNotEmpty)
          || (!isPublicNewChamber.value && newChamberNameController.text.isNotEmpty)) {
        Chamber newItemlist = Chamber.createBasic(newChamberNameController.text, newChamberDescController.text);

        newItemlist.ownerId = ownerId;
        newItemlist.ownerName = ownerName;
        newItemlist.ownerType = ownerType;
        String newItemlistId = "";

        if (profile.position?.latitude != 0.0) {
          newItemlist.position = profile.position!;
        }

        newItemlist.public = isPublicNewChamber.value;
        newItemlistId = await ChamberFirestore().insert(newItemlist);

        ///DEPRECATED
        // if(isPublicNewItemlist.value) {
        //   AppConfig.logger.i("Inserting Public Chamber to Public collection");
        //   newItemlistId = await ChamberFirestore().insert(newItemlist);
        // } else {
        //   AppConfig.logger.i("Inserting Private Chamber to collection for profileId ${newItemlist.ownerId}");
        //   newItemlistId = await ChamberFirestore().insert(newItemlist);
        // }

        AppConfig.logger.i("Empty Chamber created successfully for profile ${newItemlist.ownerId}");
        newItemlist.id = newItemlistId;

        if(newItemlistId.isNotEmpty){
          chambers[newItemlistId] = newItemlist;
          AppConfig.logger.t("Itemlists $chambers");
          clearNewChamber();
          AppUtilities.showSnackBar(
              title: GeneratorTranslationConstants.chamberPrefs.tr,
              message: GeneratorTranslationConstants.chamberCreated.tr
          );
        } else {
          AppConfig.logger.d("Something happens trying to insert chamber");
        }
      } else {
        AppConfig.logger.d(MessageTranslationConstants.pleaseFillItemlistInfo.tr);
        errorMsg.value = newChamberNameController.text.isEmpty ? MessageTranslationConstants.pleaseAddName
            : MessageTranslationConstants.pleaseAddDescription;

        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.addNewItemlist.tr,
          message: MessageTranslationConstants.pleaseFillItemlistInfo.tr,
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.chamber]);
  }

  @override
  Future<void> deleteChamber(Chamber chamber) async {
    AppConfig.logger.d("Removing for $chamber");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);

      if(await ChamberFirestore().delete(chamber.id)) {
        AppConfig.logger.d("Chamber ${chamber.id} removed");

        chambers.remove(chamber.id);
        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.itemlistPrefs.tr,
          message: CommonTranslationConstants.itemlistRemoved.tr
        );
      } else {
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.itemlistPrefs.tr,
            message: MessageTranslationConstants.itemlistRemovedErrorMsg.tr
        );
        AppConfig.logger.e("Something happens trying to remove itemlist");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.chamber]);
  }


  @override
  Future<void> updateChamber(String itemlistId, Chamber itemlist) async {

    AppConfig.logger.d("Updating to $itemlist");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);
      String newName = newChamberNameController.text;
      String newDesc = newChamberDescController.text;

      if((newName.isNotEmpty && newName.toLowerCase() != itemlist.name.toLowerCase())
          || (newDesc.isNotEmpty && newDesc.toLowerCase() != itemlist.description.toLowerCase())) {

        if(newChamberNameController.text.isNotEmpty) {
          itemlist.name = newChamberNameController.text;
        }

        if(newChamberDescController.text.isNotEmpty) {
          itemlist.description = newChamberDescController.text;
        }

        if(await ChamberFirestore().update(itemlist)){
          AppConfig.logger.d("Chamber $itemlistId updated");
          chambers[itemlist.id] = itemlist;
          clearNewChamber();
          AppUtilities.showSnackBar(
              title: CommonTranslationConstants.itemlistPrefs.tr,
              message: CommonTranslationConstants.itemlistUpdated.tr
          );
        } else {
          AppConfig.logger.i("Something happens trying to update itemlist");
          AppUtilities.showSnackBar(
              title: CommonTranslationConstants.itemlistPrefs.tr,
              message: MessageTranslationConstants.itemlistUpdatedErrorMsg.tr
          );
        }
      } else {
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.itemlistPrefs.tr,
            message: CommonTranslationConstants.itemlistUpdateSameInfo.tr
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(
          title: CommonTranslationConstants.itemlistPrefs.tr,
          message: MessageTranslationConstants.itemlistUpdatedErrorMsg.tr
      );
    }


    isLoading.value = false;
    update([AppPageIdConstants.chamber]);
  }

  @override
  Future<void> gotoChamberPresets(Chamber chamber) async {
    await Get.toNamed(AppRouteConstants.chamberPresets, arguments: [chamber]);
    update([AppPageIdConstants.chamber]);
  }

  @override
  Future<void> setPrivacyOption() async {
    AppConfig.logger.t('setPrivacyOption for Playlist');
    isPublicNewChamber.value = !isPublicNewChamber.value;
    AppConfig.logger.d("New Itemlist would be ${isPublicNewChamber.value ? 'Public':'Private'}");
    update([AppPageIdConstants.chamber, AppPageIdConstants.chamberPresets]);
  }

}
