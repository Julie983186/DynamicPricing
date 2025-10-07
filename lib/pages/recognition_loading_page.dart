import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../services/route_logger.dart';
import 'package:http/http.dart' as http;
import 'recognition_result_page.dart';
import 'dart:io';
import '../services/api_service.dart';

class RecognitionLoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final String? market; // 👈 新增傳入的賣場名稱

  const RecognitionLoadingPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.market,
  });

  @override
  State<RecognitionLoadingPage> createState() => _RecognitionLoadingPageState();
}

class _RecognitionLoadingPageState extends State<RecognitionLoadingPage> {
  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ocr'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', widget.imagePath!),
      );
      request.fields['market'] = widget.market ?? '未知賣場';

      // 👉 帶入 JWT Token
      if (widget.token != null) {
        request.headers['Authorization'] = 'Bearer ${widget.token}';
      }

      // 再去抓最新資料
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final productInfo = json.decode(respStr);
      print(productInfo);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionResultPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
            imagePath: widget.imagePath,
            productInfo: productInfo,
          ),
        ),
      );
    } catch (e) {
      print("❌ OCR failed: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text("辨識中，請稍候..."),
          ],
        ),
      ),
    );
  }
}