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
                        // 左上角會員 / 訪客 icon
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_isGuest()) {
                                Navigator.pushNamed(context, '/login');
                              } else {
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
                                const Icon(Icons.account_circle,
                                    size: 32, color: Colors.black87),
                                const SizedBox(height: 4),
                                Text(
                                  _isGuest()
                                      ? "訪客"
                                      : (widget.userName ?? "會員"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
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
                          height: 40, // 調整圖片高度，與 LOGO 文字高度相當
                          fit: BoxFit.contain,
                        ),

                        // 右上角再次掃描 icon
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_isGuest()) {
                                _showGuestDialog();
                              } else {
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