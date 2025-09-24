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
