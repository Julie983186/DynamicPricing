import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'recognition_result_page.dart';

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
      Uri.parse("http://192.168.0.129:5000/product/$productId"),
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
    } else {
      print("更新失敗: ${res.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: _primaryGreen),
                  ),
                ),
                Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.imagePath != null)
              Image.file(File(widget.imagePath!), height: 200, fit: BoxFit.contain),

            const SizedBox(height: 20),

            TextField(controller: nameController, decoration: const InputDecoration(labelText: '商品名稱', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: '有效期限 (YYYY-MM-DD)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '原價', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: proPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '優惠價', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: marketController, decoration: const InputDecoration(labelText: '賣場', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updateProduct,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              child: const Text('送出', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
