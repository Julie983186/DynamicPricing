import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
import 'member_profile_page.dart';

class MemberEditPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phone;
  final String email;
  final String token;

  const MemberEditPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.email,
    required this.token,
  });

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/member_edit');

    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final success = await updateUserData(
      userId: widget.userId,
      token: widget.token,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料修改成功！'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.red),
      );
    }
  }

  // LOGO
  Widget _buildLogo() {
    return const SizedBox(
      height: 160, 
      width: double.infinity,
      child: Center(
        child: Image(
          image: AssetImage('assets/logo.png'), 
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // 替換為圖片 Logo
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0), 
                            child: _buildLogo(), // 使用新的 Logo Widget
                          ),
                          _buildFormCard(),
                          const SizedBox(height: 20), 
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('編輯個人資料', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextFieldRow('姓名', _nameController, hintText: '請輸入姓名'),
          const SizedBox(height: 15),
          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
          const SizedBox(height: 15),
          _buildTextFieldRow('帳號', _emailController, hintText: '請輸入Email'),
          const SizedBox(height: 15),
          _buildTextFieldRow('密碼', _passwordController, hintText: '請輸入新密碼', obscureText: true),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFFFB300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('修改', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(String label, TextEditingController controller,
      {String hintText = '', bool obscureText = false}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}