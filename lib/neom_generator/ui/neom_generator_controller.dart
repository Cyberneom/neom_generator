import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/data/firestore/chamber_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/neom/chamber.dart';
import 'package:neom_core/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_core/core/domain/model/neom/neom_frequency.dart';
import 'package:neom_core/core/domain/model/neom/neom_parameter.dart';
import 'package:neom_core/core/utils/enums/app_item_state.dart';
import 'package:neom_frequencies/frequencies/ui/frequency_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';
import 'package:surround_frequency_generator/surround_frequency_generator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../domain/use_cases/neom_generator_service.dart';
import '../utils.constants/neom_generator_constants.dart';

class NeomGeneratorController extends GetxController implements NeomGeneratorService {

  final userController = Get.find<UserController>();

  ///EXPERIMENTAL
  // final neom360viewerController = Get.put(Neom360ViewerController());
  final frequencyController = Get.put(FrequencyController());

  late SoundController soundController;
  WebViewController webViewAndroidController = WebViewController();
  PlatformWebViewController webViewIosController = PlatformWebViewController(const PlatformWebViewControllerCreationParams());

  AppProfile profile = AppProfile();

  ChamberPreset chamberPreset = ChamberPreset();

  RxBool isPlaying = false.obs;
  RxBool isLoading = true.obs;
  final RxInt frequencyState = 0.obs;
  final RxMap<String, Chamber> chambers = <String, Chamber>{}.obs;
  final Rx<Chamber> chamber = Chamber().obs;
  final RxBool existsInChamber = false.obs;
  final RxBool isUpdate = false.obs;
  final RxBool isButtonDisabled = false.obs;

  RxString frequencyDescription = "".obs;

  bool noChambers = false;

  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  double detectedFrequency = 0;
  StreamController<Uint8List>? _audioStreamController;
  final List<int> _accumulatedData = [];
  List<double> detectedPitches = [];

  @override
  void onInit() async {
    super.onInit();
    List<dynamic> arguments  = Get.arguments ?? [];

    try {
      if(arguments.isNotEmpty) {
        if(arguments.elementAt(0) is ChamberPreset) {
          chamberPreset =  arguments.elementAt(0);
        } else if(arguments.elementAt(0) is NeomFrequency) {
          chamberPreset.neomFrequency = arguments.elementAt(0);
        }
      }

      profile = userController.profile;
      chambers.value = profile.chambers ?? {};
      soundController = SoundController();

      chamberPreset.neomFrequency ??= NeomFrequency();
      chamberPreset.neomParameter ??= NeomParameter();

      settingChamber();

      _recorder = FlutterSoundRecorder();
      initializeRecorder();
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {

      await soundController.init();
      if(chambers.isEmpty) {
        noChambers = true;
      } else {
        existsInChamber.value = frequencyAlreadyInItemlist();
        if(chamber.value.id.isEmpty) {
          chamber.value = chambers.values.first;
        }
      }

      frequencyDescription.value = chamberPreset.description.isNotEmpty
          ? chamberPreset.description : chamberPreset.neomFrequency!.description.isNotEmpty ? chamberPreset.neomFrequency!.description : "";

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.generator]);
  }

  @override
  void dispose() {
    // Dispose the WebViewController

    super.dispose();
    // Dispose of GetX resources
    Get.delete<NeomGeneratorController>();
  }

  @override
  Future<void> settingChamber() async {

    try {
      AudioParam customAudioParam = AudioParam(
          volume: chamberPreset.neomParameter!.volume,
          x: chamberPreset.neomParameter!.x,
          y: chamberPreset.neomParameter!.y,
          z: chamberPreset.neomParameter!.z,
          freq:chamberPreset.neomFrequency!.frequency);
        soundController.value = customAudioParam;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      Get.back();
    }

    isLoading.value = false;
    update([AppPageIdConstants.generator]);
  }


  @override
  Future<void> setFrequency(double frequency) async {

    double threshold = 0.0000001;
    double freqDifference = (chamberPreset.neomFrequency!.frequency - frequency).abs();
    if(chamberPreset.neomFrequency!.frequency == frequency || (freqDifference < threshold)) return;

    chamberPreset.neomFrequency!.frequency = frequency.ceilToDouble();
    frequencyDescription.value = "";
    for (var element in frequencyController.frequencies.values) {
      if(element.frequency.ceilToDouble() == frequency.ceilToDouble()) {
        frequencyDescription.value = element.description;
      }
    }

    if(existsInChamber.value) isUpdate.value = true;

    await soundController.setFrequency(frequency);
    update([AppPageIdConstants.generator]);
  }


