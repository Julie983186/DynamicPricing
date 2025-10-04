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
  final TextEditingController originalPriceController =
      TextEditingController(text: '35'); // 預設原價
  final TextEditingController discountPriceController =
      TextEditingController(text: '25'); // 預設即期價

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit');
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    originalPriceController.dispose();
    discountPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      resizeToAvoidBottomInset: true, // 保證鍵盤彈出時自動調整
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // 鍵盤彈出時自動滾動到底部
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
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Image.asset(
                'assets/milk.jpg',
                height: 200,
                fit: BoxFit.contain,
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
              const SizedBox(height: 15),

              TextField(
                controller: originalPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '原價',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: discountPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '即期價',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecognitionLoadingPage(
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
      ),
    );
  }
}
