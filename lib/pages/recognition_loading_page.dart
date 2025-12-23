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
  final String? market; // 保留賣場名稱

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
  String _statusMessage = "請稍待";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // 呼叫實際的 OCR 處理功能
    _processImage();
    saveCurrentRoute('/loading'); 
  }

  // 處理圖片上傳和 OCR 請求
  Future<void> _processImage() async {
    try {
      // 確保 imagePath 不為 null
      if (widget.imagePath == null) {
        throw Exception("Image path is null.");
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ocr'),
      );

      // 1. 上傳圖片檔案
      request.files.add(
        await http.MultipartFile.fromPath('image', widget.imagePath!),
      );
      
      // 2. market 欄位
      request.fields['market'] = widget.market ?? '未知賣場';

      // 3. 帶入 JWT Token
      if (widget.token != null) {
        request.headers['Authorization'] = 'Bearer ${widget.token}';
      }

      // 4. 發送請求並等待回應
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final productInfo = json.decode(respStr);
      print(productInfo);
      
      // 5. 處理成功或失敗
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        // 成功，導航到結果頁面
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
      } else {
        _handleError("伺服器回應失敗: ${response.statusCode}");
      }

    } catch (e) {
      _handleError("OCR 處理失敗: $e");
    }
  }
  
  // 錯誤處理函式
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isError = true;
        _statusMessage = message;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
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
            // LOGO
            Image.asset(
              'assets/logo.png',
              height: 140,
            ),
            const SizedBox(height: 40),

            // 狀態文字
            Text(
              _isError ? '辨識失敗' : '辨識進行中...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isError ? Colors.red : const Color.fromARGB(255, 0, 0, 0), 
              ),
            ),
            const SizedBox(height: 10),
            
            // 進度或錯誤訊息
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // loading indicator
            _isError
                ? const Icon(Icons.error_outline, color: Colors.red, size: 50) 
                : const CircularProgressIndicator(color: Color(0xFF388E3C)), 
          ],
        ),
      ),
    );
  }
}