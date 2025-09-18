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
Future<bool> loginUser(String email, String password) async {
  //final String ip = kIsWeb ? 'http://127.0.0.1:5000' : 'http://你的局域網IP:5000';
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      print('登入成功');
      return true;
    } else {
      print('登入失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
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
