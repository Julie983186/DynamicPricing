import 'package:flutter/material.dart';
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
      title: '碳即',
      debugShowCheckedModeBanner: false,
      // 一開始進入登入/註冊頁
      home: const RegisterLoginPage(),
    );
  }
}
