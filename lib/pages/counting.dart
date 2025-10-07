import 'package:flutter/material.dart';
import 'dart:async'; // 確保引入 dart:async
import '../services/route_logger.dart';
import 'countingresult.dart';
import 'dart:io';

class LoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const LoadingPage({super.key, this.userId, this.userName, this.token, this.imagePath, this.productInfo});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/counting'); // 記錄當前頁面
    
    // 🎯 保持原始邏輯：模擬計算，2秒後跳轉到結果頁
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { 
        // 使用 pushReplacement 較佳，但為保持原邏輯，這裡使用 push
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountingResult(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: widget.productInfo,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 背景色保持不變
      body: Center( // 🎯 移除 SafeArea，直接使用 Center
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              'assets/logo.png', // 您的 Logo 圖片路徑
              height: 140, // 🎯 調整圖片高度為 140
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40), // 🎯 調整間距為 40

            // 標題文字
            const Text(
              '價格計算中...', // 保持原始文字
              style: TextStyle(
                fontSize: 20, // 🎯 調整字體大小為 20
                fontWeight: FontWeight.bold, // 🎯 調整字體粗細為 bold
                color: Colors.black, // 🎯 調整文字顏色為黑色
              ),
            ),
            const SizedBox(height: 10),
            
            // 副標題文字
            const Text(
              '請稍待',
              style: TextStyle(
                fontSize: 16, // 🎯 調整字體大小為 16
                color: Colors.black54, // 🎯 調整文字顏色為 Colors.black54
              ),
            ),
            const SizedBox(height: 30), // 🎯 調整間距為 30

            // 🎯 loading indicator
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}