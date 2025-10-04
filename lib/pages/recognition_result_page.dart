import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart'; // 導向目標
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
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            Image.asset(
              'assets/milk.jpg',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // 商品資訊區塊 (背景與頁面一致)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  '商品名稱：瑞穗鮮乳・全脂290ml',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  '有效期限：2025-10-02',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  '原價：32元',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  '即期價：30元',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              '產品名稱、價格及有效期限是否正確？',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
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

            // 「手動修改」按鈕
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

            // 「重新掃描」按鈕
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
