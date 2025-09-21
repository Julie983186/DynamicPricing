import 'package:flutter/material.dart';

class MemberEditPage extends StatefulWidget {
  const MemberEditPage({Key? key}) : super(key: key);

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  // 為了演示，我們使用 TextEditingController 來控制 TextField 的內容
  // 在實際應用中，這些值可能從用戶資料庫中獲取
  final TextEditingController _nameController = TextEditingController(text: '王小花');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 淺綠色背景
      appBar: AppBar(
        // 因為設計圖沒有顯示 AppBar，所以可以將它設定為透明或不顯示標題
        backgroundColor: Colors.transparent,
        elevation: 0, // 移除 AppBar 的陰影
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)), // 返回箭頭顏色
        title: const Text(
          '', // 不顯示 AppBar 標題
          style: TextStyle(color: Color(0xFF388E3C)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 讓內容可以滾動
          child: Center( // 讓整個內容區塊居中
            child: ConstrainedBox( // 限制卡片的總寬度
              constraints: const BoxConstraints(maxWidth: 400), // 設定最大寬度為 400 像素
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // 頂部 LOGO 區域 (根據你的設計圖，MemberEditPage 也有 LOGO)
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
                    
                    // 編輯個人資料卡片
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
                          const Text(
                            '編輯個人資料',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // 姓名輸入框
                          _buildTextFieldRow('姓名', _nameController, readOnly: true), // 姓名設定為只讀
                          const SizedBox(height: 15),
                          
                          // 電話輸入框
                          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
                          const SizedBox(height: 15),
                          
                          // 帳號輸入框
                          _buildTextFieldRow('帳號', _accountController, hintText: '請輸入電郵'),
                          const SizedBox(height: 15),
                          
                          // 密碼輸入框
                          _buildTextFieldRow('密碼', _passwordController, hintText: '請輸入密碼', obscureText: true),
                          const SizedBox(height: 30),
                          
                          // 修改按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // 步驟 1: 假設資料已成功修改
                                // 在實際應用中，這裡會是呼叫後端 API，並在成功回調中執行以下代碼
                                
                                // 步驟 2: 顯示成功提示訊息
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('資料已成功修改！'),
                                    backgroundColor: Colors.green, // 綠色背景表示成功
                                    duration: const Duration(seconds: 2), // 顯示 2 秒
                                  ),
                                );

                                // 步驟 3: 延遲一段時間後返回上一頁
                                // 我們使用 Future.delayed 來等待 SnackBar 顯示完畢
                                Future.delayed(const Duration(seconds: 2), () {
                                  Navigator.pop(context);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, 
                                backgroundColor: const Color(0xFFFFB300), // 橘色按鈕背景
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                '修改',
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

  // 輔助方法：創建帶有標籤的輸入框行
  Widget _buildTextFieldRow(String label, TextEditingController controller, {String hintText = '', bool obscureText = false, bool readOnly = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中對齊
      children: [
        SizedBox(
          width: 60, // 標籤的固定寬度
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly, // 設定是否只讀
            obscureText: obscureText, // 是否隱藏文字 (用於密碼)
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none, // 無邊框
              ),
              filled: true,
              fillColor: Colors.white, // 輸入框背景白色
            ),
            style: TextStyle(
              color: readOnly ? Colors.grey[700] : Colors.black87, // 只讀文字顏色較淺
            ),
          ),
        ),
      ],
    );
  }
}