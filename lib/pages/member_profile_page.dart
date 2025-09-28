import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
import 'scanning_picture_page.dart';
import 'member_history_page.dart';


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
  // 使用 String 而非 TextEditingController
  String _name = '';
  String _phone = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _name = widget.userName; // 預設名稱
    _loadUserData();
    saveCurrentRoute('/member_profile'); 
  }

  // --- 載入會員資料 ---
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
                          // 1. LOGO
                          _buildLogo(),
                          const SizedBox(height: 20),

                          // 2. 個人資料卡片
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

  // LOGO 區塊
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

  // 個人資料卡片
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
          // 頂部操作
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

          // 資料顯示
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  _buildDataRow('姓名', _name),
                  const SizedBox(height: 15),
                  _buildDataRow('電話', _phone),
                  const SizedBox(height: 15),
                  _buildDataRow('Email', _email),
                  const SizedBox(height: 15),
                  _buildDataRow('密碼', '********'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 修改按鈕 → 進入 /member_edit
          // 修改按鈕 → 進入 /member_edit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final bool? needsReload = await Navigator.pushNamed(
                  context,
                  '/member_edit',
                  arguments: {
                    'userId': widget.userId,
                    'userName': _name,
                    'phone': _phone,
                    'email': _email,
                    'token': widget.token,
                  },
                ) as bool?;

                if (needsReload == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('資料已成功修改！'), backgroundColor: Colors.green),
                  );
                  _loadUserData(); // ✅ 重新讀會員資料
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

          // 登出
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // 頂部操作按鈕
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconTextButton(
          context,
          '歷史記錄',
          Icons.description,
          () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberHistoryPage(
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                ),
        ),
        _buildIconTextButton(
          context,
          '掃描',
          Icons.fullscreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanningPicturePage(
                userId: widget.userId,
                userName: widget.userName,
                token: widget.token,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Icon + 文字按鈕
  Widget _buildIconTextButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _kPrimaryGreen,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kPrimaryGreen),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 16, color: _kPrimaryGreen)),
        ],
      ),
    );
  }

  // 資料顯示列
  Widget _buildDataRow(String label, String value) {
    final displayValue = value.isEmpty ? '未填寫' : value;
    final displayColor = value.isEmpty ? Colors.grey[600] : Colors.black;

    return Row(
      children: [
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
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              color: displayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // 登出按鈕
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
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