  @override
  void setVolume(double volume) async {
    chamberPreset.neomParameter!.volume = volume;
    soundController.setVolume(volume);
    if(existsInChamber.value) isUpdate.value = true;
    update([AppPageIdConstants.generator]);
  }

  @override
  Future<void> stopPlay() async {

    if(isPlaying.value && await soundController.isPlaying()) {
      await soundController.stop();
      isPlaying.value = false;
    } else {
      await soundController.play().whenComplete(() => isPlaying.value = true);
    }

    AppConfig.logger.i('isPlaying: $isPlaying');
    update([AppPageIdConstants.generator]);
  }

  void changeControllerStatus(bool status){
    isPlaying.value = status;
    update([AppPageIdConstants.generator]);
  }

  AudioParam getAudioParam()  {
    soundController.init();
    return AudioParam(
          volume: chamberPreset.neomParameter!.volume,
          x: chamberPreset.neomParameter!.x,
          y: chamberPreset.neomParameter!.y,
          z: chamberPreset.neomParameter!.z,
          freq:chamberPreset.neomFrequency!.frequency);

  }

  Future<void> playStopPreview({bool stopPreview = false}) async {

    AppConfig.logger.d("Previewing Chamber Preset ${chamberPreset.name}");

    try {
      if(await soundController.isPlaying() || stopPreview) {
        AppConfig.logger.d("Stopping Chamber Preset ${chamberPreset.name}");
        await soundController.stop();
        // await soundController.init();
        changeControllerStatus(false);
      } else {
        AppConfig.logger.d("Playing Chamber Preset ${chamberPreset.name}");
        settingChamber();
        await soundController.init();
        await soundController.play();
        changeControllerStatus(true);
      }
      // await audioPlayer.play(BytesSource(createSample(240)));
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.generator]);
  }


  void setFrequencyState(AppItemState newState){
    AppConfig.logger.d("Setting new appItem $newState");
    frequencyState.value = newState.value;
    chamberPreset.state = newState.value;
    update([AppPageIdConstants.generator]);
  }

  void setSelectedItemlist(String selectedItemlist){
    AppConfig.logger.d("Setting selectedItemlist $selectedItemlist");
    chamber.value.id  = selectedItemlist;
    update([AppPageIdConstants.generator]);
  }

  bool frequencyAlreadyInItemlist() {
    AppConfig.logger.d("Verifying if Item already exists in chambers");

    bool alreadyInItemlist = false;
    for (var nChamber in chambers.values) {
      for (var presets in nChamber.chamberPresets ?? []) {
        if (chamberPreset.id == presets.id) {
          alreadyInItemlist = true;
          chamber.value = nChamber;
        }
      }
    }

    AppConfig.logger.d("Frequency already exists in chambers: $alreadyInItemlist");
    return alreadyInItemlist;
  }

  Future<void> addPreset(BuildContext context, {int frequencyPracticeState = 0}) async {

    if(!isButtonDisabled.value) {
      isButtonDisabled.value = true;
      isLoading.value = true;
      update([AppPageIdConstants.generator]);

      AppConfig.logger.i("ChamberPreset would be added as $frequencyState for Itemlist ${chamber.value.id}");

      if(frequencyPracticeState > 0) frequencyState.value = frequencyPracticeState;

      if(noChambers) {
        chamber.value.name = AppTranslationConstants.myFavItemlistName.tr;
        chamber.value.description = AppTranslationConstants.myFavItemlistDesc.tr;
        chamber.value.imgUrl = AppProperties.getAppLogoUrl();
        chamber.value.ownerId = profile.id;
        chamber.value.id = await ChamberFirestore().insert(chamber.value);
      } else {
        if(chamber.value.id.isEmpty) chamber.value.id = chambers.values.first.id;
      }

      if(chamber.value.id.isNotEmpty) {

        try {
          chamberPreset.id = "${chamberPreset.neomFrequency!.frequency.ceilToDouble().toString()}_${chamberPreset.neomParameter!.volume.toString()}"
              "_${chamberPreset.neomParameter!.x.toString()}_${chamberPreset.neomParameter!.y.toString()}_${chamberPreset.neomParameter!.z.toString()}";
          chamberPreset.name = "${AppTranslationConstants.frequency.tr} ${chamberPreset.neomFrequency!.frequency.ceilToDouble().toString()} Hz";
          chamberPreset.imgUrl = AppProperties.getAppLogoUrl();
          chamberPreset.ownerId = profile.id;
          chamberPreset.neomFrequency!.description = frequencyDescription.value;
          if(await ChamberFirestore().addPreset(chamber.value.id, chamberPreset)) {
            await ProfileFirestore().addChamberPreset(profileId: profile.id, chamberPresetId: chamberPreset.id);
            await userController.reloadProfileItemlists();
            await userController.loadProfileChambers();
            userController.profile.chamberPresets?.add(chamberPreset.id);
            AppConfig.logger.d("Preset added to Neom Chamber");
          } else {
            AppConfig.logger.d("Preset not added to Neom Chamber");
          }
        } catch (e) {
          AppConfig.logger.e(e.toString());
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.generator.tr,
              message: 'Algo salió mal agregando tu preset a tu cámara Neom.'
          );
        }

        AppUtilities.showSnackBar(
            title: AppTranslationConstants.generator.tr,
            message: 'El preajuste para la frecuencia de "${chamberPreset.neomFrequency!.frequency.ceilToDouble().toString()}"'
                ' Hz fue agregado a la Cámara Neom: ${chamber.value.name}.'
        );
      }
    }

    existsInChamber.value = true;
    isButtonDisabled.value = false;
    isLoading.value = false;

    update([]);
  }

  Future<void> removePreset(BuildContext context) async {


    if(!isButtonDisabled.value) {
      isButtonDisabled.value = true;
      isLoading.value = true;
      update([AppPageIdConstants.generator]);

      AppConfig.logger.i("ChamberPreset would be removed for Itemlist ${chamber.value.id}");

      if(chamber.value.id.isEmpty) chamber.value.id = chambers.values.first.id;

      if(chamber.value.id.isNotEmpty) {
        try {
          if(await ChamberFirestore().deletePreset(chamber.value.id, chamberPreset)) {
            await userController.reloadProfileItemlists();
            chambers.value = userController.profile.chambers ?? {};
            AppConfig.logger.d("Preset removed from Neom Chamber");
          } else {
            AppConfig.logger.d("Preset not removed from Neom Chamber");
          }
        } catch (e) {
          AppConfig.logger.e(e.toString());
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.neomChamber.tr,
              message: 'Algo salió mal eliminando tu preset de tu cámara Neom.'
          );
        }

        AppUtilities.showSnackBar(
            title: AppTranslationConstants.neomChamber.tr,
            message: 'El preajuste para la frecuencia de "${chamberPreset.neomFrequency!.frequency.ceilToDouble().toString()}"'
                ' Hz fue removido de la Cámara Neom: ${chamber.value.name} satisfactoriamente.'
        );
      }
    }

    existsInChamber.value = false;
    isButtonDisabled.value = false;
    isLoading.value = false;
    update([]);
  }

  @override
  void setParameterPosition({required double x, required double y, required double z}) {

    try {
      chamberPreset.neomParameter!.x = x;
      chamberPreset.neomParameter!.y = y;
      chamberPreset.neomParameter!.z = z;

      soundController.setPosition(x,y,z);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    if(existsInChamber.value) isUpdate.value = true;
    update([]);
  }

  Future<void> increaseFrequency({double step = 1}) async {
    double newFrequency = chamberPreset.neomFrequency!.frequency + step;
    if(newFrequency <= 0) return;
    AppConfig.logger.d("Increasing Frequency from ${chamberPreset.neomFrequency!.frequency} to $newFrequency");
    chamberPreset.neomFrequency!.frequency = newFrequency;
    frequencyDescription.value = "";
    for (var element in frequencyController.frequencies.values) {
      if(element.frequency.ceilToDouble() == newFrequency) {
        frequencyDescription.value = element.description;
      }
    }

    if(existsInChamber.value) isUpdate.value = true;

    await soundController.setFrequency(newFrequency);
    update([AppPageIdConstants.generator]);
  }

  Future<void> decreaseFrequency({double step = 1}) async {
    double newFrequency = chamberPreset.neomFrequency!.frequency - step;
    if(newFrequency <= 0) return;
    await setFrequency(newFrequency);
  }

  RxBool longPressed = false.obs;
  RxInt timerDuration = NeomGeneratorConstants.recursiveCallTimerDuration.obs;

  void increaseOnLongPress() {
    if(longPressed.value) {
      if(timerDuration > NeomGeneratorConstants.recursiveCallTimerDurationMin) timerDuration--;
      increaseFrequency();
      Timer(Duration(milliseconds: timerDuration.value), increaseOnLongPress);
    }
  }

  void decreaseOnLongPress() {
    if(longPressed.value) {
      if(timerDuration > NeomGeneratorConstants.recursiveCallTimerDurationMin) timerDuration--;
      decreaseFrequency();
      Timer(Duration(milliseconds: timerDuration.value), decreaseOnLongPress);
    }
  }

  Future<void> initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
  }

  void initializeStreamController(){
    _audioStreamController = StreamController<Uint8List>();
    _audioStreamController!.stream.listen((audioData) async {

      double freqPitch = await getPitchFromAudioData(audioData);
      if(freqPitch > NeomGeneratorConstants.frequencyMin && freqPitch < NeomGeneratorConstants.frequencyMax) {
        AppConfig.logger.d("Pitch: $freqPitch Hz");
        detectedFrequency = freqPitch;
        detectedPitches.add(freqPitch);
      }

      update([AppPageIdConstants.generator]);
    });
  }

  Future<void> startRecording() async {


    AppConfig.logger.d("Start Recording");
    isRecording = true;
    detectedFrequency = 0;


    try {
      playStopPreview(stopPreview: true);

      if (_audioStreamController == null) {
        initializeStreamController();
      }

      _recorder!.startRecorder(
        codec: Codec.pcm16WAV,
        sampleRate: NeomGeneratorConstants.sampleRate,
        numChannels: 1,
        toStream: _audioStreamController?.sink, //
      );

      // Stop the recorder after x seconds
      Timer(Duration(seconds: NeomGeneratorConstants.sampleDuration), () {
        stopRecording();
        if((detectedFrequency) > 0) {
          setFrequency(detectedFrequency);
        }
      });
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.generator]);
  }

  void stopRecording() async {
    await _recorder!.stopRecorder();
    isRecording = false;
    detectedFrequency = getMostFrequentPitch();
    if(detectedFrequency > 0) playStopPreview();
    update([AppPageIdConstants.generator]);
  }

  Future<double> getPitchFromAudioData(Uint8List audioData) async {
    _accumulatedData.addAll(audioData);

    const int bytesPerSample = 2;
    double pitch = 0;
    int neededBytes = NeomGeneratorConstants.neededSamples * bytesPerSample;

    while (_accumulatedData.length >= neededBytes) {
      // Extraemos los primeros neededBytes
      final chunk = _accumulatedData.sublist(0, neededBytes);
      // Los removemos del acumulado para postearior analisis del buffer
      _accumulatedData.removeRange(0, neededBytes);

      final pitchDetectorDart = PitchDetector(
        audioSampleRate: NeomGeneratorConstants.sampleRate.toDouble(),
        bufferSize: NeomGeneratorConstants.neededSamples,
      );

      try {
        final chunkAsUint8List = Uint8List.fromList(chunk);

        PitchDetectorResult pitchResult = await pitchDetectorDart.getPitchFromIntBuffer(chunkAsUint8List);
        pitch = pitchResult.pitch.roundToDouble();
      } catch (e) {
        AppConfig.logger.e("Pitch detector error: $e");
      }
    }

    return pitch;
  }

  double getMostFrequentPitch() {
    if (detectedPitches.isEmpty) return 0;

    final Map<double, int> frequencyMap = {};

    for (var pitch in detectedPitches) {
      frequencyMap[pitch] = (frequencyMap[pitch] ?? 0) + 1;
    }

    final mostFrequentEntry = frequencyMap.entries
        .reduce((a, b) => a.value >= b.value ? a : b);

    return mostFrequentEntry.key; //Most recurrent freq
  }

}
