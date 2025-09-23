import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import to pages
import 'pages/scanning_picture_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
import 'pages/register_login_page.dart';  // 引入登入註冊頁
import 'pages/member_area_page.dart';    // 引入會員專區頁
import 'pages/home_page.dart';            // 引入首頁
import 'pages/counting.dart';
import 'pages/countingresult.dart';
import 'pages/adviceproduct.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '碳即',
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

      // all routes
      routes: {
        // login group
        '/login': (context) => const RegisterLoginPage(),
        //'/member': (context) => const MemberAreaPage(userName: '測試使用者'),

        // recognition group
        '/loading': (context) => const RecognitionLoadingPage(),
        '/resultCheck': (context) => const RecognitionResultPage(),
        '/edit': (context) => const RecognitionEditPage(),
      },
      // 一開始進入登入/註冊頁
      home: const RegisterLoginPage(),
    );
  }
}