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
