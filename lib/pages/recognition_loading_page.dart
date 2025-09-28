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
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              'assets/logo.png',
              height: 140,
            ),
            const SizedBox(height: 40),

            // text
            const Text(
              '辨識進行中...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '請稍待',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // loading indicator
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}