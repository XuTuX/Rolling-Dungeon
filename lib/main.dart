import 'package:circle_war/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const CircleWarApp());
  });
}

class CircleWarApp extends StatelessWidget {
  const CircleWarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rolling Dungeon',
      navigatorKey: Get.key,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B4B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F0),
      ),
      home: const HomeScreen(),
    );
  }
}
