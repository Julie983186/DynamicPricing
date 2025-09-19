import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'pages/camera_page.dart';
import 'pages/preview_page.dart';
import 'pages/result_page.dart';
=======
import 'package:flutter_localizations/flutter_localizations.dart'; // 🌐 ローカライズ用

// 各ページのインポート
import 'pages/register_login_page.dart';
import 'pages/member_area_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
>>>>>>> Stashed changes

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< Updated upstream
      title: 'Dynamic Pricing',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/camera',
      routes: {
        '/camera': (context) =>  CameraPage(),
        '/preview': (context) => const PreviewPage(),
        '/result': (context) => const ResultPage(),
      },
      home: CameraPage(),
=======
      title: '註冊登入範例',
      debugShowCheckedModeBanner: false,

      // 🌐 ローカライズ設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
      ],

      // ✅ 初期画面
      initialRoute: '/loading',

      routes: {
        '/login': (context) => const RegisterLoginPage(),
        '/member': (context) => const MemberAreaPage(userName: '測試使用者'),
        '/loading': (context) => const RecognitionLoadingPage(),
        '/result': (context) => const RecognitionResultPage(),
        '/edit': (context) => const RecognitionEditPage(),
      },
>>>>>>> Stashed changes
    );
  }
}