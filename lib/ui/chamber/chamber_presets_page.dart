import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';

import '../widgets/chamber_widgets.dart';
import 'chamber_preset_controller.dart';

class ChamberPresetsPage extends StatelessWidget {
  const ChamberPresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChamberPresetController>(
      id: AppPageIdConstants.chamberPresets,
      init: ChamberPresetController(),
      builder: (chamberController) => Scaffold(
        backgroundColor: AppColor.getMain(),
        appBar: AppBarChild(title: chamberController.chamber.name.length > AppConstants.maxItemlistNameLength
            ? "${chamberController.chamber.name.substring(0,AppConstants.maxItemlistNameLength)}..."
            : chamberController.chamber.name),
        body: Container(
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration, 
          child: chamberController.isLoading.value ? const Center(child: CircularProgressIndicator())
              : Obx(()=> buildPresetsList(context, chamberController)),
        ),
        floatingActionButton: chamberController.isFixed || !chamberController.chamber.isModifiable ? const SizedBox.shrink()
            : FloatingActionButton(
          tooltip: CommonTranslationConstants.addItem.tr,
          onPressed: ()=> {
            Get.toNamed(AppRouteConstants.itemSearch,
                arguments: [MediaSearchType.song, chamberController.chamber])
          },
          child: const Icon(Icons.playlist_add),
        ),
      ),
    );
  }
}
