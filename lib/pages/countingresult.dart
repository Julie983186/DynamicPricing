import 'package:flutter/material.dart';
import 'adviceproduct.dart';
import '../services/route_logger.dart';
import 'register_login_page.dart'; // 登入 / 註冊頁面

class CountingResult extends StatefulWidget {
  const CountingResult({super.key});

  @override
  State<CountingResult> createState() => _CountingResultState();
}

class _CountingResultState extends State<CountingResult> {
  bool _hasShownGuestDialog = false;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/countingResult'); // 記錄當前頁面

    // 等畫面 build 完再顯示 dialog（這樣才能拿到 context）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isGuest() && !_hasShownGuestDialog) {
        _hasShownGuestDialog = true;
        _showGuestDialog();
      }
    });
  }

  // TODO: 這裡示範性地回傳 true 表示是訪客。
  // 在實務上請改成你的真實判斷，例如從 Provider、SharedPreferences、或 FirebaseAuth 檢查使用者是否為訪客。
  bool _isGuest() {
    // 範例：假設目前為訪客，請改成實際邏輯
    return true;
  }

  // 若使用者選擇「保留」，可以在這裡呼叫儲存掃描紀錄的函式
  Future<void> _saveScanRecord() async {
    // TODO: 在此實作儲存掃描紀錄（例如呼叫 API、寫入 local DB）
    debugPrint('掃描紀錄已儲存（範例）');
  }

  // 若使用者選擇「不保留」，可以在這裡處理捨棄邏輯
  Future<void> _discardScanRecord() async {
    // TODO: 在此實作捨棄掃描紀錄的必要流程（例如不送出、不寫入資料庫）
    debugPrint('掃描紀錄已捨棄（範例）');
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 點背景不會關閉
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("提示"),
          content: const Text("您目前是訪客身分，要不要保留這筆掃描紀錄？"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 關閉 dialog
                await _discardScanRecord();
                // 維持在 countingresult.dart（不做其他跳轉）
              },
              child: const Text("不保留"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 關閉 dialog
                // 前往登入/註冊頁面（可用 push 或 pushReplacement）
                // 這裡示範 push，註冊完成可用 Navigator.pop(context, true) 回傳結果
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterLoginPage(),
                  ),
                );

                // 如果 RegisterLoginPage 回傳 true 表示註冊/登入成功並要儲存該筆掃描紀錄
                if (result == true) {
                  await _saveScanRecord();
                } else {
                  // 使用者可能沒有完成註冊/登入，視需求處理
                  debugPrint('RegisterLoginPage 回傳: $result');
                }
              },
              child: const Text("保留"),
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
      backgroundColor: const Color(0xFFD9EAD3),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 250),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- 上方 LOGO 與 icons ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
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
                        Icon(Icons.fullscreen, size: 30, color: Colors.black87),
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
                          "有效期限：2025-05-25",
                          style:
                              TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),

                        // --- 價格比對 ---
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

            // 下方可拖曳的推薦商品區塊
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.85,
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

