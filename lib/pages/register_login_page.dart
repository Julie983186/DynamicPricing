import 'package:flutter/material.dart';
import 'member_area_page.dart';
import 'scanning_picture_page.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

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
                      color: Colors.white.withOpacity(0.8),
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
                            children: const [
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

// --- 註冊表單 ---
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
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              bool isSuccess = await registerUser(
                nameController.text,
                phoneController.text,
                emailController.text,
                passwordController.text,
              );

              if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
                );
                await Future.delayed(const Duration(seconds: 2));
                DefaultTabController.of(context)?.animateTo(1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('註冊失敗，請重試。'), backgroundColor: Colors.red),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.red),
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

// --- 登入表單 ---
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

            if (user != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberAreaPage(
                    userId: user['id'],
                    userName: user['name'],
                    token: user['token'],
                  ),
                ),
              );
            } else {
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

// 輔助函式
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
