import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'recognition_result_page.dart';
import '../services/api_service.dart';

// 注意：原程式碼中引用了 RecognitionLoadingPage，
// 但在 RecognitionEditPage 類別中並未導入。
// 為了程式碼的完整性，我會暫時使用 RecognitionResultPage 替換，
// 但建議您檢查並確認 RecognitionLoadingPage 的路徑。
// 為了遵循原程式碼邏輯，我將其改為 _updateProduct 方法中正確的導航邏輯。

class RecognitionEditPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const RecognitionEditPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  static const Color _primaryGreen = Colors.green;

  late TextEditingController nameController;
  late TextEditingController dateController;
  // 注意：原程式碼中這裡有 priceController, proPriceController, marketController
  // 您的需求程式碼中用了 originalPriceController, discountPriceController, 但少了 Market。
  // 為保持與 initState 和 _updateProduct 的一致性，我使用原始的名稱。
  late TextEditingController priceController;
  late TextEditingController proPriceController;
  late TextEditingController marketController; 

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit');
    nameController = TextEditingController(text: widget.productInfo?["ProName"]);
    dateController = TextEditingController(text: widget.productInfo?["ExpireDate"]);
    priceController = TextEditingController(text: widget.productInfo?["Price"]?.toString());
    proPriceController = TextEditingController(text: widget.productInfo?["ProPrice"]?.toString());
    marketController = TextEditingController(text: widget.productInfo?["Market"]);
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    priceController.dispose();
    proPriceController.dispose();
    marketController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    final productId = widget.productInfo?["ProductID"];
    if (productId == null) return;

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/product/$productId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ProName": nameController.text,
        "ExpireDate": dateController.text,
        "Price": int.tryParse(priceController.text),
        "ProPrice": int.tryParse(proPriceController.text),
        "Market": marketController.text,
      }),
    );

    if (res.statusCode == 200) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecognitionResultPage(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: {
                "ProductID": productId,
                "ProName": nameController.text,
                "ExpireDate": dateController.text,
                "Price": priceController.text,
                "ProPrice": proPriceController.text,
                "Market": marketController.text,
              },
            ),
          ),
        );
      }
    } else {
      // 建議在實際 APP 中使用 ScaffoldMessenger 顯示錯誤
      print("更新失敗: ${res.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      // 💡 關鍵修正一：允許 Scaffold 自動調整佈局以避免鍵盤彈出時的溢位
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        // 💡 關鍵修正二：使用 SingleChildScrollView 包裹整個內容
        child: SingleChildScrollView(
          // reverse: true, // reverse: true 較適合聊天應用，對表單來說，預設滾動通常更自然
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
          child: Column(
            // 💡 關鍵修正三：為了讓鍵盤彈出時能看到輸入框，我們需要添加一個空間
            // 這樣即使鍵盤彈出，也不會遮擋住最後一個輸入框和按鈕。
            // 由於 SingleChildScrollView 本身能捲動，這裡不需要 reverse: true
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
                  // Logo 
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 顯示圖片
              if (widget.imagePath != null)
                Image.file(File(widget.imagePath!), height: 200, fit: BoxFit.contain),
              // 注意：原程式碼中使用 Image.file(File(widget.imagePath!))
              // 您提供的範例程式碼中使用 Image.asset('assets/milk.jpg')
              // 這裡以您的原邏輯為主：
              // if (widget.imagePath != null)
              //   Image.file(File(widget.imagePath!), height: 200, fit: BoxFit.contain),

              const SizedBox(height: 20),

              // --- 輸入欄位 ---
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
                  labelText: '有效期限 (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: priceController, // 使用原始的 priceController
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '原價',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: proPriceController, // 使用原始的 proPriceController
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '優惠價', // 使用原始的 '優惠價'
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: marketController,
                decoration: const InputDecoration(
                  labelText: '賣場',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- 送出按鈕 ---
              ElevatedButton(
                onPressed: _updateProduct, // 點擊送出後執行更新 API
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