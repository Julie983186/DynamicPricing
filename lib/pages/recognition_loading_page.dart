// lib/pages/recognition_loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/route_logger.dart';


class RecognitionLoadingPage extends StatefulWidget {
  const RecognitionLoadingPage({super.key});

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
      Navigator.pushReplacementNamed(context, '/resultCheck');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F3DA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'LOGO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '辨識進行中...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '請稍待',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}