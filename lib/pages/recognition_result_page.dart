// lib/pages/recognition_result_page.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart';
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';


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
  // 設置要求的背景色
  static const Color _lightGreenBackground = Color(0xFFE8F5E9); 

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/resultCheck'); // 記錄當前頁面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 將背景色改為 0xFFE8F5E9
      backgroundColor: _lightGreenBackground, 
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 替換 'LOGO' 文字為圖片
            Image.asset(
              'assets/logo.png', // 您的 Logo 圖片路徑
              height: 40, // 設定圖片高度
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

            // 「正確」按鈕 (維持導航到 LoadingPage)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 保持原始程式碼的導航目標：LoadingPage
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
              child: const Text('正確'),
            ),
            const SizedBox(height: 10),

            // 「手動修改」按鈕 (維持不變)
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
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('手動修改'),
            ),
            const SizedBox(height: 10),

            // 「重新掃描」按鈕 (維持不變)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
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
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描'),
            ),
          ],
        ),
      ),
    );
  }
}