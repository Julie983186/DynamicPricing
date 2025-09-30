import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart'; // ✅ 導向目標
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';
import 'recognition_loading_page.dart'; 

class RecognitionResultPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionResultPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
  });

  @override
  State<RecognitionResultPage> createState() => _RecognitionResultPageState();
}

class _RecognitionResultPageState extends State<RecognitionResultPage> {
  static const Color _lightGreenBackground = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/resultCheck');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 放大 Logo
            Image.asset(
              'assets/logo.png',
              height: 100, // Logo 放大
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            Image.asset(
              'assets/milk.jpg',
              height: 200,
            ),
            const SizedBox(height: 20),

            const Text(
              '商品名稱：瑞穗鮮乳・全脂290ml',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const Text(
              '有效期限：\n2025-10-02',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            const Text(
              '產品名稱及有效期限是否正確？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // 「正確」按鈕
            ElevatedButton(
              onPressed: () {
                // 🎯 修正導航目標：導向 CountingPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 假設 counting.dart 中定義的頁面為 CountingPage
                    builder: (_) => LoadingPage( 
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('正確', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「手動修改」按鈕 (導向 RecognitionEditPage)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognitionEditPage(
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 157, 92),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('手動修改', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「重新掃描」按鈕 (導向 ScanningPicturePage)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanningPicturePage(
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 138, 179),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}