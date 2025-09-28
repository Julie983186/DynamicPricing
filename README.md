//app.py
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from db_config import db_config

app = Flask(__name__)

# 修正：明確地將 CORS 套用到整個應用程式
CORS(app, supports_credentials=True)

# 使用從 db_config.py 匯入的資料庫設定
app.config['MYSQL_HOST'] = db_config['host']
app.config['MYSQL_USER'] = db_config['user']
app.config['MYSQL_PASSWORD'] = db_config['password']
app.config['MYSQL_DB'] = db_config['database']

mysql = MySQL(app)

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')

    try:
        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users (name, phone, email, password) VALUES (%s, %s, %s, %s)",
                    (name, phone, email, password))
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '註冊成功'}), 200
    except Exception as e:
        import traceback
        print(traceback.format_exc())  # 印出完整錯誤訊息
        return jsonify({'message': '註冊失敗', 'error': str(e)}), 500


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']

    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE email=%s AND password=%s", (email, password))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3]
            }
            return jsonify({'message': '登入成功', 'user': user_data}), 200
        else:
            return jsonify({'message': '帳號或密碼錯誤'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
# 抓取會員資料
@app.route('/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3],
            }
            return jsonify(user_data), 200
        else:
            return jsonify({'message': '找不到該會員'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
# 更新會員資料
@app.route('/user/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.get_json()
    
    # 只取出前端傳過來的欄位
    fields = {}
    for key in ['name', 'email', 'phone', 'password']:
        if key in data:
            fields[key] = data[key]

    if not fields:
        return jsonify({'message': '沒有可更新的欄位'}), 400

    # 動態生成 SQL
    set_clause = ", ".join([f"{key}=%s" for key in fields.keys()])
    values = list(fields.values())
    values.append(user_id)  # id 放最後

    try:
        cur = mysql.connection.cursor()
        sql = f"UPDATE users SET {set_clause} WHERE id=%s"
        cur.execute(sql, values)
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '更新成功'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

#抓歷史資料
import traceback

@app.route('/get_products/<int:user_id>', methods=['GET'])
def get_products(user_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.productid, p.producttype, p.proname, p.proprice,   
            h.created_at, p.expiredate, p.status, p.market
            FROM history h
            JOIN product p ON h.productid = p.productid
            WHERE h.userid = %s
            ORDER BY h.created_at DESC
        """, (user_id,))
        products = cur.fetchall()
        cur.close()

        product_list = []
        for p in products:
            product_list.append({
                'ProductID': p[0],
                'ProductType': p[1],
                'ProName': p[2],
                'ProPrice': p[3],
                'ScanDate': p[4].strftime('%Y-%m-%d') if p[4] else None,
                'ExpireDate': p[5].strftime('%Y-%m-%d') if p[5] else None,
                'Status': p[6],
                'Market': p[7],
            })
        return jsonify({'products': product_list}), 200

    except Exception as e:
        print(traceback.format_exc())  # 印出完整錯誤
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

//api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // 導入剛剛的檔案
import 'package:flutter/foundation.dart';

// 函式現在回傳 Future<bool>，用來表示成功或失敗
Future<bool> registerUser(String name, String phone, String email, String password) async {
  //final String ip = kIsWeb ? 'http://127.0.0.1:5000' : 'http://172.20.10.2:5000';
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('註冊成功');
      return true; // 註冊成功，回傳 true
    } else {
      print('註冊失敗: ${response.body}');
      return false; // 註冊失敗，回傳 false
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false; // 連線錯誤，回傳 false
  }
}

// 新增登入函式
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'id': data['user']['id'],
        'name': data['user']['name'],
      };
    } else {
      print('登入失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}





class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: '姓名')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: '電話')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: '密碼'), obscureText: true),
            ElevatedButton(
              onPressed: () {
                registerUser(
                  nameController.text,
                  phoneController.text,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: Text('註冊'),
            )
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> fetchUserData(int userId) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/user/$userId');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('取得會員資料失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

// 更新會員資料函式，允許更新電話和密碼
Future<bool> updateUserData({
  required int userId,
  String? name,
  String? email,
  String? phone,
  String? password,
}) async {
  final String ip = 'http://127.0.0.1:5000';
  final url = Uri.parse('$ip/user/$userId');

  // 只放入有值的欄位
  final Map<String, dynamic> body = {};
  if (name != null) body['name'] = name;
  if (email != null) body['email'] = email;
  if (phone != null) body['phone'] = phone;
  if (password != null) body['password'] = password;

  if (body.isEmpty) {
    print('沒有可更新的欄位');
    return false;
  }

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('更新失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

//main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import to pages
import 'pages/scanning_picture_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
import 'pages/register_login_page.dart';  // 引入登入註冊頁

import 'pages/home_page.dart';            // 引入首頁
import 'pages/counting.dart';
import 'pages/countingresult.dart';
import 'pages/adviceproduct.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '碳即',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),

      // localize
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
      ],

      // all routes
      routes: {
        // login group
        '/login': (context) => const RegisterLoginPage(),
        //'/member': (context) => const MemberAreaPage(userName: '測試使用者'),
        '/counting': (context) => const LoadingPage(), // 價格計算中頁面
        '/countingResult': (context) => const CountingResult(), // 計算結果頁面
        // recognition group
        '/loading': (context) => const RecognitionLoadingPage(),
        '/resultCheck': (context) => const RecognitionResultPage(),
        '/edit': (context) => const RecognitionEditPage(),
      },
      // 一開始進入登入/註冊頁
      home: const RegisterLoginPage(),
    );
  }
}

//home_page.dart

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首頁')),
      body: const Center(
        child: Text(
          '歡迎來到首頁！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

//register_login_page.dart

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'member_area_page.dart';
import 'member_edit_page.dart';
import '../services/api_service.dart'; 

// 註冊與登入頁面
class RegisterLoginPage extends StatelessWidget {
  const RegisterLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFD9EAD3),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    'LOGO',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF274E13),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 244, 242, 242).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
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
                          height: 400,
                          child: TabBarView(
                            children: [
                              // 註冊會員表單 - 使用修正後的 StatefulWidget
                              RegisterForm(),
                              // 會員登入表單
                              LoginForm(),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('以訪客身份使用'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 修正後的註冊表單，使用 StatefulWidget
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // 定義 TextEditingController 來獲取輸入框的內容
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 將 buildTextField 移到類別內部，確保正確使用控制器
  Widget buildTextField(String label, {bool obscureText = false, TextEditingController? controller}) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              bool isSuccess = await registerUser(
                nameController.text,
                phoneController.text,
                emailController.text,
                passwordController.text,
              );

              if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
                );
                await Future.delayed(const Duration(seconds: 2));

                // 返回登入頁 (切換 TabIndex)
                DefaultTabController.of(context).animateTo(1);
              }else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('註冊失敗，請重試。'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('發生錯誤: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('註冊'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            final user = await loginUser(
              emailController.text,
              passwordController.text,
            );

            if (user != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberAreaPage(
                    userId: user['id'],
                    userName: user['name'], // 從後端 API 拿到 userName
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('登入失敗'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('登入'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}


// 輔助函式，用於建立帶有控制器的 TextField，但現在它只在 LoginForm 內部被使用
Widget buildTextField(String label, {bool obscureText = false, TextEditingController? controller}) {
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
                MaterialPageRoute(builder: (context) => MemberHistoryPage(userId:userId)),
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


//member_edit_page.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart'; 

class MemberEditPage extends StatefulWidget {
  final int userId;

  const MemberEditPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _loadUserData(); // 初始化時去後端抓資料
  }

  Future<void> _loadUserData() async {
    final userData = await fetchUserData(widget.userId);
    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false; // 即使失敗也要結束 loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入會員資料失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)),
        title: const Text('', style: TextStyle(color: Color(0xFF388E3C))),
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
                          _buildFormCard(),
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
          const Text(
            '編輯個人資料',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          _buildTextFieldRow('姓名', _nameController, hintText: '請輸入姓名'),
          const SizedBox(height: 15),
          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
          const SizedBox(height: 15),
          _buildTextFieldRow('帳號', _emailController, hintText: '請輸入Email'),
          const SizedBox(height: 15),
          _buildTextFieldRow('密碼', _passwordController, hintText: '請輸入密碼', obscureText: true),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                bool success = await updateUserData(
                  userId: widget.userId,
                  name: _nameController.text.isNotEmpty ? _nameController.text : null,
                  phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                  email: _emailController.text.isNotEmpty ? _emailController.text : null,
                  password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('資料已成功修改！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('更新失敗'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
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
      {String hintText = '', bool obscureText = false, bool readOnly = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(color: readOnly ? Colors.grey[700] : Colors.black87),
          ),
        ),
      ],
    );
  }
}


//member_history_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MemberHistoryPage extends StatefulWidget {
  final int userId; // 登入後傳進來的會員 id
  const MemberHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MemberHistoryPage> createState() => _MemberHistoryPageState();
}

class _MemberHistoryPageState extends State<MemberHistoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/get_products/${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data['products'];
          isLoading = false;
        });
      } else {
        throw Exception("載入失敗");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)),
        title: const Text(
          '',
          style: TextStyle(color: Color(0xFF388E3C)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 搜尋欄
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildSearchBar(context),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                '掃描歷史記錄',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 歷史記錄列表
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? const Center(child: Text("目前沒有歷史紀錄"))
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: _buildHistoryCard(context, product),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              ).then((pickedDate) {
                if (pickedDate != null) {
                  print('選擇的日期: $pickedDate');
                }
              });
            },
            child: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: constraints.maxWidth * 0.18,
                    height: constraints.maxWidth * 0.25,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product['Market'] ?? '未知超市',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const Text(
                    '分店',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['ProName'] ?? '未知商品',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _buildInfoRow('掃描時間', product['ScanDate'] ?? ''),
                    _buildInfoRow('有效期限', product['ExpireDate'] ?? ''),
                    _buildInfoRow('狀態', product['Status'] ?? ''),
                    const SizedBox(height: 5),
                    _buildPriceRow('原價', '\$${product['ProPrice'] ?? 0}', isOriginal: true),
                    _buildPriceRow('建議價格', '\$55', isOriginal: false), // 假設
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('刪除按鈕已點擊'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isOriginal ? Colors.black54 : Colors.green[700],
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isOriginal ? Colors.black87 : Colors.red,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

//scannign_picture_page.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class ScanningPicturePage extends StatefulWidget {
  const ScanningPicturePage({Key? key}) : super(key: key);

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isCameraInitialized = false;
  // 將 _selectedStore 的初始值設為 null，使其沒有預設選項
  String? _selectedStore; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimation();
  }

  // 初始化相機
  // 此方法會取得可用的相機，並初始化 CameraController
  // 確保相機在頁面載入時已準備好進行預覽
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('沒有可用的相機');
        return;
      }

      // 找後鏡頭（back）
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      print('相機初始化錯誤: $e');
    }
  }

  // 初始化掃描框動畫
  // 負責創建一個 AnimationController，用於控制掃描線的上下移動
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 頁面主體 UI
  // 負責建構整個頁面的視覺佈局
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    const double maxContentWidth = 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'LOGO',
          style: TextStyle(
            color: Color(0xFF388E3C),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
        centerTitle: true,
        // 設置此屬性為 false，才能強制移除返回鍵
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _buildTopUI(),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 鏡頭即時預覽
                      CameraPreview(_cameraController!),
                      // 疊加UI (掃描框、文字)
                      _buildOverlay(),
                    ],
                  ),
                ),
                _buildBottomUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 頁面上方 UI
  // 包含會員/訪客頭像與賣場選擇下拉選單
  // 頁面上方 UI
Widget _buildTopUI() {
  return Container(
    color: const Color(0xFFE8F5E9),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column( // 將 Row 改為 Column，以便垂直排列
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 確保元素靠上對齊
          children: [
            // 左側的會員/訪客頭像和名稱
            GestureDetector(
              onTap: () {
                print('頭像被點擊');
              },
              child: Column(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 25),
                  ),
                  const Text('訪客', style: TextStyle(color: Color(0xFF388E3C), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // 右側的賣場選擇區
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreDropdown(),
                ],
              ),
            ),
          ],
        ),
        // 將 _buildCurrentStoreInfo() 從 Expanded 外部移出，並用 Center 包住
        const SizedBox(height: 10),
        _buildCurrentStoreInfo(),
      ],
    ),
  );
}
  
  // 賣場選擇下拉式選單
  Widget _buildStoreDropdown() {
    // 定義選項列表
    final List<String> stores = ['家樂福', '全聯', '愛買'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // 將 value 設為 _selectedStore
          value: _selectedStore,
          // 新增 hint 屬性作為提示文字
          hint: const Text('請選擇賣場', style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStore = newValue;
            });
          },
          items: stores.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 目前賣場資訊
  // 目前賣場資訊
Widget _buildCurrentStoreInfo() {
  return Text(
    _selectedStore != null ? '目前賣場：$_selectedStore' : '尚未選擇賣場',
    style: const TextStyle(
      color: Color.fromARGB(221, 239, 41, 41),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );
}
  
  // 疊加在相機預覽上的 UI
  // 包含掃描框、掃描線和提示文字
  Widget _buildOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
      ],
    );
  }

  // 掃描框遮罩
  // 創建一個帶有透明中心矩形的遮罩，用於突出顯示掃描區域
  Widget _buildScanMask() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        const Color(0xFFE8F5E9).withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 320,
                // 調整掃描框的高度，使其變長
                height: 900,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 掃描線動畫
  // 創建一條上下移動的掃描線，模擬掃描過程
  Widget _buildScanLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const double scanLineWidth = 320 * 0.8;
          // 根據動畫值計算掃描線的 Y 軸位移
          return Transform.translate(
            offset: Offset(0, -125 + _animationController.value * 250),
            child: Container(
              width: scanLineWidth,
              height: 3,
              color: Colors.greenAccent,
            ),
          );
        },
      ),
    );
  }

  // 引導文字
  // 提醒使用者如何對準商品資訊
  Widget _buildHintText() {
    return const Positioned(
      top: 20,
      child: Text(
        '請對準產品名稱、價格與有效期限',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // 頁面下方 UI (拍照按鈕)
  // 提供一個可點擊的圓形按鈕來觸發拍照功能
  Widget _buildBottomUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: GestureDetector(
          onTap: _takePicture,
          child: Container(
            // 調整按鈕的尺寸，使其變小
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.green,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  // 拍照功能
  // 呼叫相機控制器的 takePicture() 方法來拍照
  void _takePicture() async {
    if (!_isCameraInitialized) {
      print('相機尚未初始化');
      return;
    }
    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      
      if (!mounted) {
        return;
      }
      print('照片已儲存至: ${image.path}');
      
      await _uploadImage(image.path);
      
    } catch (e) {
      print('拍照失敗: $e');
    }
  }

  // 圖片上傳功能（假想）
  // 模擬將照片上傳到後端 API 並接收結果
  Future<void> _uploadImage(String imagePath) async {
    print('正在將照片上傳至假想後端API...');
    try {
      await Future.delayed(const Duration(seconds: 2));
      print('照片上傳成功！');

      // 上傳完成後 → 跳到辨識 Loading 頁
      if (!mounted) return;
      Navigator.pushNamed(context, '/loading');
    } catch (e) {
      print('照片上傳失敗: $e');
    }
  }
}

//recognition_loading_page.dart

// lib/pages/recognition_loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';

class RecognitionLoadingPage extends StatefulWidget {
  const RecognitionLoadingPage({super.key});

  @override
  State<RecognitionLoadingPage> createState() => _RecognitionLoadingPageState();
}

class _RecognitionLoadingPageState extends State<RecognitionLoadingPage> {
  @override
  void initState() {
    super.initState();

    // 3秒後結果確認
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/resultCheck');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F3DA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'LOGO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '辨識進行中...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '請稍待',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

//recognition_result_page.dart

import 'package:flutter/material.dart';

class RecognitionResultPage extends StatelessWidget {
  const RecognitionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F3DA), // 明るい緑背景
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            const Text(
              'LOGO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/sample.jpg', // temporary image
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              '商品名稱：瑞穗鮮乳・全脂290ml',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '有效期限：\n2025-05-25',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '產品名稱及有效期限是否正確？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/counting');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('正確'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('手動修改'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/scan');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描'),
            ),
          ],
        ),
      ),
    );
  }
}

//recognition_edit_page.dart

import 'package:flutter/material.dart';

class RecognitionEditPage extends StatefulWidget {
  const RecognitionEditPage({super.key});

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  final TextEditingController nameController =
      TextEditingController(text: '瑞穗鮮乳・全脂290ml');
  final TextEditingController dateController =
      TextEditingController(text: '2025-05-25');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F3DA),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // ←返回 Result Page
                  },
                  child: const Icon(Icons.arrow_back_ios),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LOGO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/sample.jpg',
              height: 200,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: '有效期限',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/counting');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('送出'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

//counting.dart

import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();

    // 模擬計算，2秒後跳轉到結果頁
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/countingResult');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9EAD3), // 淡綠背景
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'LOGO',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF274E13), // 深綠
                ),
              ),
              SizedBox(height: 30),
              Text(
                '價格計算中...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '請稍待',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//counting_result.dart

import 'package:flutter/material.dart';
import 'adviceproduct.dart'; // 記得引入

class CountingResult extends StatelessWidget {
  const CountingResult({super.key});

  @override
  Widget build(BuildContext context) {
    double originalPrice = 35;
    double discountPrice = 32;
    double saved = originalPrice - discountPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFD9EAD3),
      body: SafeArea(
        child: Stack(
          children: [
            /// 上層內容 (價格結果)
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 250), // 預留下方空間給 BottomSheet
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- 上方 LOGO 與 icons ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        // 左上角
                        Column(
                          children: [
                            Icon(Icons.person, size: 32, color: Colors.black87),
                            SizedBox(height: 4),
                            Text("訪客",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(
                          'LOGO',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF274E13),
                          ),
                        ),
                        Icon(Icons.fullscreen,
                            size: 30, color: Colors.black87),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 商品卡片 ---
                  Container(
                    width: 330,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 220,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Image.network(
                            "https://i.ibb.co/5TjRv8k/milk.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "商品名稱：瑞穗鮮乳-全脂290ml",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "有效期限：2025-05-25",
                          style: TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),

                        // --- 價格比對 ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildPriceBox("原價", "\$$originalPrice",
                                isDiscount: false),
                            buildPriceBox("即期優惠價", "\$$discountPrice",
                                isDiscount: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "‼ 目前價格落於合理範圍 ‼",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "比原價省下 \$$saved 元",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            /// 下方可拖曳的推薦商品區塊
            DraggableScrollableSheet(
              initialChildSize: 0.25, // 預設高度 (25%)
              minChildSize: 0.15,     // 最小高度
              maxChildSize: 0.85,     // 最大高度
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: AdviceProductList(scrollController: scrollController),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 抽出價格卡片
  Widget buildPriceBox(String title, String price, {bool isDiscount = false}) {
    return SizedBox(
      width: 130,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDiscount ? Colors.orange.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isDiscount ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(
                fontSize: isDiscount ? 26 : 24,
                fontWeight: FontWeight.bold,
                color: isDiscount ? Colors.deepOrange : Colors.black,
                decoration: isDiscount ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//adviceproduct.dart

import 'package:flutter/material.dart';

class AdviceProductList extends StatelessWidget {
  final ScrollController scrollController;
  const AdviceProductList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: Icon(Icons.drag_handle, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          "先別離開！根據掃描的商品，您也能考慮以下商品：",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        GridView.count(
          controller: scrollController, // 跟 DraggableScrollableSheet 同步
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            ProductCard(
              imageUrl: "https://i.imgur.com/7F3K5bO.png",
              price: 30,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "https://i.imgur.com/0rVeh4q.png",
              price: 28,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "https://i.imgur.com/TKXrY9K.png",
              price: 25,
              expiry: "效期剩5小時",
            ),
          ],
        ),
      ],
    );
  }
}

/// 沿用原本 ProductCard
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final double price;
  final String expiry;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.price,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFD9EAD3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              "\$$price",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              expiry,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}


//app.py
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from db_config import db_config
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
import traceback

app = Flask(__name__)

# CORS
CORS(app, supports_credentials=True)

# MySQL 設定
app.config['MYSQL_HOST'] = db_config['host']
app.config['MYSQL_USER'] = db_config['user']
app.config['MYSQL_PASSWORD'] = db_config['password']
app.config['MYSQL_DB'] = db_config['database']

# JWT 設定
app.config['JWT_SECRET_KEY'] = 'TanJiDynamicPricing2025finalproject'
jwt = JWTManager(app)

mysql = MySQL(app)

# ---------------------- 註冊 ----------------------
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            "INSERT INTO users (name, phone, email, password) VALUES (%s, %s, %s, %s)",
            (name, phone, email, password)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '註冊成功'}), 200
    except Exception as e:
        print(traceback.format_exc())
        return jsonify({'message': '註冊失敗', 'error': str(e)}), 500

# ---------------------- 登入 ----------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']

    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE email=%s AND password=%s", (email, password))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3]
            }
            # 建立 JWT Token
            token = create_access_token(identity=user_data['id'])
            return jsonify({'message': '登入成功', 'user': user_data, 'token': token}), 200
        else:
            return jsonify({'message': '帳號或密碼錯誤'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- 取得會員資料 ----------------------
@app.route('/user/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    current_user = get_jwt_identity()
    if current_user != user_id:
        return jsonify({'message': '沒有權限查看此資料'}), 403

    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3],
            }
            return jsonify(user_data), 200
        else:
            return jsonify({'message': '找不到該會員'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- 更新會員資料 ----------------------
@app.route('/user/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    current_user = get_jwt_identity()
    if current_user != user_id:
        return jsonify({'message': '沒有權限更新此資料'}), 403

    data = request.get_json()
    fields = {k: v for k, v in data.items() if k in ['name', 'email', 'phone', 'password']}

    if not fields:
        return jsonify({'message': '沒有可更新的欄位'}), 400

    set_clause = ", ".join([f"{key}=%s" for key in fields.keys()])
    values = list(fields.values())
    values.append(user_id)

    try:
        cur = mysql.connection.cursor()
        sql = f"UPDATE users SET {set_clause} WHERE id=%s"
        cur.execute(sql, values)
        mysql.connection.commit()

        # 再抓更新後的資料
        cur.execute("SELECT id, name, phone, email FROM users WHERE id=%s", (user_id,))
        updated_user = cur.fetchone()
        cur.close()

        user_data = {
            'id': updated_user[0],
            'name': updated_user[1],
            'phone': updated_user[2],
            'email': updated_user[3],
        }

        return jsonify({'message': '更新成功', 'user': user_data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- 抓歷史資料 ----------------------
@app.route('/get_products/<string:user_id>', methods=['GET'])
def get_products(user_id):
    try:
        # 支援訪客模式
        if user_id == "0" or user_id.lower() == "guest":
            return jsonify({'products': []}), 200

        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.productid, p.producttype, p.proname, p.proprice,   
                   h.created_at, p.expiredate, p.status, p.market
            FROM history h
            JOIN product p ON h.productid = p.productid
            WHERE h.userid = %s
            ORDER BY h.created_at DESC
        """, (user_id,))
        products = cur.fetchall()
        cur.close()

        product_list = []
        for p in products:
            product_list.append({
                'ProductID': p[0],
                'ProductType': p[1],
                'ProName': p[2],
                'ProPrice': p[3],
                'ScanDate': p[4].strftime('%Y-%m-%d') if p[4] else None,
                'ExpireDate': p[5].strftime('%Y-%m-%d') if p[5] else None,
                'Status': p[6],
                'Market': p[7],
            })
        return jsonify({'products': product_list}), 200

    except Exception as e:
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

# ---------------------- 啟動 ----------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

    

//api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final String ip = 'http://127.0.0.1:5000';

/// ------------------ 註冊 ------------------
Future<bool> registerUser(String name, String phone, String email, String password) async {
  final url = Uri.parse('$ip/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('註冊成功');
      return true;
    } else {
      print('註冊失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 登入 ------------------
/// 回傳 id, name, token
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final url = Uri.parse('$ip/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'id': data['user']['id'],
        'name': data['user']['name'],
        'token': data['token'], // ✅ JWT token
      };
    } else {
      print('登入失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 抓取會員資料 ------------------
/// 需要帶 token
Future<Map<String, dynamic>?> fetchUserData(int userId, String token) async {
  final url = Uri.parse('$ip/user/$userId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('取得會員資料失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 更新會員資料 ------------------
/// 需要帶 token
Future<bool> updateUserData({
  required int userId,
  required String token,
  String? name,
  String? email,
  String? phone,
  String? password,
}) async {
  final url = Uri.parse('$ip/user/$userId');

  final Map<String, dynamic> body = {};
  if (name != null) body['name'] = name;
  if (email != null) body['email'] = email;
  if (phone != null) body['phone'] = phone;
  if (password != null) body['password'] = password;

  if (body.isEmpty) {
    print('沒有可更新的欄位');
    return false;
  }

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('更新成功: ${response.body}');
      return true;
    } else {
      print('更新失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 註冊畫面 ------------------
class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: '電話')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: '密碼'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await registerUser(
                  nameController.text,
                  phoneController.text,
                  emailController.text,
                  passwordController.text,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('註冊成功')),
                  );
                }
              },
              child: const Text('註冊'),
            )
          ],
        ),
      ),
    );
  }
}


