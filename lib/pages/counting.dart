import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'countingresult.dart';
import 'dart:io';
import '../services/api_service.dart';


class LoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const LoadingPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/counting');

    // 延遲 0.5 秒後開始呼叫 API 計算
    Future.delayed(const Duration(milliseconds: 500), _fetchAiPriceAndGo);
  }

  Future<void> _fetchAiPriceAndGo() async {
    if (widget.productInfo == null) return;

    try {
      final productId = widget.productInfo!["ProductID"];

      // 🔹 呼叫後端 /predict_price API
      final uri = Uri.parse("${ApiConfig.baseUrl}/predict_price?productId=$productId");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        // 找到對應 ProductID 的結果
        final productData =
            data.firstWhere((e) => e["ProductID"] == productId, orElse: () => null);

        if (productData != null) {
          final updatedProductInfo = {
            ...?widget.productInfo,
            "AiPrice": productData["AiPrice"],
            "Reason": productData["Reason"],
          };

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CountingResult(
                  userId: widget.userId,
                  userName: widget.userName,
                  token: widget.token,
                  imagePath: widget.imagePath,
                  productInfo: updatedProductInfo,
                ),
              ),
            );
          }
        } else {
          throw Exception("找不到對應的 ProductID");
        }
      } else {
        throw Exception("API 回傳錯誤: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 呼叫 AI 價格 API 發生錯誤: $e");

      // 🔹 出錯也跳轉到結果頁顯示原始資料
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CountingResult(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: widget.productInfo,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const Text(
              '價格計算中...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '請稍待',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
