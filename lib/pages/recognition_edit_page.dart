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
  final TextEditingController nameController =
      TextEditingController(text: '瑞穗鮮乳・全脂290ml');
  final TextEditingController dateController =
      TextEditingController(text: '2025-05-25');

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit'); // ✅ 記錄當前頁面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F3DA),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // ←返回 Result Page
                  },
                  child: const Icon(Icons.arrow_back_ios),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LOGO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/milk.jpg',
              height: 200,
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