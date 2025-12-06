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
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return MemberHistoryPage(
            userId: args?['userId'],
            userName: args?['userName'],
            token: args?['token'],
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