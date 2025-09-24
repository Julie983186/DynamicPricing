import 'package:flutter/material.dart';
import 'member_edit_page.dart';
import 'member_history_page.dart';
import 'scanning_picture_page.dart';
import 'register_login_page.dart';
import '../services/route_logger.dart';


class MemberAreaPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String token;

  const MemberAreaPage({
    Key? key,
    required this.userId,
    required this.userName,
    required this.token,
  }) : super(key: key);

  @override
  State<MemberAreaPage> createState() => _MemberAreaPageState();
}

class _MemberAreaPageState extends State<MemberAreaPage> {
  late String userName;

  @override
  void initState() {
    super.initState();
    userName = widget.userName; // 初始化 State 變數
    saveCurrentRoute('/member_area'); // 記錄當前頁面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0, bottom: 50.0),
                      child: Text(
                        'LOGO',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ),
                    Container(
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
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFDCEDC8),
                            child: Icon(Icons.person, size: 50, color: Color(0xFF689F38)),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            '會員專區',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$userName 您好!', // 使用 State 變數
                            style: const TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                          const SizedBox(height: 30),

                          _buildMenuItem(context, '編輯個人資料', Icons.edit),
                          _buildMenuItem(context, '瀏覽歷史記錄', Icons.history),
                          _buildMenuItem(context, '開始商品掃描', Icons.qr_code_scanner),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterLoginPage()),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFFFFB300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 5,
                              ),
                              child: const Text('登出', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (title == '編輯個人資料') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberEditPage(
                    userId: widget.userId,
                    token: widget.token,
                  ),
                ),
              );
              if (result != null && result is String) {
                setState(() {
                  userName = result; // 更新名字
                });
              }
            } else if (title == '瀏覽歷史記錄') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemberHistoryPage(userId: widget.userId, token: widget.token)),
              );
            } else if (title == '開始商品掃描') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanningPicturePage()),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.green.withOpacity(0.3),
          highlightColor: Colors.green.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        ),
      ),
    );
  }
}
