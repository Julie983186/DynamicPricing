import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'member_history_page.dart';

// 淺綠色背景
const Color _kLightGreenBg = Color(0xFFE8F5E9);

class GuestLoginPage extends StatelessWidget {
  final int productId; // 要綁定的商品ID

  const GuestLoginPage({super.key, required this.productId});

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
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 150,
                    width: 300,
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
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
                          height: 500, // 可調整高度
                          child: TabBarView(
                            children: [
                              GuestRegisterForm(productId: productId),
                              GuestLoginForm(productId: productId),
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

// ---------------- 註冊表單 ----------------
class GuestRegisterForm extends StatefulWidget {
  final int productId;

  const GuestRegisterForm({super.key, required this.productId});

  @override
  _GuestRegisterFormState createState() => _GuestRegisterFormState();
}

class _GuestRegisterFormState extends State<GuestRegisterForm> {
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
        // 註冊成功 → 顯示訊息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('註冊成功！正在自動登入…'),
            backgroundColor: Colors.green,
          ),
        );

        // 自動登入
        final user = await loginUser(
          emailController.text,
          passwordController.text,
        );

        if (user != null && mounted) {
          // 儲存剛掃描的商品紀錄
          final saveSuccess = await saveGuestHistory(widget.productId, user['token']);

          // 跳轉歷史頁
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MemberHistoryPage(
                  userId: user['id'],
                  userName: user['name'],
                  token: user['token'],
                ),
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('自動登入失敗'), backgroundColor: Colors.red),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('註冊失敗，請重試。'),
            backgroundColor: Colors.red,
          ),
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
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('姓名', controller: nameController),
            buildTextField('電話', controller: phoneController),
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
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
              child: const Text('註冊', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- 登入表單 ----------------
class GuestLoginForm extends StatefulWidget {
  final int productId;

  const GuestLoginForm({super.key, required this.productId});

  @override
  State<GuestLoginForm> createState() => _GuestLoginFormState();
}

class _GuestLoginFormState extends State<GuestLoginForm> {
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
      // 儲存剛掃描的商品紀錄
      final saveSuccess = await saveGuestHistory(widget.productId, user['token']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemberHistoryPage(
              userId: user['id'],
              userName: user['name'],
              token: user['token'],
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('登入失敗'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
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
              child: const Text('登入', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
