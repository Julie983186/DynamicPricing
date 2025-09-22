
import 'package:flutter/material.dart';
import 'member_edit_page.dart'; // 引入 member_edit_page.dart 檔案
import 'member_history_page.dart'; // 引入掃描歷史記錄頁面
import 'scanning_picture_page.dart'; // 引入影像辨識頁面
import 'register_login_page.dart';

class MemberAreaPage extends StatelessWidget {
  final int userId;
  final String userName;

  const MemberAreaPage({
    Key? key,
    required this.userId,
    required this.userName,   
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: SingleChildScrollView( // 讓內容可以滾動
          child: Center( // 讓整個內容區塊居中
            child: ConstrainedBox( // 限制卡片的總寬度
              constraints: const BoxConstraints(maxWidth: 400), // 設定最大寬度為 400 像素
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // 添加左右內邊距
                child: Column(
                  children: [
                    // 頂部 LOGO 區域
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0, bottom: 50.0),
                      child: Text(
                        'LOGO',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C), // 深綠色 LOGO
                        ),
                      ),
                    ),
                    
                    // 會員專區卡片
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9), // 淺米綠色卡片背景
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
                          // 會員頭像
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFDCEDC8),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF689F38),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // 會員專區標題
                          const Text(
                            '會員專區',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          
                          // 歡迎訊息
                          Text(
                            '$userName您好!',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // 功能按鈕列表
                          _buildMenuItem(context, '編輯個人資料', Icons.edit),
                          _buildMenuItem(context, '瀏覽歷史記錄', Icons.history),
                          _buildMenuItem(context, '開始商品掃描', Icons.qr_code_scanner),
                          const SizedBox(height: 30),
                          
                          // 登出按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // 導航回登入頁，並清空頁面堆疊
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterLoginPage()),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, 
                                backgroundColor: const Color(0xFFFFB300), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                '登出',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
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
          onTap: () {
            if (title == '編輯個人資料') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberEditPage(userId: userId),
                ),
              );
            } else if (title == '瀏覽歷史記錄') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MemberHistoryPage()),
              );
            } else if (title == '開始商品掃描') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanningPicturePage()),
              );
            } else {
              print('$title 被點擊');
            }
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.green.withOpacity(0.3),
          highlightColor: Colors.green.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                decorationColor: Colors.black54,
                decorationThickness: 1.0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}