import 'package:flutter/material.dart';

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
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 上方 LOGO 與 icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 左上角 - 人頭 icon + 訪客文字
                      Column(
                        children: const [
                          Icon(Icons.person, size: 32, color: Colors.black87),
                          SizedBox(height: 4),
                          Text(
                            "訪客",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // LOGO
                      const Text(
                        'LOGO',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF274E13),
                        ),
                      ),

                      // 右上角 - 放大 icon
                      const Icon(Icons.fullscreen, size: 30, color: Colors.black87),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 商品卡片（圖片 + 商品資訊 + 比價區塊）
                Container(
                  width: 330,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // 商品圖片
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

                      // 商品名稱與效期
                      const Text(
                        "商品名稱：瑞穗鮮乳-全脂290ml",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "有效期限：2025-05-25",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      // 價格比對
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 原價 Container
                          SizedBox(
                            width: 130,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200, // 原價底色
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "原價",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "\$$originalPrice",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 即期優惠價 Container
                          SizedBox(
                            width: 130,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100, // 優惠價底色
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "即期優惠價",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "\$$discountPrice",
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

                const SizedBox(height: 30),

                // 推薦商品區塊
                Container(
                  width: 330,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "先別閃開！根據推薦的商品，您也能考慮以下商品：",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildRecommendedItem("https://i.ibb.co/qgrT6V1/item1.png", 30),
                          buildRecommendedItem("https://i.ibb.co/m0HFLw2/item2.png", 28),
                          buildRecommendedItem("https://i.ibb.co/98w0MfM/item3.png", 25),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 建立推薦商品小卡片
  Widget buildRecommendedItem(String imageUrl, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Text(
            "\$$price",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
