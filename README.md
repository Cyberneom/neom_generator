# neom_generator
Neom Generator for Open Neom.
neom_generator is a core module within the Open Neom ecosystem, 
dedicated to the generation and manipulation of frequencies and audio patterns.
It provides the foundational tools for creating personalized sound experiences,
enabling users to interact with the "Neom Chamber" (or "Neom Chamber") for guided meditation,
conscious well-being, and biofeedback applications.

This module is designed for mobile app integration with a future vision for wearables and IoT devices,
aligning with the broader Tecnozenism philosophy of integrating technology and human consciousness.

🌟 Features & Responsibilities
neom_generator is responsible for:
•	Frequency Generation: Core logic for generating specific audio frequencies based on user input
    or predefined parameters.
•	Parameter Control: Allowing users to adjust various audio parameters such as volume, and spatial
    positioning (X, Y, Z axes) within a virtual sound environment.
•	Neom Chamber (Chamber) Management: Providing functionality to create, manage, and interact with
    "Chambers" – personalized collections of frequency presets. This includes:
    -	Creating new Chambers (Collection of frequencies).
    -	Adding, removing, and updating frequency presets within a Chamber.
    -	Setting privacy options for Chambers (public/private).
•	Voice Frequency Detection: Integrating microphone input and pitch detection algorithms to analyze
    and display the user's voice frequency, enabling biofeedback and self-exploration.
•	Preset Management: Saving, loading, updating, and removing user-defined frequency presets for
    quick access and personalized experiences.
•	Audio Playback Control: Managing the playback of generated frequencies, including play/stop functionality.
•	Integration with Core Services: Consuming essential services from neom_core and neom_commons for user management,
    logging, and common utilities.

📦 Installation
Add neom_generator as a Git dependency in your pubspec.yaml file:
dependencies:
    neom_generator:
        git:
            url: https://github.com/Open-Neom/neom_generator.git

Then, run flutter pub get in your project's root directory.

🚀 Usage
neom_generator is typically integrated into the main application (neom_app) as a primary feature.
It provides the UI and logic for the frequency generation and Neom Chamber experience.

Example of launching the Neom Generator Page (e.g., from neom_app's routing):
// In your main application's AppRoutes or a navigation method
import 'package:get/get.dart';
import 'package:neom_generator/generator/ui/frequency_generator_page.dart'; // Adjust path as needed
import 'package:neom_generator/generator/bindings/generator_binding.dart'; // Adjust path as needed
import 'package:neom_core/core/utils/constants/app_route_constants.dart'; // For AppRouteConstants.generator

// In your GetPages list:
GetPage(
    name: AppRouteConstants.generator,
    page: () => const NeomGeneratorPage(),
    transition: Transition.zoom,
),

// To navigate to it:
// Get.toNamed(AppRouteConstants.generator);

Example of using a generator controller method:
// In a UI widget within the neom_generator module
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_generator/generator/ui/neom_generator_controller.dart'; // Adjust path

class MyGeneratorControls extends StatelessWidget {
    const MyGeneratorControls({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return GetBuilder<NeomGeneratorController>(
            builder: (_) => Column(
                children: [
                    Text("Frequency: ${_.soundController.value.freq.round()} Hz"),
                    Slider(
                        value: _.soundController.value.volume,
                        min: 0, max: 1,
                        onChanged: (val) => _.setVolume(val),
                    ),
                    IconButton(
                        icon: Icon(_.isPlaying.value ? Icons.pause : Icons.play_arrow),
                        onPressed: () => _.playStopPreview(),
                    ),
                ],
            ),
        );
    }
}

🛠️ Dependencies
neom_generator relies on the following key packages to provide its functionalities:
•	flutter: The Flutter SDK.
•	neom_core: For core models, use cases, and utilities.
•	neom_commons: For reusable UI components, common utilities, and translation constants.
•	get: For state management and dependency injection.
•	Audio Processing: flutter_sound (for audio recording/playback), pitch_detector_dart (for pitch detection),
    surround_frequency_generator (for frequency generation logic).
•	UI Components: sleek_circular_slider (for custom sliders), rflutter_alert (for custom alerts).
•	System Utilities: enum_to_string (for enum conversions), path_provider (for file system access), 
    permission_handler (for microphone permissions).
•	Web Integration: webview_flutter (for potential web-based audio visualization or VR integrations).

🤝 Contributing
We welcome contributions to neom_generator! Please refer to the main Open Neom repository for detailed contribution
guidelines and code of conduct.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
