import 'package:flutter/material.dart';
import 'scanning_picture_page.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

// 💡 新增: 定義會員頁面的淺綠色背景
const Color _kLightGreenBg = Color(0xFFE8F5E9); 
const Color _kPrimaryGreen = Color(0xFF388E3C); // 定義綠色方便 TabBar 使用
const Color _kAccentOrange = Colors.orange; // 註冊/登入按鈕使用

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
    // 💡 確保導航到登入頁面時，可以正確記錄路徑
    saveCurrentRoute('/login'); 
  }

  // 💡 Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox( 
      height: 150, 
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
                  const SizedBox(height: 30), // 調整頂部間距
                  _buildLogo(),
                  const SizedBox(height: 20), // 縮小 Logo 與下方卡片的間距

                  Container(
                    width: 300, // 註冊/登入卡片的寬度
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // 稍微調高透明度
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.black,
                          indicatorColor: _kPrimaryGreen,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // 🎯 核心修正 1: 確保 TabBarView 有固定的高度
                        SizedBox( 
                          height: 330, // 固定的高度，確保按鈕能對齊
                          child: const TabBarView(
                            physics: NeverScrollableScrollPhysics(), 
                            children: [
                              RegisterForm(),
                              LoginForm(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20), 
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
                            side: const BorderSide(color: Color(0xFF274E13)), // 綠色邊框
                          ),
                          child: const Text(
                            '以訪客身份使用',
                            style: TextStyle(color: Color(0xFF274E13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // 底部間距
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 輔助函式 (保持不變)
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

// --- 註冊表單 (已修正) ---
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

  @override
  Widget build(BuildContext context) {
    return Column(
      // 確保 Column 撐滿外層 SizedBox 的高度
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        
        // 🎯 修正: 移除原先按鈕上方的 SizedBox(height: 20)
        // 🎯 核心修正 2: 使用 Spacer 將「註冊」按鈕推到最下方
        const Spacer(), 
        
        ElevatedButton(
          onPressed: () async {
            // 註冊邏輯...
            try {
              bool isSuccess = await registerUser(
                nameController.text,
                phoneController.text,
                emailController.text,
                passwordController.text,
              );

              if (isSuccess && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
                );
                await Future.delayed(const Duration(seconds: 2));
                DefaultTabController.of(context)?.animateTo(1);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('註冊失敗，請重試。'), backgroundColor: Colors.red),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentOrange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('註冊'),
        ),
        // 🎯 核心修正 3: 將按鈕下方的間距縮小
        const SizedBox(height: 5),
      ],
    );
  }
}

// --- 登入表單 (已修正) ---
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

  @override
  Widget build(BuildContext context) {
    return Column(
      // 確保 Column 撐滿外層 SizedBox 的高度
      children: [
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        
        // 🎯 修正: 移除原先按鈕上方的 SizedBox(height: 20)
        // 🎯 核心修正 2: 使用 Spacer 將「登入」按鈕推到最下方
        const Spacer(), 
        
        ElevatedButton(
          onPressed: () async {
            // 登入邏輯...
            final user = await loginUser(
              emailController.text,
              passwordController.text,
            );

            if (user != null && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanningPicturePage(),
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('登入失敗'), backgroundColor: Colors.red),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentOrange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('登入'),
        ),
        // 🎯 核心修正 3: 將按鈕下方的間距縮小
        const SizedBox(height: 5),
      ],
    );
  }
}