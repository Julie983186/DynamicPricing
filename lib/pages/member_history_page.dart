import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'package:intl/intl.dart'; // 💡 新增：用於日期格式化
import 'scanning_picture_page.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:async';



// 定義顏色常量
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9); 
const Color _kCardBg = Color(0xFFF1F8E9); 
const Color _kAccentRed = Color(0xFFD32F2F); 

class MemberHistoryPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const MemberHistoryPage({super.key, this.userId, this.userName, this.token});

  @override
  State<MemberHistoryPage> createState() => _MemberHistoryPageState();
}

class _MemberHistoryPageState extends State<MemberHistoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  DateTime? _selectedDate;
  String _searchText = ""; // 搜尋文字

  
  Timer? _priceRefreshTimer; // ✅ 定時刷新 AI 價格

  @override
  void initState() {
    super.initState();
    fetchHistory(); 
    saveCurrentRoute('/member_history'); 

    // ✅ 定時刷新 AI 價格，每 30 秒更新一次
    _priceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshAiPrices();
    });
  }
  @override
  void dispose() {
    _priceRefreshTimer?.cancel(); // ✅ 停掉定時器
    super.dispose();
  }

  // 日期選擇器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _kPrimaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      fetchHistory(date: picked, search: _searchText);
    }
  }

  // 抓歷史紀錄 + AI定價
  Future<void> fetchHistory({DateTime? date, String? search}) async {
    setState(() => isLoading = true);

    String baseUrl = "${ApiConfig.baseUrl}/get_products/${widget.userId}";
    Map<String, String> queryParams = {};

    if (date != null) {
      queryParams["date"] = DateFormat('yyyy-MM-dd').format(date);
    } else if (_selectedDate != null) {
      queryParams["date"] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    if (search != null && search.isNotEmpty) {
      queryParams["search"] = search;
    } else if (_searchText.isNotEmpty) {
      queryParams["search"] = _searchText;
    }

    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            products = data['products'] ?? [];
            isLoading = false;
          });
        }
        // ✅ 立即抓一次 AI 價格
        _refreshAiPrices();

        print("✅ 抓到歷史紀錄，共 ${products.length} 筆");
        for (var p in products) {
          print("Product: ${p['ProName']}, HistoryID=${p['HistoryID']}, AI=${p['AiPrice']}");
        }
      } else {
        throw Exception("載入失敗: ${response.body}");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("❌ Error fetching history: $e");
    }
  }
  // 🔹 專門刷新 AI 價格的方法
  Future<void> _refreshAiPrices() async {
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      double? aiPrice = await fetchAIPrice(product['ProductID']); // 或使用 product['ProName']
      if (aiPrice != null && mounted) {
        setState(() {
          products[i]['AiPrice'] = aiPrice;
        });
      }
    }
  }

  // 刪除紀錄
  void _deleteHistoryItem(int historyId, int index) async {
    if (historyId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 無效的 HistoryID')),
      );
      return;
    }

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/history/$historyId");
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已刪除紀錄 (ID=$historyId)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 刪除失敗: ${response.body}')),
        );
      }
    } catch (e) {
      print("❌ 刪除發生錯誤: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 刪除發生錯誤: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = _selectedDate == null 
        ? '掃描歷史記錄' 
        : DateFormat('yyyy/MM/dd').format(_selectedDate!);

    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildSearchBar(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: _kPrimaryGreen))
                          : products.isEmpty
                              ? Center(
                                  child: Text(
                                    _selectedDate != null 
                                        ? "當日沒有歷史紀錄"
                                        : (widget.token == null ? "訪客模式無法保存歷史紀錄" : "目前沒有歷史紀錄"),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 15.0),
                                      child: _buildHistoryCard(context, product, index),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      color: _kLightGreenBg, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _kPrimaryGreen),
            onPressed: () => Navigator.pop(context), 
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: _kPrimaryGreen), 
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanningPicturePage(
                  userId: widget.userId!,
                  userName: widget.userName!,
                  token: widget.token!,
                ),
              ),
            ), 
          ),
        ],
      ),
    );
  }
  
  // 搜尋欄位 (含日曆)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchText = value;
                });
                fetchHistory(search: value);
              },
            ),
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.calendar_today, color: _kPrimaryGreen), 
            ),
          ),
        ],
      ),
    );
  }

  // 單一卡片
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product, int index) {
    final marketParts = (product['Market'] as String? ?? '未知超市|未知分店').split('|');
    final market = marketParts[0];
    final branch = marketParts.length > 1 ? marketParts[1] : '分店';
    
    final originalPrice = product['ProPrice'] ?? 0;
    final suggestedPrice = product['AiPrice'] ?? 0; 

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: _kCardBg,
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
          // 圖片
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                    image: DecorationImage(
                      image: product['ImagePath'] != null
                        ? NetworkImage("${ApiConfig.baseUrl}${product['ImagePath']}")
                        : const AssetImage('assets/milk.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(market, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(branch, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // 文字資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['ProName'] ?? '未知商品',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                _buildInfoRow('掃描時間', product['ScanDate'] ?? '-'),
                _buildInfoRow('有效期限', product['ExpireDate'] ?? '-'),
                _buildPriceRow('即期價格', '\$${originalPrice}', isOriginal: true),
                _buildPriceRow('AI定價', '\$${suggestedPrice}', isOriginal: true),
              ],
            ),
          ),

          // 刪除按鈕
          GestureDetector(
            onTap: () => _deleteHistoryItem(product['HistoryID'] ?? -1, index),
            child: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.delete_outline, color: _kAccentRed, size: 28),
            ),
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
          Text('$label:', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
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
              color: isOriginal ? Colors.black54 : _kAccentRed,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isOriginal ? Colors.black87 : _kAccentRed,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
