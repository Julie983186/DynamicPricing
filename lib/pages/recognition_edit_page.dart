import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart';
import 'recognition_loading_page.dart'; 

class RecognitionEditPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionEditPage({super.key, this.userId, this.userName, this.token});

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  static const Color _primaryGreen = Colors.green;

  final TextEditingController nameController =
        TextEditingController(text: '瑞穗鮮乳・全脂290ml');
  final TextEditingController dateController =
        TextEditingController(text: '2025-10-02');

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit');
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 返回按鈕靠左，LOGO 居中
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios, color: _primaryGreen),
                  ),
                ),
                // Logo 放大
                Image.asset(
                  'assets/logo.png',
                  height: 100, // 將 Logo 放大
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Image.asset(
              'assets/milk.jpg',
              height: 200,
              fit: BoxFit.contain, // 加上 fit: BoxFit.contain 確保圖片完整顯示
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: '有效期限',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognitionLoadingPage( // 修正為 RecognitionLoadingPage
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
             
              child: const Text(
                '送出',
                style: TextStyle(color: Colors.white, fontSize: 16), 
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}