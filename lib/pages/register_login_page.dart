import 'package:flutter/material.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import 'countingresult.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

// 定義會員頁面的淺綠色背景
const Color _kLightGreenBg = Color(0xFFE8F5E9);

// 註冊與登入頁面
class RegisterLoginPage extends StatefulWidget {
  const RegisterLoginPage({super.key});

  @override
  State<RegisterLoginPage> createState() => _RegisterLoginPageState();
}

class _RegisterLoginPageState extends State<RegisterLoginPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/login'); // 記錄當前頁面
  }

  // Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox(
      height: 150,
      width: 300,
      child: Image.asset(
        'assets/logo.png',
        width: 300,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _kLightGreenBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  _buildLogo(),
                  const SizedBox(height: 20),
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        TabBar(
                          labelColor: Colors.black,
                          indicatorColor: Colors.green,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 450, // 可根據內容調整高度
                          child: TabBarView(
                            children: [
                              RegisterForm(),
                              LoginForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 輔助函式: 建立文字輸入框
Widget buildTextField(String label,
    {bool obscureText = false, TextEditingController? controller}) {
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

// --- 註冊表單 (RegisterForm) ---
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submitRegister() async {
    try {
      bool isSuccess = await registerUser(
        nameController.text,
        phoneController.text,
        emailController.text,
        passwordController.text,
      );

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 2));
        DefaultTabController.of(context)?.animateTo(1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊失敗，請重試。'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 上半部分: 輸入欄位
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('姓名', controller: nameController),
            buildTextField('電話', controller: phoneController),
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        // 下半部分: 按鈕
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '註冊',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanningPicturePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF274E13)),
              ),
              child: const Text(
                '以訪客身份使用',
                style: TextStyle(color: Color(0xFF274E13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- 登入表單 (LoginForm) ---
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submitLogin() async {
    final user = await loginUser(
      emailController.text,
      passwordController.text,
    );

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanningPicturePage(
            userId: user['id'] as int,
            userName: user['name'] as String,
            token: user['token'] as String,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登入失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 上半部分: Email / 密碼
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        // 下半部分: 按鈕
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '登入',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanningPicturePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF274E13)),
              ),
              child: const Text(
                '以訪客身份使用',
                style: TextStyle(color: Color(0xFF274E13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
