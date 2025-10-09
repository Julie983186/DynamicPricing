//main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import pages
import 'pages/splash_screen.dart'; 
import 'pages/scanning_picture_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
import 'pages/register_login_page.dart';
import 'pages/member_history_page.dart';
import 'pages/counting.dart';
import 'pages/countingresult.dart';
import 'pages/adviceproduct.dart';
import 'pages/member_profile_page.dart'; 
import 'pages/member_edit_page.dart'; 

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

      // localization (保持不變)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
      ],

      // 應用程式永遠從 /splash 啟動
      initialRoute: '/splash',
      routes: {
        // ------------------ 啟動畫面路由 ------------------
        '/splash': (context) => const SplashScreen(),

        // ------------------ 會員相關路由 ------------------
        '/login': (context) => const RegisterLoginPage(), 

        // 注意：/member_history 可能也需要修改，因為它的參數也是硬編碼的
        '/member_history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberHistoryPage(
            userId: args['userId'],
            userName: args['userName'],
            token: args['token'],
          );
        },


        '/member_profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberProfilePage(
            userId: args['userId'],
            userName: args['userName'],
            token: args['token'],
          );
        },
        
        '/member_edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberEditPage(
            userId: args['userId'],
            userName: args['userName'],
            phone: args['phone'],
            email: args['email'],
            token: args['token'],
          );
        },

        // ------------------ 掃描與識別路由 (保持不變) ------------------
        '/scan': (context) => ScanningPicturePage(),
        '/counting': (context) => LoadingPage(),
        '/countingResult': (context) => CountingResult(),
        '/loading': (context) => RecognitionLoadingPage(),
        '/resultCheck': (context) => RecognitionResultPage(),
        '/edit': (context) => RecognitionEditPage(),

        // ------------------ 推薦商品路由 (保持不變) ------------------
        '/advice_product': (context) => Scaffold(
          appBar: AppBar(title: const Text('推薦商品')),
          body: AdviceProductList(
            scrollController: ScrollController(),
          ),
        ),
      },
    );
  }
}
---------------------------------------------------
//api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb

