import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/get_started.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Humidity & Temperature',
      home: GetStarted(),
      debugShowCheckedModeBanner: false,
    );
  }
}
