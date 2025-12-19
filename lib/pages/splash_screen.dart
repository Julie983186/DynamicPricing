import 'package:flutter/material.dart';
import '../services/route_logger.dart'; 

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

  // 設定跳轉
  void _navigateToNextScreen() async {
    // 延遲 3 秒後自動跳轉
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      //跳轉到登入頁面
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0D0), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash_background.jpg',
              width: MediaQuery.of(context).size.width * 0.8, // 螢幕 80% 寬
              fit: BoxFit.contain,
            ),
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