/// ------------------ 全域 IP 設定 ------------------
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:5000'; 
}
/// ------------------ 註冊 ------------------
Future<bool> registerUser(String name, String phone, String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/register');

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
  final url = Uri.parse('${ApiConfig.baseUrl}/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("login success data = $data");
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
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

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
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

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
---------------------------------------------------
//route_logger.dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveCurrentRoute(String routeName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_route', routeName);
}
---------------------------------------------------
//splash_screen.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart'; // 確保路徑正確

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/splash'); // 記錄當前頁面
    _navigateToNextScreen();
  }

  // 設定跳轉邏輯
  void _navigateToNextScreen() async {
    // 延遲 3 秒後自動跳轉
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      // 使用 pushReplacementNamed 跳轉到登入頁面，並清除當前路由
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 這裡我們使用一個簡單的、與你的 LOGO 主題相符的背景
    // 你可以替換為你的資產圖片，如果你的圖片路徑是 'assets/splash_image.jpg'
    
    // 假設你的 LOGO 圖片（如你上傳的 `image_171c04.jpg` 所示）
    // 已經放在 assets 資料夾中，並且你已在 pubspec.yaml 中註冊該資料夾。
    
    // 如果你沒有使用圖片，則使用純色背景和文字 LOGO
    return Scaffold(
      // 背景色使用與圖片相符的淺黃/淺綠色調
      backgroundColor: const Color(0xFFF5F0D0), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 這是使用圖片資產的方法（請確保路徑正確）
            Image.asset(
              'assets/splash_background.jpg',
              width: MediaQuery.of(context).size.width * 0.8, // 螢幕 80% 寬
              fit: BoxFit.contain,
            ),
            // 如果不想用圖片，只想用文字和顏色
            /*
            const Text(
              '碳即',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            */
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//register_login_page.dart
import 'package:flutter/material.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import 'countingresult.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
// import 'register_login_page.dart'; // 移除不必要的自我引用

// 定義會員頁面的淺綠色背景
const Color _kLightGreenBg = Color(0xFFE8F5E9);

// 註冊與登入頁面
class RegisterLoginPage extends StatefulWidget {
  const RegisterLoginPage({super.key});

  @override
  State<RegisterLoginPage> createState() => _RegisterLoginPageState();
}

class _RegisterLoginPageState extends State<RegisterLoginPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/login'); // 記錄當前頁面
  }

  // Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox(
      height: 150, // 增加 Logo 容器的高度
      width: 300,
      child: Image.asset(
        'assets/logo.png', // 確保這是你的 Logo 圖片正確路徑
        width: 300,
        fit: BoxFit.contain, // 確保圖片完整顯示不裁切
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _kLightGreenBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  _buildLogo(),
                  const SizedBox(height: 20),

                  Container(
                    width: 300, // 註冊/登入卡片的寬度
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
                    child: const Column(
                      children: [
                        TabBar(
                          labelColor: Colors.black,
                          indicatorColor: Colors.green,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        SizedBox(height: 20),
                        // TabBarView 設定固定高度 380
                        SizedBox(
                          height: 380,
                          child: TabBarView(
                            children: [
                              RegisterForm(),
                              LoginForm(), // LoginForm 現在使用 spaceBetween
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // 底部間距
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 輔助函式: 建立文字輸入框
Widget buildTextField(String label,
    {bool obscureText = false, TextEditingController? controller}) {
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

// --- 註冊表單 (RegisterForm) ---
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
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

  // 註冊邏輯方法
  void submitRegister() async {
    // 假設 registerUser 是已定義的異步服務方法
    // 這裡我們假設它已定義在 api_service.dart 中
    try {
      bool isSuccess = await registerUser(
        nameController.text,
        phoneController.text,
        emailController.text,
        passwordController.text,
      );

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 2));
        DefaultTabController.of(context)?.animateTo(1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊失敗，請重試。'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 註冊表單仍使用預設的 start 對齊，因為內容較多，本身就比較貼近底部
    return Column(
      children: [
        buildTextField('姓名', controller: nameController),
        buildTextField('電話', controller: phoneController),
        buildTextField('Email', controller: emailController),
        buildTextField('密碼', controller: passwordController, obscureText: true),
        
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
          ),
          
          child: const Text(
            '註冊',
            style: TextStyle(color: Colors.white), 
          ),
        ),
        
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanningPicturePage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Color(0xFF274E13)),
          ),
          child: const Text(
            '以訪客身份使用',
            style: TextStyle(color: Color(0xFF274E13)),
          ),
        ),
      ],
    );
  }
}

// --- 登入表單 (LoginForm) ---
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 登入邏輯方法
  void submitLogin() async {
    // 假設 loginUser 是已定義的異步服務方法
    final user = await loginUser(
      emailController.text,
      passwordController.text,
    );

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanningPicturePage(
            userId: user['id'] as int,
            userName: user['name'] as String,
            token: user['token'] as String,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登入失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 關鍵修改點：使用 MainAxisAlignment.spaceBetween
    return Column(
      // 使用 spaceBetween 讓內容（頂部輸入框組和底部按鈕組）在固定高度內撐開
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Email 和密碼欄位 (貼齊頂部)
        Column(
          mainAxisSize: MainAxisSize.min, // 確保這組 Column 只佔用最小高度
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        
        // 2. 登入和訪客按鈕 (貼齊底部)
        Column(
          mainAxisSize: MainAxisSize.min, // 確保這組 Column 只佔用最小高度
          children: [
            const SizedBox(height: 20), // 登入按鈕上方的間距
            ElevatedButton(
              onPressed: submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              
              child: const Text(
                '登入',
                style: TextStyle(color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 10), // 按鈕間的間距
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanningPicturePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF274E13)),
              ),
              child: const Text(
                '以訪客身份使用',
                style: TextStyle(color: Color(0xFF274E13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
---------------------------------------------------
//scanning_picture_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/route_logger.dart';
import 'recognition_loading_page.dart';
import 'member_profile_page.dart';
import 'register_login_page.dart';

class ScanningPicturePage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const ScanningPicturePage({
    Key? key,
    this.userId,
    this.userName,
    this.token,
  }) : super(key: key);

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage>
    with TickerProviderStateMixin {
  late Future<CameraController> _cameraControllerFuture;
  late AnimationController _animationController;
  bool _isFlashing = false;
  bool _isUploading = false;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/scan');
    _cameraControllerFuture = _initCameraController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<CameraController> _initCameraController() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxContentWidth = 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 90, // 整體 AppBar 高度
        title: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5), // 控制上下距離
            child: Image.asset(
              'assets/logo.png',
              height: 90, // 固定 Logo 高度
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
        centerTitle: true,
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
                  child: FutureBuilder<CameraController>(
                    future: _cameraControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text("無法初始化相機"));
                      }
                      final controller = snapshot.data!;
                      return _buildOverlayStack(controller);
                    },
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

  Widget _buildTopUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        if (widget.userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberProfilePage(
                                userId: widget.userId!,
                                userName: widget.userName ?? "會員",
                                token: widget.token ?? "",
                              ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("需要登入"),
                                content: const Text("請先登入或註冊以使用會員功能"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("取消"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterLoginPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text("登入/註冊"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_circle,
                            color: Colors.white, size: 25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userId != null ? widget.userName ?? "會員" : "訪客",
                    style: const TextStyle(
                        color: Color(0xFF388E3C), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(child: _buildStoreDropdown()),
            ],
          ),
          const SizedBox(height: 10),
          _buildCurrentStoreInfo(),
        ],
      ),
    );
  }

  Widget _buildStoreDropdown() {
    final List<String> stores = ['家樂福', '全聯', '愛買'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStore,
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

  Widget _buildOverlayStack(CameraController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
        if (_isFlashing) Container(color: Colors.white.withOpacity(0.7)),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

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

  Widget _buildScanLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const double scanLineWidth = 320 * 0.8;
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

  Widget _buildHintText() {
    return const Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Text(
        '請對準產品名稱、價格與有效期限',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: FutureBuilder<CameraController>(
          future: _cameraControllerFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _takePicture(snapshot.data!),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                  color: Colors.green,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 30),
              ),
            );
          },
        ),
      ),
    );
  }

  void _takePicture(CameraController controller) async {
    try {
      _animationController.stop();
      setState(() => _isFlashing = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _isFlashing = false);

      final image = await controller.takePicture();
      print('照片已儲存至: ${image.path}');

      setState(() => _isUploading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isUploading = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionLoadingPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      print('拍照或上傳失敗: $e');
      setState(() => _isUploading = false);
    } finally {
      _animationController.repeat(reverse: true);
    }
  }
}
---------------------------------------------------
//recognition_loading_page.dart
// lib/pages/recognition_loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/route_logger.dart';
import 'recognition_result_page.dart';

class RecognitionLoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionLoadingPage({super.key, this.userId, this.userName, this.token});

  @override
  State<RecognitionLoadingPage> createState() => _RecognitionLoadingPageState();
}


class _RecognitionLoadingPageState extends State<RecognitionLoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/loading'); // 記錄當前頁面
    // 3秒後結果確認
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionResultPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              'assets/logo.png',
              height: 140,
            ),
            const SizedBox(height: 40),

            // text
            const Text(
              '辨識進行中...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '請稍待',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // loading indicator
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//recognition_result_page.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart'; // ✅ 導向目標
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';
import 'recognition_loading_page.dart'; 

class RecognitionResultPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionResultPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
  });

  @override
  State<RecognitionResultPage> createState() => _RecognitionResultPageState();
}

class _RecognitionResultPageState extends State<RecognitionResultPage> {
  static const Color _lightGreenBackground = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/resultCheck');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 放大 Logo
            Image.asset(
              'assets/logo.png',
              height: 100, // Logo 放大
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            Image.asset(
              'assets/milk.jpg',
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
              '有效期限：\n2025-10-02',
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

            // 「正確」按鈕
            ElevatedButton(
              onPressed: () {
                // 🎯 修正導航目標：導向 CountingPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 假設 counting.dart 中定義的頁面為 CountingPage
                    builder: (_) => LoadingPage( 
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('正確', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「手動修改」按鈕 (導向 RecognitionEditPage)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognitionEditPage(
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 157, 92),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('手動修改', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「重新掃描」按鈕 (導向 ScanningPicturePage)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanningPicturePage(
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 138, 179),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//recognition_edit_page.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart';
import 'recognition_loading_page.dart'; 

class RecognitionEditPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const RecognitionEditPage({super.key, this.userId, this.userName, this.token});

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  static const Color _primaryGreen = Colors.green;

  final TextEditingController nameController =
        TextEditingController(text: '瑞穗鮮乳・全脂290ml');
  final TextEditingController dateController =
        TextEditingController(text: '2025-10-02');

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit');
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          children: [
            // 返回按鈕靠左，LOGO 居中
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios, color: _primaryGreen),
                  ),
                ),
                // Logo 放大
                Image.asset(
                  'assets/logo.png',
                  height: 100, // 將 Logo 放大
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Image.asset(
              'assets/milk.jpg',
              height: 200,
              fit: BoxFit.contain, // 加上 fit: BoxFit.contain 確保圖片完整顯示
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognitionLoadingPage( // 修正為 RecognitionLoadingPage
                      userId: widget.userId,
                      userName: widget.userName,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
             
              child: const Text(
                '送出',
                style: TextStyle(color: Colors.white, fontSize: 16), 
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//counting.dart
import 'package:flutter/material.dart';
import 'dart:async'; // 確保引入 dart:async
import '../services/route_logger.dart';
import 'countingresult.dart';

class LoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const LoadingPage({super.key, this.userId, this.userName, this.token});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/counting'); // 記錄當前頁面
    
    // 🎯 保持原始邏輯：模擬計算，2秒後跳轉到結果頁
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { 
        // 使用 pushReplacement 較佳，但為保持原邏輯，這裡使用 push
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountingResult(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 背景色保持不變
      body: Center( // 🎯 移除 SafeArea，直接使用 Center
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              'assets/logo.png', // 您的 Logo 圖片路徑
              height: 140, // 🎯 調整圖片高度為 140
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40), // 🎯 調整間距為 40

            // 標題文字
            const Text(
              '價格計算中...', // 保持原始文字
              style: TextStyle(
                fontSize: 20, // 🎯 調整字體大小為 20
                fontWeight: FontWeight.bold, // 🎯 調整字體粗細為 bold
                color: Colors.black, // 🎯 調整文字顏色為黑色
              ),
            ),
            const SizedBox(height: 10),
            
            // 副標題文字
            const Text(
              '請稍待',
              style: TextStyle(
                fontSize: 16, // 🎯 調整字體大小為 16
                color: Colors.black54, // 🎯 調整文字顏色為 Colors.black54
              ),
            ),
            const SizedBox(height: 30), // 🎯 調整間距為 30

            // 🎯 loading indicator
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//countingresult.dart
import 'package:flutter/material.dart';
import 'adviceproduct.dart';
import '../services/route_logger.dart';
import 'register_login_page.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart'; // 確保 ScanningPicturePage 已被引入

class CountingResult extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const CountingResult({
    super.key,
    this.userId,
    this.userName,
    this.token,
  });

  @override
  State<CountingResult> createState() => _CountingResultState();
}

class _CountingResultState extends State<CountingResult> {
  // 標準背景色設定
  static const Color _standardBackground = Color(0xFFE8F5E9);
  
  // 保持原有的訪客對話框狀態旗標
  bool _hasShownGuestDialog = false;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/countingResult');
  }

  bool _isGuest() => widget.userId == null || widget.token == null;

  Future<void> _saveScanRecord() async {
    debugPrint('掃描紀錄已儲存（範例）');
  }

  Future<void> _discardScanRecord() async {
    debugPrint('掃描紀錄已捨棄（範例）');
  }

  // 原始的訪客對話框：用於「再次掃描」按鈕
  void _showGuestDialog() {
    if (_hasShownGuestDialog) return; // 防止重複彈出
    _hasShownGuestDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("提示"),
          content: const Text("您目前是訪客身分，要不要保留這筆掃描紀錄？"),
          actions: [
            TextButton(
              onPressed: () async {
                // 1. 關閉對話框
                Navigator.of(context).pop();
                
                // 2. 捨棄掃描紀錄
                await _discardScanRecord();
                
                // 3. 導回掃描頁面 (使用 pushReplacement 避免堆疊過深)
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanningPicturePage(
                        userId: widget.userId,
                        userName: widget.userName,
                        token: widget.token,
                      ),
                    ),
                  );
                }
              },
              child: const Text("不保留"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterLoginPage()),
                );
                if (result == true) {
                  await _saveScanRecord();
                }
              },
              child: const Text("保留"),
            ),
          ],
        );
      },
    ).then((_) {
      // 關閉後允許下次再觸發
      _hasShownGuestDialog = false;
    });
  }

  // 🎯 修改後的「需要登入」對話框：用於點擊頭像 (使用標準 AlertDialog 樣式)
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("需要登入"),
          content: const Text("請先登入或註冊以使用會員功能"),
          actions: <Widget>[
            // 取消按鈕 (左側)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 關閉對話框
              },
              child: const Text("取消"),
            ),
            
            // 登入/註冊按鈕 (右側，橘色背景)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // 橘色背景
              ),
              onPressed: () {
                // 1. 關閉對話框
                Navigator.of(context).pop(); 
                
                // 2. 導向登入/註冊頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterLoginPage()),
                );
              },
              child: const Text("登入/註冊"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double originalPrice = 35;
    double discountPrice = 32;
    double saved = originalPrice - discountPrice;

    return Scaffold(
      // 背景顏色修改為 0xFFE8F5E9
      backgroundColor: _standardBackground, 
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 250),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 上方 LOGO 與 icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 左上角會員 / 訪客 icon 【樣式已修改】
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_isGuest()) {
                                // 🎯 訪客點擊頭像時彈出「需要登入」對話框
                                _showLoginRequiredDialog();
                              } else {
                                // 會員點擊時導向會員檔案頁面 (保持不變)
                                Navigator.pushNamed(
                                  context,
                                  '/member_profile',
                                  arguments: {
                                    'userId': widget.userId!,
                                    'userName': widget.userName!,
                                    'token': widget.token!,
                                  },
                                );
                              }
                            },
                            child: Column(
                              children: [
                                // 🎯 新的頭像樣式
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF388E3C).withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_circle,
                                      color: Colors.white, size: 25),
                                ),
                                
                                const SizedBox(height: 4),
                                Text(
                                  _isGuest()
                                      ? "訪客"
                                      : (widget.userName ?? "會員"),
                                  // 🎯 新的文字樣式 (綠色文字)
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // LOGO 替換為圖片
                        Image.asset(
                          'assets/logo.png', // 您的 Logo 圖片路徑
                          height: 90, // 調整圖片高度，與 LOGO 文字高度相當
                          fit: BoxFit.contain,
                        ),

                        // 右上角再次掃描 icon
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              // 🎯 修正：訪客點擊時呼叫原始的 _showGuestDialog()
                              if (_isGuest()) {
                                _showGuestDialog(); // 彈出「要不要保留這筆掃描紀錄？」
                              } else {
                                // 會員直接導向掃描頁面 (保持不變)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScanningPicturePage(
                                      userId: widget.userId,
                                      userName: widget.userName,
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.fullscreen,
                                  size: 30, color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 商品卡片 (內容不變)
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
                          child: Image.asset(
                            'assets/milk.jpg',
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
                          "有效期限：2025-10-02",
                          style: TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildPriceBox("即期價格", "\$$originalPrice",
                                isDiscount: false),
                            buildPriceBox("AI定價", "\$$discountPrice",
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

            // 推薦商品 DraggableScrollableSheet (內容不變)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
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

  Widget buildPriceBox(String title, String price,
      {bool isDiscount = false}) {
    // ... buildPriceBox 方法保持不變
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
                decoration:
                    isDiscount ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//adviceproduct.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart';

class AdviceProductList extends StatefulWidget {
  final ScrollController scrollController;
  const AdviceProductList({super.key, required this.scrollController});

  @override
  State<AdviceProductList> createState() => _AdviceProductListState();
}

class _AdviceProductListState extends State<AdviceProductList> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/advice_product'); // 記錄當前頁面
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 30,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 28,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 25,
              expiry: "效期剩5小時",
            ),
          ],
        ),
      ],
    );
  }
}

/// ProductCard 保持不變
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
              child: Image.asset(imageUrl, fit: BoxFit.contain),
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
---------------------------------------------------
//member_pofile_page.dart
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
---------------------------------------------------
//member_history_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'package:intl/intl.dart'; // 💡 新增：用於日期格式化
import 'scanning_picture_page.dart';
import '../services/api_service.dart';


// 定義顏色常量 (使用與其他頁面一致的色系)
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9); // 頁面背景色
const Color _kCardBg = Color(0xFFF1F8E9); // 卡片背景色
const Color _kAccentRed = Color(0xFFD32F2F); // 價格/刪除紅色

class MemberHistoryPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const MemberHistoryPage({super.key, this.userId, this.userName, this.token});

  @override
  State<MemberHistoryPage> createState() => _MemberHistoryPageState();
}

class _MemberHistoryPageState extends State<MemberHistoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  DateTime? _selectedDate; // 💡 新增：用於儲存使用者選擇的日期

  @override
  void initState() {
    super.initState();
    // 初始載入時不傳遞日期，載入全部歷史
    fetchHistory(); 
    saveCurrentRoute('/member_history'); 
  }

  // 💡 新增：日期選擇器函式
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryGreen, // 日期選擇器主色
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _kPrimaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // 重新載入歷史紀錄，並傳遞選定的日期
      fetchHistory(date: picked);
    }
  }

  // 💡 修改：fetchHistory 函式接受可選的 date 參數
  Future<void> fetchHistory({DateTime? date}) async {
    setState(() {
      isLoading = true; // 重新搜尋時顯示 loading
    });

    // 格式化日期為 YYYY-MM-DD 格式，以便傳遞給 API
    String? dateString;
    if (date != null) {
      dateString = DateFormat('yyyy-MM-dd').format(date);
    } else if (_selectedDate != null) {
      dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    try {
      final baseUrl = "${ApiConfig.baseUrl}/get_products/${widget.userId}";
      final url = dateString != null ? Uri.parse('$baseUrl?date=$dateString') : Uri.parse(baseUrl);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}', 
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(mounted) {
          setState(() {
            products = data['products'] ?? []; 
            isLoading = false;
          });
        }
      } else {
        throw Exception("載入失敗: ${response.body}");
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching history: $e");
    }
  }

  // 模擬刪除功能 (保持不變)
  void _deleteHistoryItem(int productId, int index) {
    // 這裡應該呼叫 API 進行實際刪除
    setState(() {
      products.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('商品已移除: ${productId}'), duration: const Duration(seconds: 1)),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 💡 顯示當前選定的日期，若無則顯示 '掃描歷史記錄'
    String titleText = _selectedDate == null 
        ? '掃描歷史記錄' 
        : DateFormat('yyyy/MM/dd').format(_selectedDate!);

    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
        // 移除 AppBar，使用自定義的導航結構以符合設計圖的簡潔風格
        automaticallyImplyLeading: false, // 隱藏預設返回按鈕
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部導航欄 (返回鍵 + 掃描圖示)
            _buildCustomHeader(context),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // 標題 (顯示日期或預設文字)
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryGreen, // 標題顏色使用主色調
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // 搜尋欄
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildSearchBar(context),
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // 歷史記錄列表
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: _kPrimaryGreen))
                          : products.isEmpty
                              ? Center(
                                  child: Text(
                                    _selectedDate != null 
                                        ? "當日沒有歷史紀錄"
                                        : (widget.token == null ? "訪客模式無法保存歷史紀錄" : "目前沒有歷史紀錄"),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 15.0),
                                      child: _buildHistoryCard(context, product, index),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helper 函式 ---

  // 依設計圖重新構建的頂部 Header (保持不變)
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      color: _kLightGreenBg, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _kPrimaryGreen),
            onPressed: () => Navigator.pop(context), 
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: _kPrimaryGreen), 
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanningPicturePage(
                  userId: widget.userId!,
                  userName: widget.userName!,
                  token: widget.token!,
                ),
              ),
            ), 
          ),
        ],
      ),
    );
  }
  
  // 💡 修改：搜尋欄位 Helper (加入日曆按鈕)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
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
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // 💡 變更：右側圖標改為日曆，並加上點擊事件
          GestureDetector(
            onTap: () => _selectDate(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.calendar_today, color: _kPrimaryGreen), 
            ),
          ),
        ],
      ),
    );
  }

  // 歷史記錄單一卡片 Helper (保持不變)
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product, int index) {
    // 假設 product['Market'] 包含 '家樂福' 和 '內壢店'
    final marketParts = (product['Market'] as String? ?? '未知超市|未知分店').split('|');
    final market = marketParts[0];
    final branch = marketParts.length > 1 ? marketParts[1] : '分店';
    
    // 價格和有效期限
    final originalPrice = product['ProPrice'] ?? 0;
    const suggestedPrice = 32; // 假設AI定價為 32 元

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: _kCardBg, // 淺綠色卡片背景
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
          // 商品圖片 + 超市分店
          SizedBox(
            width: 80,
            child: Column(
              children: [
                // 圖片 placeholder (可替換為 NetworkImage)
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                    image: DecorationImage(
                      // 如果有 ImageUrl 可以改成 NetworkImage(product['ImageUrl'])
                      image: AssetImage('assets/milk.jpg'), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  market,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  branch,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // 商品資訊 (名稱, 時間, 價格)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['ProName'] ?? '未知商品',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                _buildInfoRow('掃描時間', product['ScanDate'] ?? '-'),
                _buildInfoRow('有效期限', product['ExpireDate'] ?? '-'),
                _buildPriceRow('即期價格', '\$${originalPrice}', isOriginal: true),
                _buildPriceRow('AI定價', '\$${suggestedPrice}', isOriginal: false),
              ],
            ),
          ),

          // 刪除按鈕
          GestureDetector(
            onTap: () => _deleteHistoryItem(product['ProId'] ?? -1, index),
            child: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.delete_outline, color: _kAccentRed, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // 資訊行 Helper (保持不變)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  // 價格行 Helper (保持不變)
  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isOriginal ? Colors.black54 : _kAccentRed, // 建議價格使用紅色
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: 14
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isOriginal ? Colors.black87 : _kAccentRed,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
---------------------------------------------------
//member_edit_page.dart
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
        const SnackBar(content: Text('資料已成功修改！'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // ✅ 通知 Profile 要 reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.red),
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
