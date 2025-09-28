import 'package:flutter/material.dart';
import '../services/route_logger.dart'; // 確保路徑正確

// 🎯 背景色常量
const Color _kSplashBackgroundColor = Color(0xFFFAF0D3); 
const Color _kPrimaryGreen = Color(0xFF2E7D32); // 此常量不再用於載入圖，但保留

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/splash'); // 記錄當前頁面
    _navigateToNextScreen();
  }

  // 設定跳轉邏輯
  void _navigateToNextScreen() async {
    // 延遲 10 秒後自動跳轉
    await Future.delayed(const Duration(seconds: 20));

    if (mounted) {
      // 使用 pushReplacementNamed 跳轉到登入頁面，並清除當前路由
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      // 🎯 使用背景色常量
      backgroundColor: _kSplashBackgroundColor, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 保持 Logo 垂直置中
          children: [
            // 圖片資產 (Logo)
            Image.asset(
              'assets/splash_background.jpg', 
              // 💡 調整高度到 400，您可以根據需要再微調
              height: 875, 
              fit: BoxFit.contain, // 保持圖片完整顯示，不裁切
            ),
            
            // 🎯 核心修正: 移除 SizedBox 和 CircularProgressIndicator
            // 
            // 之前的程式碼:
            // const SizedBox(height: 50),
            // CircularProgressIndicator(...)
            
          ],
        ),
      ),
    );
  }
}