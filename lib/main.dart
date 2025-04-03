import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:trial_1/pages/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}
