import 'package:flutter/material.dart';

class AdviceProduct extends StatelessWidget {
  const AdviceProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部 LOGO 與設定、掃描
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: const [
                      Icon(Icons.person, color: Color(0xFF274E13)),
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
                  const Text(
                    "LOGO",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF274E13),
                    ),
                  ),
                  const Icon(Icons.qr_code_scanner, color: Color(0xFF274E13)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 提示文字
            const Text(
              "先別離開！根據掃描的商品，您也能考慮以下商品：",
              style: TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 商品區塊
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
      ),
    );
  }
}

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
      color: const Color(0xFFD9EAD3), // 修改卡片底色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "\$$price",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expiry,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
