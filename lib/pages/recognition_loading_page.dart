// lib/pages/recognition_loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/route_logger.dart';
import 'recognition_result_page.dart';


class RecognitionLoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionLoadingPage({super.key, this.userId, this.userName, this.token});

  @override
  State<RecognitionLoadingPage> createState() => _RecognitionLoadingPageState();
}


class _RecognitionLoadingPageState extends State<RecognitionLoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/loading'); // 記錄當前頁面
    // 3秒後結果確認
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionResultPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 將背景色改為 0xFFE8F5E9
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 替換 'LOGO' 文字為圖片
            Image.asset(
              'assets/logo.png', // 您的 Logo 圖片路徑
              height: 150, // 調整圖片高度，您可以根據需求修改
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              '辨識進行中...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C), // 調整文字顏色為深綠
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '請稍待',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF689F38), // 調整文字顏色為較亮綠
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF388E3C)), // 調整進度指示器顏色
          ],
        ),
      ),
    );
  }
}