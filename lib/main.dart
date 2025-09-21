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
      title: '註冊登入範例',
      debugShowCheckedModeBanner: false,
      // 暫時將初始頁面設定為 MemberAreaPage
      home: MemberAreaPage(userName: '測試使用者'),
    );
  }
}
