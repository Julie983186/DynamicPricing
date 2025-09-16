import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/api_service.dart'; // 引入 api_service.dart

// 註冊與登入頁面
class RegisterLoginPage extends StatelessWidget {
  const RegisterLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFD9EAD3),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    'LOGO',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF274E13),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 244, 242, 242).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.black,
                          indicatorColor: Colors.green,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            children: [
                              // 註冊會員表單 - 使用修正後的 StatefulWidget
                              RegisterForm(),
                              // 會員登入表單
                              LoginForm(),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('以訪客身份使用'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 修正後的註冊表單，使用 StatefulWidget
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // 定義 TextEditingController 來獲取輸入框的內容
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final accountController = TextEditingController();
  final passwordController = TextEditingController();

  // 將 buildTextField 移到類別內部，確保正確使用控制器
  Widget buildTextField(String label, {bool obscureText = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('帳號', controller: accountController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              bool isSuccess = await registerUser(
                nameController.text,
                phoneController.text,
                accountController.text,
                passwordController.text,
              );

              if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('註冊成功！'),
                    backgroundColor: Colors.green,
                  ),
                );
                await Future.delayed(const Duration(seconds: 2));
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('註冊失敗，請重試。'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('發生錯誤: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('註冊'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final accountController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTextField('帳號', controller: accountController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              bool isSuccess = await loginUser(
                accountController.text,
                passwordController.text,
              );

              if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('登入成功！'),
                    backgroundColor: Colors.green,
                  ),
                );
                await Future.delayed(const Duration(seconds: 1));
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('登入失敗，請檢查帳號或密碼'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('發生錯誤: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('登入'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}


// 輔助函式，用於建立帶有控制器的 TextField，但現在它只在 LoginForm 內部被使用
Widget buildTextField(String label, {bool obscureText = false, TextEditingController? controller}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );
}