import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb

/// ------------------ 全域 IP 設定 ------------------
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.154:5000'; 
}
/// ------------------ 註冊 ------------------
Future<bool> registerUser(String name, String phone, String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('註冊成功');
      return true;
    } else {
      print('註冊失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 登入 ------------------
/// 回傳 id, name, token
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("login success data = $data");
      return {
        'id': data['user']['id'],
        'name': data['user']['name'],
        'token': data['token'], // ✅ JWT token
      };
    } else {
      print('登入失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 抓取會員資料 ------------------
/// 需要帶 token
Future<Map<String, dynamic>?> fetchUserData(int userId, String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('取得會員資料失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 更新會員資料 ------------------
/// 需要帶 token
Future<bool> updateUserData({
  required int userId,
  required String token,
  String? name,
  String? email,
  String? phone,
  String? password,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

  final Map<String, dynamic> body = {};
  if (name != null) body['name'] = name;
  if (email != null) body['email'] = email;
  if (phone != null) body['phone'] = phone;
  if (password != null) body['password'] = password;

  if (body.isEmpty) {
    print('沒有可更新的欄位');
    return false;
  }

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('更新成功: ${response.body}');
      return true;
    } else {
      print('更新失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 註冊畫面 ------------------
class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: '電話')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: '密碼'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await registerUser(
                  nameController.text,
                  phoneController.text,
                  emailController.text,
                  passwordController.text,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('註冊成功')),
                  );
                }
              },
              child: const Text('註冊'),
            )
          ],
        ),
      ),
    );
  }
}

/// ------------------ 抓取會員歷史商品紀錄 ------------------
/// 需要帶 token，可選擇帶日期（dateString）
Future<List<dynamic>> fetchHistoryProducts(
  int userId,
  String? token, {
  String? dateString,
}) async {
  try {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/get_products/$userId' +
          (dateString != null ? '?date=$dateString' : ''),
    );

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      } else {
        print('回傳資料格式錯誤: $data');
        return [];
      }
    } else {
      print('取得歷史紀錄失敗: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    print('連線錯誤: $e');
    return [];
  }
}

/// ------------------ 儲存訪客歷史紀錄 ------------------
Future<bool> saveGuestHistory(int productId, String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/save_guest_history');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 登入後才會有 token
      },
      body: jsonEncode({'productID': productId}),
    );

    if (response.statusCode == 200) {
      debugPrint('歷史紀錄儲存成功');
      return true;
    } else {
      debugPrint('歷史紀錄儲存失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 抓取單筆商品 AI 價格 ------------------
Future<double?> fetchAIPrice(int productId) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/predict_price');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      // 改用 ProductID 找對應商品
      final match = data.firstWhere(
        (item) => item['ProductID'] == productId,
        orElse: () => null,
      );

      if (match != null) {
        return (match['AiPrice'] as num).toDouble();
      } else {
        debugPrint("找不到對應商品的 AI 價格: ProductID=$productId");
        return null;
      }
    } else {
      debugPrint("抓 AI 價格失敗: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("抓 AI 價格失敗: $e");
    return null;
  }
}

//登入儲存掃描紀錄
Future<bool> saveScanRecord({
  required int userId,
  required String token,
  required int productId,
}) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/scan_records'); // <-- 確認路徑
    final body = jsonEncode({
      'userId': userId,
      'productId': productId,
    });

    print('🔹 saveScanRecord URL: $url');
    print('🔹 saveScanRecord body: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ saveScanRecord 成功: productId=$productId");
      return true;
    } else {
      print("❌ saveScanRecord 失敗: ${response.statusCode} ${response.body}");
      return false;
    }
  } catch (e) {
    print("❌ saveScanRecord 例外: $e");
    return false;
  }
}
