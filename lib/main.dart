import 'package:flutter/material.dart';
import 'pages/register_login_page.dart';  // 引入登入註冊頁
import 'pages/home_page.dart';            // 引入首頁
import 'pages/counting.dart';
import 'pages/countingresult.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '註冊登入範例',
      debugShowCheckedModeBanner: false,
      // 初始頁面設定為 RegisterLoginPage
      home: const CountingResult(),
    );
  }
}
