import 'package:flutter/material.dart';
import '../services/route_logger.dart'; // 確保路徑正確

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
    // 延遲 3 秒後自動跳轉
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      // 使用 pushReplacementNamed 跳轉到登入頁面，並清除當前路由
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 這裡我們使用一個簡單的、與你的 LOGO 主題相符的背景
    // 你可以替換為你的資產圖片，如果你的圖片路徑是 'assets/splash_image.jpg'
    
    // 假設你的 LOGO 圖片（如你上傳的 `image_171c04.jpg` 所示）
    // 已經放在 assets 資料夾中，並且你已在 pubspec.yaml 中註冊該資料夾。
    
    // 如果你沒有使用圖片，則使用純色背景和文字 LOGO
    return Scaffold(
      // 背景色使用與圖片相符的淺黃/淺綠色調
      backgroundColor: const Color(0xFFF5F0D0), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 這是使用圖片資產的方法（請確保路徑正確）
            Image.asset(
              'assets/splash_background.jpg',
              width: MediaQuery.of(context).size.width * 0.8, // 螢幕 80% 寬
              fit: BoxFit.contain,
            ),
            // 如果不想用圖片，只想用文字和顏色
            /*
            const Text(
              '碳即',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            */
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }
}