import 'package:flutter/material.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import 'countingresult.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
// import 'register_login_page.dart'; // 移除不必要的自我引用

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
      height: 150, // 增加 Logo 容器的高度
      width: 300,
      child: Image.asset(
        'assets/logo.png', // 確保這是你的 Logo 圖片正確路徑
        width: 300,
        fit: BoxFit.contain, // 確保圖片完整顯示不裁切
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
                    width: 300, // 註冊/登入卡片的寬度
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
                        // TabBarView 設定固定高度 380
                        SizedBox(
                          height: 380,
                          child: TabBarView(
                            children: [
                              RegisterForm(),
                              LoginForm(), // LoginForm 現在使用 spaceBetween
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // 底部間距
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

  // 註冊邏輯方法
  void submitRegister() async {
    // 假設 registerUser 是已定義的異步服務方法
    // 這裡我們假設它已定義在 api_service.dart 中
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
    // 註冊表單仍使用預設的 start 對齊，因為內容較多，本身就比較貼近底部
    return Column(
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        
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

  // 登入邏輯方法
  void submitLogin() async {
    // 假設 loginUser 是已定義的異步服務方法
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
    // 💡 關鍵修改點：使用 MainAxisAlignment.spaceBetween
    return Column(
      // 使用 spaceBetween 讓內容（頂部輸入框組和底部按鈕組）在固定高度內撐開
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Email 和密碼欄位 (貼齊頂部)
        Column(
          mainAxisSize: MainAxisSize.min, // 確保這組 Column 只佔用最小高度
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        
        // 2. 登入和訪客按鈕 (貼齊底部)
        Column(
          mainAxisSize: MainAxisSize.min, // 確保這組 Column 只佔用最小高度
          children: [
            const SizedBox(height: 20), // 登入按鈕上方的間距
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
            
            const SizedBox(height: 10), // 按鈕間的間距
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