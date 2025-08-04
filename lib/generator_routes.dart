import 'package:get/get.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/chamber/chamber_page.dart';
import 'ui/chamber/chamber_presets_page.dart';
import 'ui/neom_generator_page.dart';

class GeneratorRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.generator,
        page: () => NeomGeneratorPage(),
        transition: Transition.zoom,
    ),
    GetPage(
        name: AppRouteConstants.chamberPresets,
        page: () => const ChamberPresetsPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.chamber,
        page: () => const ChamberPage(),
        transition: Transition.zoom
    ),
  ];

}
