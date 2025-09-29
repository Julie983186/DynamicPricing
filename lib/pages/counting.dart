import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'countingresult.dart';

class LoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const LoadingPage({super.key, this.userId, this.userName, this.token});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/counting'); // 記錄當前頁面
    // 模擬計算，2秒後跳轉到結果頁
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CountingResult(
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 替換 'LOGO' 文字為圖片
              Image.asset(
                'assets/logo.png', // 您的 Logo 圖片路徑
                height: 150, // 調整圖片高度，您可以根據需求修改
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                '價格計算中...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }
}