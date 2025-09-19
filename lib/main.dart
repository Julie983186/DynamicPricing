import 'package:flutter/material.dart';
import 'pages/camera_page.dart';
import 'pages/preview_page.dart';
import 'pages/result_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Pricing',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/camera',
      routes: {
        '/camera': (context) =>  CameraPage(),
        '/preview': (context) => const PreviewPage(),
        '/result': (context) => const ResultPage(),
      },
      home: CameraPage(),
    );
  }
}
