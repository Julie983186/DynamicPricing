import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart';

class RecognitionEditPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionEditPage({super.key, this.userId, this.userName, this.token});

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  // 標準背景色設定
  static const Color _standardBackground = Color(0xFFE8F5E9); 
  // 為了保持返回按鈕的顏色與 LOGO 文字原本的綠色一致，我們定義一個綠色常數。
  static const Color _primaryGreen = Colors.green; 

  final TextEditingController nameController =
      TextEditingController(text: '瑞穗鮮乳・全脂290ml');
  final TextEditingController dateController =
      TextEditingController(text: '2025-10-02');

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit'); // ✅ 記錄當前頁面
  }

  @override
  void dispose() {
    nameController.dispose(); // 良好習慣：釋放資源
    dateController.dispose(); // 良好習慣：釋放資源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景顏色修改為 0xFFE8F5E9
      backgroundColor: _standardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 使用 Stack 實現返回按鈕靠左，LOGO 居中
            Stack(
              alignment: Alignment.center,
              children: [
                // 返回按鈕 (靠左)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // ←返回 Result Page
                    },
                    child: const Icon(Icons.arrow_back_ios, color: _primaryGreen),
                  ),
                ),
                // LOGO 圖片 (居中)
                Image.asset(
                  'assets/logo.png', // 您的 Logo 圖片路徑
                  height: 35, 
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 圖片
            Image.asset(
              'assets/milk.jpg',
              height: 200,
            ),
            const SizedBox(height: 20),
            
            // 商品名稱輸入框
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            // 有效期限輸入框
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: '有效期限',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // 「送出」按鈕 (保持原始邏輯：導向 LoadingPage)
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
              child: const Text('送出'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}