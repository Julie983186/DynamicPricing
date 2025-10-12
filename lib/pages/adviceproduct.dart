import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class AdviceProductList extends StatefulWidget {
  final ScrollController scrollController;
  final int? productId;
  final String? reason;

  const AdviceProductList({
    Key? key,
    required this.scrollController,
    this.productId,
    this.reason,
  }) : super(key: key);

  @override
  State<AdviceProductList> createState() => _AdviceProductListState();
}

class _AdviceProductListState extends State<AdviceProductList> {
  List<dynamic> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    if (widget.productId == null) return;

    try {
      final url = Uri.parse(
          "${ApiConfig.baseUrl}/recommend_products/${widget.productId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recommendations = data;
          _isLoading = false;
        });
      } else {
        print("❌ API錯誤: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 連線錯誤: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.reason == "合理"
                  ? "推薦同賣場、同到期日的其他合理商品"
                  : "推薦同賣場、同到期日同類型的合理商品",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),

            // 若還在載入
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_recommendations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("目前無推薦商品", style: TextStyle(fontSize: 16)),
                ),
              )
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final item = _recommendations[index];
                  final name = item["ProName"] ?? "未命名商品";
                  final price = item["ProPrice"]?.toString() ?? "-";
                  final imagePath = item["ImagePath"] ?? "";
                  final expireDate = item["ExpireDate"] ?? "";

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: imagePath.isNotEmpty
                          ? Image.network(
                              "${ApiConfig.baseUrl}/$imagePath",
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: Text("即期價：\$${price}\n效期：$expireDate"),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
