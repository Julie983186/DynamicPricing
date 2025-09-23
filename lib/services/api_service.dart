import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // 導入剛剛的檔案
import 'package:flutter/foundation.dart';

// 函式現在回傳 Future<bool>，用來表示成功或失敗
Future<bool> registerUser(String name, String phone, String email, String password) async {
  //final String ip = kIsWeb ? 'http://127.0.0.1:5000' : 'http://172.20.10.2:5000';
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/register');

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
      return true; // 註冊成功，回傳 true
    } else {
      print('註冊失敗: ${response.body}');
      return false; // 註冊失敗，回傳 false
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false; // 連線錯誤，回傳 false
  }
}

// 新增登入函式
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'id': data['user']['id'],
        'name': data['user']['name'],
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





class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: '姓名')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: '電話')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: '密碼'), obscureText: true),
            ElevatedButton(
              onPressed: () {
                registerUser(
                  nameController.text,
                  phoneController.text,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: Text('註冊'),
            )
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> fetchUserData(int userId) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/user/$userId');

  try {
    final response = await http.get(url);

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

// 更新會員資料函式，允許更新電話和密碼
Future<bool> updateUserData({
  required int userId,
  String? name,
  String? email,
  String? phone,
  String? password,
}) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/user/$userId');

  // 只放入有值的欄位
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
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


