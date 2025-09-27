import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

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
  // 將 TextEditingController 轉為 String，因為這個頁面只用於顯示
  String _name = '';
  String _phone = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初始化時使用傳入的 userName 作為預設值
    _name = widget.userName;
    _loadUserData();
    saveCurrentRoute('/member_area');
  }

  // --- 資料載入邏輯 (保持不變) ---
  Future<void> _loadUserData() async {
    final userData = await fetchUserData(widget.userId, widget.token);
    if (userData != null && mounted) {
      setState(() {
        _name = userData['name'] ?? widget.userName;
        _phone = userData['phone'] ?? '';
        _email = userData['email'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入會員資料失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
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
                          const SizedBox(height: 10),
                          // 1. LOGO 區塊
                          _buildLogo(),
                          const SizedBox(height: 20),
                          
                          // 2. 表單與操作卡片
                          _buildProfileCard(context),

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

  // LOGO 區塊 Helper (保持不變)
  Widget _buildLogo() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  // 個人資料卡片 Helper (已調整資料區塊實現置中)
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          // 歷史記錄 & 掃描 按鈕行
          _buildActionButtons(context),
          const SizedBox(height: 10),

          // 頭像
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFDCEDC8),
              child: Icon(Icons.person, size: 50, color: _kPrimaryGreen),
            ),
          ),
          const SizedBox(height: 30),

          // 🎯 核心修正：將資料欄位 ConstrainedBox 限寬後置中
          Center(
            child: ConstrainedBox(
              // 限制資料區塊的最大寬度，使其不會填滿卡片，從而實現整體置中
              constraints: const BoxConstraints(maxWidth: 280), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDataRow('姓名', _name),
                  const SizedBox(height: 15), // 行間距
                  _buildDataRow('電話', _phone),
                  const SizedBox(height: 15), // 行間距
                  _buildDataRow('帳號', _email),
                  const SizedBox(height: 15), // 行間距
                  _buildDataRow('密碼', '********'), // 密碼僅顯示星號
                ],
              ),
            ),
          ),
          const SizedBox(height: 30), // 資料區塊與按鈕間距

          // 修改按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async { 
                final bool? needsReload = await Navigator.pushNamed(context, '/member_edit', arguments: {
                  'userId': widget.userId,
                  'userName': _name,
                  'phone': _phone,
                  'email': _email,
                  'token': widget.token,
                }) as bool?;
              
                if (needsReload == true) {
                  _loadUserData();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _kAccentOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('修改', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 15),

          // 登出按鈕
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // 頂部操作按鈕 (保持不變)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconTextButton(
          context,
          '歷史記錄',
          Icons.description,
          () => Navigator.pushNamed(context, '/member_history'),
        ),
        
        _buildIconTextButton(
          context,
          '掃描',
          Icons.fullscreen,
          () => Navigator.pushNamed(context, '/scan'),
        ),
      ],
    );
  }

  // 通用圖標+文字按鈕 Helper (保持不變)
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

  // 資料顯示列 Helper (標籤和數值在同一行，無邊框，僅文字)
  Widget _buildDataRow(String label, String value) {
    final displayValue = value.isEmpty ? '未填寫' : value;
    final displayColor = value.isEmpty ? Colors.grey[600] : Colors.black;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. 左側標籤 (固定寬度，靠左)
        SizedBox(
          width: 60, 
          child: Text(
            label, 
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 20), // 標籤與值之間的間距
        
        // 2. 右側數值 (使用 Expanded 讓它佔據剩餘空間，靠左對齊)
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 16, 
              color: displayColor,
              fontWeight: FontWeight.bold, // 讓數值更突出
            ),
          ),
        ),
      ],
    );
  }
  
  // 登出按鈕 Helper (保持不變)
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // 登出邏輯 (回到登入頁)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
        ),
        child: const Text('登出', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}