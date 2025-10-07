import 'dart:io';
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart'; // ✅ 導向目標
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';
import 'recognition_loading_page.dart'; 

class RecognitionResultPage extends StatelessWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  static const Color _lightGreenBackground = Color(0xFFE8F5E9);

  const RecognitionResultPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  Widget build(BuildContext context) {
    saveCurrentRoute('/resultCheck');

    final name = productInfo?["ProName"] ?? "未知商品";
    final date = productInfo?["ExpireDate"] ?? "未知日期";
    final price = productInfo?["Price"] ?? "未知價格";
    final proprice = productInfo?["ProPrice"] ?? "未知優惠";
    final market = productInfo?["Market"] ?? "未知賣場";

    return Scaffold(
      backgroundColor: _lightGreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // 拍攝的圖片 (如果有)
            if (imagePath != null)
              Image.file(File(imagePath!), height: 200, fit: BoxFit.contain)
            else
              Image.asset('assets/milk.jpg', height: 200, fit: BoxFit.contain),
            const SizedBox(height: 20),

            // 商品資訊
            Text("商品名稱：$name",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("有效期限：$date",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("原價：$price",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("即期價格：$proprice",
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("賣場：$market",
                style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 驗證文字
            const Text(
              '產品名稱及有效期限是否正確？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 「正確」按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoadingPage( // or CountingPage
                      userId: userId,
                      userName: userName,
                      token: token,
                      imagePath: imagePath,
                      productInfo: productInfo,
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
                      userId: userId,
                      userName: userName,
                      token: token,
                      imagePath: imagePath,
                      productInfo: productInfo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 157, 92),
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  const Text('手動修改', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「重新掃描」按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanningPicturePage(
                      userId: userId,
                      userName: userName,
                      token: token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 138, 179),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}