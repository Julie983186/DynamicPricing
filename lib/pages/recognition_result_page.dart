import 'dart:io';
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart';
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';
import 'recognition_loading_page.dart'; 
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

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

  /// 刪除商品後重新掃描
  Future<void> _deleteProductAndRescan(int productId, BuildContext context) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/product/$productId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('商品已刪除，請重新掃描'),
              backgroundColor: Colors.green,
            ),
          );
        }

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
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('刪除商品失敗: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('刪除商品失敗: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('連線錯誤: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('連線錯誤: $e');
    }
  }

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

            // 拍照圖片 
            if (imagePath != null)
              Image.file(File(imagePath!), height: 200, fit: BoxFit.contain)
            else
              Image.asset('assets/milk.jpg', height: 200, fit: BoxFit.contain),
            const SizedBox(height: 20),

            // 商品資訊
            Text("商品名稱：$name", style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("有效期限：$date", style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("原價：$price", style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("即期價格：$proprice", style: const TextStyle(fontSize: 18, color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("賣場：$market", style: const TextStyle(fontSize: 18, color: Colors.blueGrey), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 確認 ORC 辨識文字
            const Text(
              '產品名稱及有效期限是否正確？',
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 正確送出資料
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoadingPage(
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

            // 手動修改資料
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
              child: const Text('手動修改', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 重新掃描
            ElevatedButton(
              onPressed: () async {
                final productId = productInfo?["ProductID"];
                if (productId != null) {
                  await _deleteProductAndRescan(productId, context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
