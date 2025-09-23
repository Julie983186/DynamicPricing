import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import to pages
import 'pages/camera_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
import 'pages/register_login_page.dart';  // 引入登入註冊頁
import 'pages/member_area_page.dart';    // 引入會員專區頁
// 引入首頁

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Pricing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),

      // localize
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
      ],

      // sinitial route
      initialRoute: '/camera',

      // all routes
      routes: {
        // camera group
        '/camera': (context) => const CameraPage(),
       
        // login group
        '/login': (context) => const RegisterLoginPage(),
        //'/member': (context) => const MemberAreaPage(userName: '測試使用者'),

        // recognition group
        '/loading': (context) => const RecognitionLoadingPage(),
        '/resultCheck': (context) => const RecognitionResultPage(),
        '/edit': (context) => const RecognitionEditPage(),
      },
      title: '碳即',
      debugShowCheckedModeBanner: false,
      // 一開始進入登入/註冊頁
      home: const RegisterLoginPage(),
    );
  }
}