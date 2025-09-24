import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';


class MemberHistoryPage extends StatefulWidget {
  final int userId;        // 會員 ID, 訪客用 0
  final String? token;     // JWT token, 訪客為 null

  const MemberHistoryPage({Key? key, required this.userId, this.token}) : super(key: key);

  @override
  State<MemberHistoryPage> createState() => _MemberHistoryPageState();
}

class _MemberHistoryPageState extends State<MemberHistoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
    saveCurrentRoute('/member_history'); // 記錄當前頁面
  }

  Future<void> fetchHistory() async {
    try {
      final url = Uri.parse("http://127.0.0.1:5000/get_products/${widget.userId}");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}', // ✅ 會員才帶 token
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data['products'];
          isLoading = false;
        });
      } else {
        throw Exception("載入失敗: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)),
        title: const Text(
          '掃描歷史',
          style: TextStyle(color: Color(0xFF388E3C)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 搜尋欄
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildSearchBar(context),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                '掃描歷史記錄',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 歷史記錄列表
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? Center(
                            child: Text(
                              widget.token == null
                                  ? "訪客模式無法保存歷史紀錄"
                                  : "目前沒有歷史紀錄",
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: _buildHistoryCard(context, product),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品圖片 placeholder
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 5),
              Text(
                product['Market'] ?? '未知超市',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const Text(
                '分店',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(width: 15),

          // 商品資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['ProName'] ?? '未知商品',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                _buildInfoRow('掃描時間', product['ScanDate'] ?? ''),
                _buildInfoRow('有效期限', product['ExpireDate'] ?? ''),
                _buildInfoRow('狀態', product['Status'] ?? ''),
                const SizedBox(height: 5),
                _buildPriceRow('原價', '\$${product['ProPrice'] ?? 0}', isOriginal: true),
                _buildPriceRow('建議價格', '\$55', isOriginal: false), // 假設
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('刪除按鈕已點擊'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isOriginal ? Colors.black54 : Colors.green[700],
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isOriginal ? Colors.black87 : Colors.red,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
