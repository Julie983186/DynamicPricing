import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

// 定義顏色常量 (需確保與 MemberProfilePage 顏色一致)
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9);
const Color _kCardBg = Color(0xFFF1F8E9);
const Color _kAccentOrange = Color(0xFFFFB300); 
// 移除 _kCircleBg，因為不再需要圓形背景

class MemberEditPage extends StatefulWidget {
  // 接收從 Profile Page 傳來的資料
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
  late TextEditingController _passwordController; // 用於修改密碼

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(); // 密碼欄位預設為空
    saveCurrentRoute('/member_edit');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 資料儲存邏輯 (保持不變) ---
  Future<void> _saveChanges() async {
    // 檢查是否有實質變更
    if (_nameController.text == widget.userName &&
        _phoneController.text == widget.phone &&
        _emailController.text == widget.email &&
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有偵測到任何變更'), backgroundColor: Colors.blue),
      );
      Navigator.pop(context);
      return;
    }

    // 執行 API 更新
    bool success = await updateUserData(
      userId: widget.userId,
      token: widget.token,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料已成功修改！'), backgroundColor: _kPrimaryGreen),
      );
      Navigator.pop(context, true); 
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.red),
      );
    }
  }

  // LOGO 區塊 Helper (保持不變)
  Widget _buildLogo() {
    return SizedBox(
      height: 200, 
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/logo.png', // 確保您的專案 assets/logo.png 存在
          width: double.infinity, 
          fit: BoxFit.fitWidth, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightGreenBg,
      
      // 🎯 保持 extendBodyBehindAppBar: true
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60, 
        
        // 🎯 修正：使用 IconButton 替換預設的 leading widget，只顯示深綠色箭頭
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kPrimaryGreen, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        
        // 確保不顯示預設返回按鈕 (雖然 leading 設置後會覆蓋預設行為)
        automaticallyImplyLeading: false, 
        
        // 移除 iconTheme，因為我們在 leading 中已經指定了顏色
        // iconTheme: const IconThemeData(color: _kPrimaryGreen),
      ),
      
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // 💡 新增間距：確保內容避開狀態欄和 App Bar
                  SizedBox(height: MediaQuery.of(context).padding.top + 10), 

                  _buildLogo(), 
                  const SizedBox(height: 20),
                  
                  _buildEditCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 編輯表單卡片 Helper (保持不變)
  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: BoxDecoration(
        color: _kCardBg,
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
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFDCEDC8),
            child: Icon(Icons.person, size: 50, color: _kPrimaryGreen),
          ),
          const SizedBox(height: 30),

          // 可編輯的表單欄位
          _buildTextFieldRow('姓名', _nameController, hintText: '請輸入姓名'),
          const SizedBox(height: 15),
          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
          const SizedBox(height: 15),
          _buildTextFieldRow('帳號', _emailController, hintText: '請輸入電郵'),
          const SizedBox(height: 15),
          _buildTextFieldRow('密碼', _passwordController, hintText: '留空則不修改密碼', obscureText: true),
          const SizedBox(height: 30),

          // 儲存按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveChanges, // 呼叫儲存邏輯
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _kPrimaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('儲存變更', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 文字輸入欄位 Helper (保持不變)
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
              border: InputBorder.none, 
              filled: true,
              fillColor: Colors.white, 
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            ),
          ),
        ),
      ],
    );
  }
}