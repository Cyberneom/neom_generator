import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/core_widgets.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:surround_frequency_generator/surround_frequency_generator.dart';

import '../utils/constants/generator_translation_constants.dart';
import '../utils/constants/neom_generator_constants.dart';
import '../utils/constants/neom_slider_constants.dart';
import 'neom_generator_controller.dart';

class NeomGeneratorPage extends StatelessWidget {
  
  final bool showAppBar;
  
  const NeomGeneratorPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NeomGeneratorController>(
      id: AppPageIdConstants.generator,
      init: NeomGeneratorController(),
      builder: (generatorController) => WillPopScope(
        onWillPop: () async {
          try {
            if(generatorController.isPlaying.value) {
              await generatorController.playStopPreview(stopPreview: true);
            }
            generatorController.soundController.removeListener(() { });
            generatorController.soundController.dispose();
            generatorController.soundController = SoundController();
            if(Platform.isAndroid) {
              await generatorController.webViewAndroidController.clearCache(); // Clear the WebView cache (optional)
              await generatorController.webViewAndroidController.goBack();    // Dispose of the WebView
            } else {
              await generatorController.webViewIosController.clearCache();
              await generatorController.webViewIosController.goBack();
            }
            generatorController.isPlaying.value = false;
          } catch (e) {
            AppConfig.logger.e(e.toString());
          }
          return true;
        },
    child: Scaffold(
      appBar: showAppBar ? AppBarChild(title: GeneratorTranslationConstants.neomChamber.tr) : null,
        body: Container(
        height: AppTheme.fullHeight(context),
        width: AppTheme.fullWidth(context),
        decoration: AppTheme.appBoxDecoration,
        child: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SoundWidget(soundController: generatorController.soundController,
            webViewAndroidController: generatorController.webViewAndroidController,
            webViewIosController: generatorController.webViewIosController,
            backgroundColor: AppColor.getMain(),
          ),
          AppTheme.heightSpace40,
          ValueListenableBuilder<AudioParam>(
            valueListenable: generatorController.soundController,
            builder: (context, AudioParam freqValue, __) {
              AudioParam freqValue = generatorController.getAudioParam();
              return Column(
                children: <Widget>[
                  SleekCircularSlider(
                    appearance: NeomSliderConstants.appearance01,
                    min: NeomGeneratorConstants.frequencyMin,
                    max: NeomGeneratorConstants.frequencyMax,
                    initialValue: generatorController.chamberPreset.neomFrequency!.frequency,
                    onChange: (double val) async {
                      await generatorController.setFrequency(val);
                    },
                    innerWidget: (double value) {
                      return Align(
                        alignment: Alignment.center,
                        child: SleekCircularSlider(
                          appearance: NeomSliderConstants.appearance02,
                          min: NeomGeneratorConstants.positionMin,
                          max: NeomGeneratorConstants.positionMax,
                          initialValue: freqValue.x,
                          onChange: (double val) {
                            generatorController.setParameterPosition(x: val, y: freqValue.y, z: freqValue.z);
                          },
                          innerWidget: (double v) {
                            return Align(
                              alignment: Alignment.center,
                              child: SleekCircularSlider(
                                appearance: NeomSliderConstants.appearance03,
                                min: NeomGeneratorConstants.positionMin,
                                max: NeomGeneratorConstants.positionMax,
                                initialValue: freqValue.y,
                                onChange: (double val) {
                                  generatorController.setParameterPosition(x: freqValue.x, y: val, z: freqValue.z);
                                },
                                innerWidget: (double v) {
                                  return Align(
                                    alignment: Alignment.center,
                                    child: SleekCircularSlider(
                                      appearance: NeomSliderConstants.appearance04,
                                      min: NeomGeneratorConstants.positionMin,
                                      max: NeomGeneratorConstants.positionMax,
                                      initialValue: freqValue.z,
                                      onChange: (double val) {
                                        generatorController.setParameterPosition(x: freqValue.x, y: freqValue.y, z: val);
                                      },
                                      innerWidget: (double val) {
                                        return Padding(
                                          padding: const EdgeInsets.all(25),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              color: generatorController.isPlaying.value ? AppColor.deepDarkViolet : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: InkWell(
                                              child: IconButton(
                                                  onPressed: ()  async {
                                                    await generatorController.playStopPreview();
                                                  },
                                                  icon: const Icon(FontAwesomeIcons.om, size: 60)
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Slider(
                    value: freqValue.volume,
                    min: NeomGeneratorConstants.volumeMin,
                    max: NeomGeneratorConstants.volumeMax,
                    onChanged: (val) {
                      generatorController.setVolume(val);
                    },
                  ),
                  AppTheme.heightSpace10,

                  Text("${generatorController.soundController.value.freq.round()} Hz",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  AppTheme.heightSpace20,
                  Text(
                    AppTranslationConstants.parameters.tr.capitalizeFirst,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  AppTheme.heightSpace10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("${AppTranslationConstants.volume.tr}: ${(generatorController.soundController.value.volume*100).round()}"),
                      Text(
                          "${GeneratorTranslationConstants.waveLength.tr}: ${generatorController.soundController.value.freq > 0 ? ((343 / generatorController.soundController.value.freq) * 100).toStringAsFixed(2) : 'N/A'} cm"
                      ),
                    ],
                  ),
                  AppTheme.heightSpace10,
                  Text(
                    GeneratorTranslationConstants.surroundSound.tr.capitalizeFirst,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  AppTheme.heightSpace10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("${GeneratorTranslationConstants.xAxis.tr}: ${generatorController.soundController.value.x.toPrecision(2)}"),
                      Text("${GeneratorTranslationConstants.yAxis.tr}: ${generatorController.soundController.value.y.toPrecision(2)}"),
                      Text("${GeneratorTranslationConstants.zAxis.tr}: ${generatorController.soundController.value.z.toPrecision(2)}"),
                    ],
                  ),
                  AppTheme.heightSpace20,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: generatorController.existsInChamber.value && !generatorController.isUpdate.value ? const SizedBox.shrink() : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        GestureDetector(
                          child: buildIconActionChip(icon: const Icon(Icons.remove), controllerFunction: () async {await generatorController.decreaseFrequency();}),
                          onLongPress: () {
                            generatorController.longPressed.value = true;
                            generatorController.timerDuration.value = NeomGeneratorConstants.recursiveCallTimerDuration;
                            generatorController.decreaseOnLongPress();
                          },
                          onLongPressUp: () => generatorController.longPressed.value = false,
                        ),
                        if(generatorController.userServiceImpl != null) TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            backgroundColor: AppColor.bondiBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),),
                          child: Text(generatorController.isUpdate.value ? GeneratorTranslationConstants.savePreset.tr : generatorController.existsInChamber.value ? GeneratorTranslationConstants.removePreset.tr : GeneratorTranslationConstants.savePreset.tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold
                              )
                          ),
                          onPressed: () async {
                            if(generatorController.existsInChamber.value && !generatorController.isUpdate.value) {
                              await generatorController.removePreset(context);
                            } else {
                              await Alert(
                                context: context,
                                style: AlertStyle(
                                    backgroundColor: AppColor.main50,
                                    titleStyle: const TextStyle(color: Colors.white)
                                ),
                                title: GeneratorTranslationConstants.chamberPrefs.tr,
                                content: Column(
                                  children: <Widget>[
                                    Obx(()=>
                                        DropdownButton<String>(
                                          items: AppItemState.values.map((AppItemState itemState) {
                                            return DropdownMenuItem<String>(
                                                value: itemState.name,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Text(itemState.name.tr),
                                                    itemState.value == 0 ? const SizedBox.shrink() : const Text(" - "),
                                                    itemState.value == 0 ? const SizedBox.shrink() :
                                                    RatingBar(
                                                      initialRating: itemState.value.toDouble(),
                                                      minRating: 1,
                                                      ignoreGestures: true,
                                                      direction: Axis.horizontal,
                                                      allowHalfRating: false,
                                                      itemCount: 5,
                                                      ratingWidget: RatingWidget(
                                                        full: AppUtilities.ratingImage(AppAssets.heart),
                                                        half: AppUtilities.ratingImage(AppAssets.heartHalf),
                                                        empty: AppUtilities.ratingImage(AppAssets.heartBorder),
                                                      ),
                                                      itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                                                      itemSize: 10,
                                                      onRatingUpdate: (rating) {
                                                        AppConfig.logger.i("New Rating set to $rating");
                                                      },
                                                    ),
                                                  ],
                                                )
                                            );
                                          }).toList(),
                                          onChanged: (String? newItemState) {
                                            generatorController.setFrequencyState(EnumToString.fromString(AppItemState.values, newItemState!) ?? AppItemState.noState);
                                          },
                                          value: CoreUtilities.getItemState(generatorController.frequencyState.value).name,
                                          alignment: Alignment.center,
                                          icon: const Icon(Icons.arrow_downward),
                                          iconSize: 15,
                                          elevation: 15,
                                          style: const TextStyle(color: Colors.white),
                                          dropdownColor: AppColor.main75,
                                          underline: Container(
                                            height: 1,
                                            color: Colors.grey,
                                          ),
                                        )
                                    ),
                                  ],
                                ),
                                buttons: [
                                  DialogButton(
                                    color: AppColor.bondiBlue75,
                                    child: Obx(()=>generatorController.isLoading.value ? const Center(child: CircularProgressIndicator())
                                        : Text(AppTranslationConstants.add.tr,
                                    )),
                                    onPressed: () async {
                                      if(generatorController.frequencyState > 0) {
                                        await generatorController.addPreset(context, frequencyPracticeState: generatorController.frequencyState.value);
                                        Navigator.pop(context);
                                      } else {
                                        Get.snackbar(
                                            CommonTranslationConstants.appItemPrefs.tr,
                                            MessageTranslationConstants.selectItemStateMsg.tr,
                                            snackPosition: SnackPosition.bottom
                                        );
                                      }
                                    },
                                  )],
                              ).show();
                            }
                            Navigator.pop(context);
                          },
                        ),
                        GestureDetector(
                          child: buildIconActionChip(icon: const Icon(Icons.add), controllerFunction: () async { await generatorController.increaseFrequency();}),
                          onLongPress: () {
                            generatorController.longPressed.value = true;
                            generatorController.timerDuration.value = NeomGeneratorConstants.recursiveCallTimerDuration;
                            generatorController.increaseOnLongPress();
                          },
                          onLongPressUp: () => generatorController.longPressed.value = false,
                        ),
                      ],
                    ),
                  ),
                  AppTheme.heightSpace10,
                  InkWell(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: generatorController.isRecording ? Colors.grey.shade800 : Colors.grey.shade900,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],),
                      child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (generatorController.isRecording)
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(),
                          ),
                        IconButton(
                          onPressed: () => generatorController.isRecording ? generatorController.stopRecording() : generatorController.startRecording(),
                          icon: Icon(FontAwesomeIcons.microphone, size: 40, color: generatorController.isRecording ? Colors.red : null),
                        ),
                      ],
                    ),),
                    onTap: () => generatorController.isRecording ? generatorController.stopRecording() : generatorController.startRecording(),
                    onLongPress: () => generatorController.isRecording ? generatorController.stopRecording() : generatorController.startRecording(),
                  ),
                  AppTheme.heightSpace10,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: generatorController.isRecording || generatorController.frequencyDescription.isEmpty ? Text(
                      generatorController.isRecording ? "${AppTranslationConstants.frequency.tr}: ${generatorController.detectedFrequency.toInt()} Hz"
                  : generatorController.detectedFrequency == 0 ? GeneratorTranslationConstants.findsYourVoiceFrequency.tr : '',
                      style: TextStyle(fontSize: generatorController.isRecording ? 18 : 15,),
                      textAlign: TextAlign.justify,
                    ) : ReadMoreContainer(
                      text: generatorController.frequencyDescription.value,
                      fontSize: 12,
                      trimLines: 5,
                    )
                  ),
                  AppTheme.heightSpace20,
                ],
              );
            },
          ),
        ],
      ),
        ),
        ),
      //TODO EXPERIMENTAL FEATURES TO MOVE NEOM CHAMBER 2D TO A 3D VERSION TO USE IT WITH SMARTPHONE VR
      // floatingActionButton: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //   FloatingActionButton(
      //     heroTag: "",
      //     backgroundColor: Colors.white12,
      //     mini: true,
      //     child: Icon(FontAwesomeIcons.vrCardboard, size: 12,color: Colors.white,),
      //     onPressed: ()=>{
      //       // Get.to(() => PanoramaView())
      //     },
      //   ),
      //   FloatingActionButton(
      //     heroTag: " ",
      //     backgroundColor: Colors.white12,
      //     mini: true,
      //     child: Icon(FontAwesomeIcons.globe, size: 12,color: Colors.white,),
      //     onPressed: ()=> {
      //       // Get.to(() => VideoSection())
      //     },
      //   ),
      //     FloatingActionButton(
      //       heroTag: " _",
      //       backgroundColor: Colors.white12,
      //       mini: true,
      //       child: Icon(FontAwesomeIcons.chrome, size: 12,color: Colors.white,),
      //       onPressed: ()=> {
      //         generatorController.neom360viewerController.launchChromeVRView(context, url: 'https://larkintuckerllc.github.io/hello-react-360/')
      //       },
      //     )
      // ],
      // )
    ),),
    );
  }
}
