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