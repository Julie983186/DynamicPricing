import 'package:flutter/material.dart';
import '../services/api_service.dart'; // 確保路徑正確
import '../services/route_logger.dart'; // 確保路徑正確

// 定義顏色常量
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9);
const Color _kCardBg = Color(0xFFF1F8E9);
const Color _kAccentOrange = Color(0xFFFFB300);

class MemberProfilePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String token;

  const MemberProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.token,
  });

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserData();
    saveCurrentRoute('/member_area');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 資料載入邏輯 ---
  Future<void> _loadUserData() async {
    // 假設 fetchUserData 會返回 { 'name', 'phone', 'email' }
    final userData = await fetchUserData(widget.userId, widget.token);
    if (userData != null && mounted) {
      setState(() {
        _nameController.text = userData['name'] ?? widget.userName;
        _phoneController.text = userData['phone'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入會員資料失敗'), backgroundColor: Colors.red),
      );
    }
  }

  // --- 資料儲存邏輯 ---
  Future<void> _saveChanges() async {
    bool success = await updateUserData(
      userId: widget.userId,
      token: widget.token,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      // 只有當密碼欄位不為空時才傳送密碼更新
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料已成功修改！'), backgroundColor: _kPrimaryGreen),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightGreenBg, // 淺綠色背景
      appBar: AppBar(
        // 移除 AppBar 預設高度和陰影，保持背景色一致
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimaryGreen))
          : SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          // 1. LOGO 區塊
                          _buildLogo(), 
                          const SizedBox(height: 30),
                          
                          // 2. 表單與操作卡片
                          _buildProfileCard(context),

                          const SizedBox(height: 40),
                          // 3. 登出按鈕
                          _buildLogoutButton(context),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // LOGO 區塊 Helper (修改為顯示圖片)
// lib/pages/member_profile_page.dart

Widget _buildLogo() {
  return SizedBox(
    height: 150, 
    width: double.infinity, // 確保父層容器佔滿可用寬度
    child: Center(
      child: Image.asset(
        'assets/logo.png', // 使用你更新的路徑
        
        // 💡 關鍵調整：讓圖片寬度填滿父層容器
        width: double.infinity, 
        
        // 💡 確保圖片寬度被拉伸，但不裁切高度
        fit: BoxFit.fitWidth, 
      ),
    ),
  );
}
  // 個人資料卡片 Helper
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: _kCardBg, // 淺綠色卡片背景
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
          // 歷史記錄 & 掃描 按鈕行
          _buildActionButtons(context),
          const SizedBox(height: 10),

          // 頭像
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFDCEDC8),
            child: Icon(Icons.person, size: 50, color: _kPrimaryGreen),
          ),
          const SizedBox(height: 30),

          // 表單欄位
          _buildTextFieldRow('姓名', _nameController, hintText: '王小花'),
          const SizedBox(height: 15),
          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
          const SizedBox(height: 15),
          _buildTextFieldRow('帳號', _emailController, hintText: '請輸入電郵'),
          const SizedBox(height: 15),
          _buildTextFieldRow('密碼', _passwordController, hintText: '請輸入密碼', obscureText: true),
          const SizedBox(height: 30),

          // 修改按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _kAccentOrange, // 橘黃色
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

  // 頂部操作按鈕 (歷史記錄 & 掃描) Helper
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 歷史記錄按鈕 (左側)
        _buildIconTextButton(
          context,
          '歷史記錄',
          Icons.description, // 使用文件圖標
          () => Navigator.pushNamed(context, '/member_history'),
        ),
        
        // 掃描按鈕 (右側)
        _buildIconTextButton(
          context,
          '掃描',
          Icons.fullscreen, // 使用全屏或類似圖標
          () => Navigator.pushNamed(context, '/scan'),
        ),
      ],
    );
  }

  // 通用圖標+文字按鈕 Helper
  Widget _buildIconTextButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _kPrimaryGreen,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: _kPrimaryGreen),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 16, color: _kPrimaryGreen)),
        ],
      ),
    );
  }


  // 文字輸入欄位 Helper
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
              // 刪除 border 讓它更像設計圖中的純文本框
              border: InputBorder.none, 
              // 使用 Container/卡片本身的顏色，讓文本框看起來更像設計圖
              filled: true,
              fillColor: Colors.white, 
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            ),
          ),
        ),
      ],
    );
  }
  
  // 登出按鈕 Helper
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // 登出邏輯 (回到登入頁)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // 假設你 main.dart 中有 /login 路由
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red[700], // 使用紅色作為登出強調色
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
        ),
        child: const Text('登出', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}