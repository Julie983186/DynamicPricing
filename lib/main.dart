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

// 【刪除舊檔案後，請確保不再引用它們！】
// import 'pages/member_area_page.dart'; // 移除
// import 'pages/member_edit_page.dart'; // 移除

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
        
        // 💡 修正點 1: 移除 /member_area 路由定義。
        // 因為登入頁現在直接使用 MaterialPageRoute 導航到 MemberProfilePage 並傳遞參數。
        // 刪除以下代碼塊：
        /*
        '/member_area': (context) => MemberProfilePage(
              userId: 1, 
              userName: '測試使用者',
              token: 'token123',
            ),
        */
            
        // 💡 修正點 2: 移除 /member_edit 路由（功能已合併）
        // '/member_edit': (context) => MemberEditPage(...) // 移除此行

        // 注意：/member_history 可能也需要修改，因為它的參數也是硬編碼的
        '/member_history': (context) => MemberHistoryPage(
              userId: 1, // ⚠️ 請記得在實際應用中從持久儲存中讀取 userId 和 token
              token: 'token123',
            ),
        
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