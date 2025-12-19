import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
import 'scanning_picture_page.dart';

class RegisterLoginPage extends StatefulWidget {
  final String? returnAction; 
  final Map<String, dynamic>? returnArgs; 
  final String? returnRoute; 
  const RegisterLoginPage({
    super.key,
    this.returnAction,
    this.returnArgs,
    this.returnRoute,
  });

  @override
  State<RegisterLoginPage> createState() => _RegisterLoginPageState();
}

class _RegisterLoginPageState extends State<RegisterLoginPage> {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/login');
  }

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

  // 處理 returnAction
  Future<void> _handleReturnAction(BuildContext context, Map<String, dynamic> user) async {
    if (widget.returnAction == null) return;

    switch (widget.returnAction) {
      case "saveRecord":
        final productId = widget.returnArgs?["productId"];
        if (productId != null) {
          print("saveScanRecord -> userId=${user['id']}, productId=$productId");
          await saveScanRecord(
            userId: user["id"],
            token: user["token"],
            productId: productId is int ? productId : int.parse(productId.toString()),
          );
        }
        break;
    }
  }


  // 登入成功 → 執行 returnAction 並跳轉頁面
  Future<void> _finishLogin(BuildContext context, Map<String, dynamic> user) async {
    if (widget.returnAction == "saveRecord" && widget.returnArgs != null) {
      final productId = widget.returnArgs!['productId'];
      if (productId != null) {
        await saveScanRecord(
          userId: user['id'],
          token: user['token'],
          productId: int.parse(productId.toString()),
        );
      }
    }

    if (!mounted) return;

    if (widget.returnRoute != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.returnRoute!,
        (route) => false,
        arguments: {
          'userId': user['id'],
          'userName': user['name'],
          'token': user['token'],
          'showSavedPopup': true,
        },
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanningPicturePage(
            userId: user['id'],
            userName: user['name'],
            token: user['token'],
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        _tabController = DefaultTabController.of(context)!; // 取得 TabController

        return Scaffold(
          backgroundColor: const Color(0xFFE8F5E9),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
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
                            height: 450,
                            child: TabBarView(
                              children: [
                                RegisterForm(
                                  onFinish: _finishLogin,
                                  returnAction: widget.returnAction,
                                  returnArgs: widget.returnArgs,
                                  returnRoute: widget.returnRoute,
                                  tabController: _tabController,
                                ),
                                LoginForm(
                                  onFinish: _finishLogin,
                                  returnAction: widget.returnAction,
                                  returnArgs: widget.returnArgs,
                                  returnRoute: widget.returnRoute,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// 共用輸入欄位
Widget buildTextField(String label,
    {bool obscureText = false, TextEditingController? controller}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
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

// 註冊表單
class RegisterForm extends StatefulWidget {
  final Future<void> Function(BuildContext, Map<String, dynamic>) onFinish;
  final String? returnAction;
  final Map<String, dynamic>? returnArgs;
  final String? returnRoute;
  final TabController? tabController;

  const RegisterForm({
    super.key,
    required this.onFinish,
    this.returnAction,
    this.returnArgs,
    this.returnRoute,
    this.tabController,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
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

  Future<void> submitRegister() async {
    final success = await registerUser(
      nameController.text,
      phoneController.text,
      emailController.text,
      passwordController.text,
    );

    if (!success || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('註冊失敗'), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('註冊成功，請登入'), backgroundColor: Colors.green),
    );

    // 切換到登入
    widget.tabController?.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            buildTextField('姓名', controller: nameController),
            buildTextField('電話', controller: phoneController),
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        Column(
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
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanningPicturePage()),
                );
              },
              child: const Text("以訪客身份使用"),
            )
          ],
        )
      ],
    );
  }
}

// 登入表單
class LoginForm extends StatefulWidget {
  final Future<void> Function(BuildContext, Map<String, dynamic>) onFinish;
  final String? returnAction;
  final Map<String, dynamic>? returnArgs;
  final String? returnRoute;

  const LoginForm({
    super.key,
    required this.onFinish,
    this.returnAction,
    this.returnArgs,
    this.returnRoute,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> submitLogin() async {
    final user = await loginUser(emailController.text, passwordController.text);

    if (user == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登入失敗'), backgroundColor: Colors.red),
      );
      return;
    }

    await widget.onFinish(context, user);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        Column(
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
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanningPicturePage()),
                );
              },
              child: const Text("以訪客身份使用"),
            )
          ],
        )
      ],
    );
  }
}
