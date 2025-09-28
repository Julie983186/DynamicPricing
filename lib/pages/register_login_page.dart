import 'package:flutter/material.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import 'countingresult.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

// 💡 新增: 定義會員頁面的淺綠色背景
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

  // 💡 Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox( // 將 Container 改為 SizedBox，更簡潔
      height: 150, // 🎯 調整處: 增加 Logo 容器的高度，給圖片更多顯示空間
      width: 300, // 保持寬度為 300，與下方卡片對齊
      child: Image.asset(
        'assets/logo.png', // 確保這是你的 Logo 圖片正確路徑
        width: 300, // 保持圖片寬度為 300
        // height: 100, // 移除固定的 height，讓 BoxFit 決定高度
        fit: BoxFit.contain, // 🎯 調整處: 使用 BoxFit.contain 確保圖片完整顯示不裁切
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
                          indicatorColor: Colors.green,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          height: 400,
                          child: TabBarView(
                            children: [
                              RegisterForm(),
                              LoginForm(),
                            ],
                          ),
                        ),
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

// --- 註冊表單 (保持不變) ---
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
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              // 假設 registerUser 是一個非同步 API 呼叫
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
                // 成功後跳轉到登入分頁
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

// --- 登入表單 (保持不變) ---
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
      children: [
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            final user = await loginUser(
              emailController.text,
              passwordController.text,
            );

            if (user != null && mounted) {
              // 成功登入 → 跳到 ScanningPicturePage 並帶參數
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