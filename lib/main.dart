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
import 'pages/member_edit_page.dart'; // 確保這個 import 存在

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
        
        // 🎯 新增或修正: 會員資料主頁面路由 (/member_area)
        // 由於 MemberProfilePage 必須有參數，這裡採用接收參數的方式定義命名路由
        '/member_area': (context) {
  // --- 測試用的硬編碼資料 (用於沒有參數時的安全啟動) ---
          const int defaultUserId = 1;
          const String defaultUserName = '測試會員';
          const String defaultToken = 'debug_token_456';

          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          
          // 檢查是否有傳入參數，如果沒有就使用預設值。
          final userId = args?['userId'] as int? ?? defaultUserId;
          final userName = args?['userName'] as String? ?? defaultUserName;
          final token = args?['token'] as String? ?? defaultToken;

          // 永遠返回 MemberProfilePage，使用傳入的參數或預設的測試值
          return MemberProfilePage(
            userId: userId,
            userName: userName,
            token: token,
          );
        },


        // 🎯 新增: 會員資料編輯頁面路由 (/member_edit)
        '/member_edit': (context) {
          // 接收從 MemberProfilePage 傳來的參數
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return const Center(child: Text('錯誤：編輯頁缺少會員資料'));
          }
          return MemberEditPage(
            userId: args['userId'] as int,
            userName: args['userName'] as String,
            phone: args['phone'] as String,
            email: args['email'] as String,
            token: args['token'] as String,
          );
        },
            
        // 注意：/member_history 建議也改成接收參數，但此處暫時保持您原有的硬編碼
        '/member_history': (context) => MemberHistoryPage(
              userId: 1, // ⚠️ 請記得在實際應用中從持久儲存中讀取 userId 和 token
              token: 'token123',
            ),
        
        // ------------------ 掃描與識別路由 (保持不變) ------------------
        '/scan': (context) => const ScanningPicturePage(),
        '/counting': (context) => const LoadingPage(),
        '/countingResult': (context) => const CountingResult(),
        '/loading': (context) => const RecognitionLoadingPage(),
        '/resultCheck': (context) => const RecognitionResultPage(),
        '/edit': (context) => const RecognitionEditPage(),

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