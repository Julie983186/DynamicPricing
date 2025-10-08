import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'package:intl/intl.dart'; 
import 'scanning_picture_page.dart';
import '../services/api_service.dart';


// 定義顏色常量 (使用與其他頁面一致的色系)
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9); // 頁面背景色
const Color _kCardBg = Color(0xFFF1F8E9); // 卡片背景色
const Color _kAccentRed = Color(0xFFD32F2F); // 價格/刪除紅色

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

  @override
  void initState() {
    super.initState();
    // 初始載入時不傳遞日期，載入全部歷史
    fetchHistory(); 
    saveCurrentRoute('/member_history'); 
  }

  // 💡 新增：日期選擇器函式
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
              primary: _kPrimaryGreen, // 日期選擇器主色
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
      // 重新載入歷史紀錄，並傳遞選定的日期
      fetchHistory(date: picked);
    }
  }

  // 💡 修改：fetchHistory 函式現在呼叫 API 服務層
Future<void> fetchHistory({DateTime? date}) async {
  setState(() {
    isLoading = true; // 重新搜尋時顯示 loading
  });

  // 格式化日期為 YYYY-MM-DD 格式
  String? dateString;
  if (date != null) {
    dateString = DateFormat('yyyy-MM-dd').format(date);
  } else if (_selectedDate != null) {
    dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }
  
  // 處理 userId，如果為 null (訪客模式)，則設為 0 (與後端 /get_products/0 對應)
  final userIdToFetch = widget.userId ?? 0;

  try {
    // 呼叫新的 API 服務函式
    final fetchedProducts = await fetchHistoryProducts(
      userIdToFetch, 
      widget.token, // 傳遞 Token
      dateString: dateString // 傳遞日期篩選條件
    );

    if (mounted) {
      setState(() {
        products = fetchedProducts; 
        isLoading = false;
      });
    }

  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
        // 可以在這裡顯示錯誤訊息給使用者
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('歷史紀錄載入失敗，請檢查網路'), backgroundColor: _kAccentRed),
        );
      });
    }
    print("Error fetching history: $e");
  }
}

  // 🎯 這裡是用戶要求的修改：加入確認對話框的刪除功能
  void _deleteHistoryItem(int productId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: const Text('您確定要刪除這筆歷史紀錄嗎？此操作不可復原。'),
          actions: <Widget>[
            // 取消按鈕
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 關閉對話框
              },
              child: const Text('取消', style: TextStyle(color: _kPrimaryGreen)),
            ),
            // 確認刪除按鈕
            TextButton(
              onPressed: () {
                // 執行刪除邏輯
                if (mounted) {
                  setState(() {
                    products.removeAt(index);
                  });
                }
                
                // 這裡應該呼叫 API 進行實際刪除 (例如 deleteProduct(productId, widget.token))

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('商品已移除: $productId'), duration: const Duration(seconds: 1)),
                );
                Navigator.of(context).pop(); // 關閉對話框
              },
              child: const Text('確認刪除', style: TextStyle(color: _kAccentRed)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // 💡 顯示當前選定的日期，若無則顯示 '掃描歷史記錄'
    String titleText = _selectedDate == null 
        ? '掃描歷史記錄' 
        : DateFormat('yyyy/MM/dd').format(_selectedDate!);

    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
        // 移除 AppBar，使用自定義的導航結構以符合設計圖的簡潔風格
        automaticallyImplyLeading: false, // 隱藏預設返回按鈕
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部導航欄 (返回鍵 + 掃描圖示)
            _buildCustomHeader(context),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // 標題 (顯示日期或預設文字)
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryGreen, // 標題顏色使用主色調
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // 搜尋欄
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildSearchBar(context),
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // 歷史記錄列表
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

  // --- UI Helper 函式 ---

  // 依設計圖重新構建的頂部 Header (保持不變)
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
  
  // 💡 修改：搜尋欄位 Helper (加入日曆按鈕)
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
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // 💡 變更：右側圖標改為日曆，並加上點擊事件
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

  // 歷史記錄單一卡片 Helper (保持不變)
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product, int index) {
    // 假設 product['Market'] 包含 '家樂福' 和 '內壢店'
    final marketParts = (product['Market'] as String? ?? '未知超市|未知分店').split('|');
    final market = marketParts[0];
    final branch = marketParts.length > 1 ? marketParts[1] : '分店';

    final scanDate = product['ScanDate'] ?? '-'; // 👈 讀取後端回傳的完整時間字串
    final expireDate = product['ExpireDate'] ?? '-';
    
    // 價格和有效期限
    final originalPrice = product['OriginalPrice'] ?? 'N/A'; // 👈 讀取 'OriginalPrice'
    final immediatePrice = product['ImmediatePrice'] ?? 'N/A'; // 👈 讀取 'ImmediatePrice' (原資料庫 ProPrice)
    final suggestedPrice = product['SuggestedPrice'] ?? 'N/A'; // 👈 讀取 'SuggestedPrice' (原資料庫 AIPrice)

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: _kCardBg, // 淺綠色卡片背景
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
          // 商品圖片 + 超市分店
          SizedBox(
            width: 80,
            child: Column(
              children: [
                // 圖片 placeholder (可替換為 NetworkImage)
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                    image: const DecorationImage(
                      // 如果有 ImageUrl 可以改成 NetworkImage(product['ImageUrl'])
                      image: AssetImage('assets/milk.jpg'), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  market,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  branch,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // 商品資訊 (名稱, 時間, 價格)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['ProName'] ?? '未知商品',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                _buildInfoRow('掃描時間', scanDate),      // 👈 這裡的文字會自動換行
                        _buildInfoRow('有效期限', expireDate),

                //關鍵修改：使用新的價格變數
                _buildPriceRow('原價', '\$$originalPrice', isOriginal: true), 
                _buildPriceRow('即期價格', '\$$immediatePrice', isOriginal: true),
                _buildPriceRow('AI定價', '\$$suggestedPrice', isOriginal: false), // AI定價使用紅色突出
              ],
            ),
          ),


          // 刪除按鈕
          GestureDetector(
            // 🎯 點擊時會觸發帶有確認對話框的 _deleteHistoryItem
            onTap: () => _deleteHistoryItem(product['ProId'] ?? -1, index),
            child: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.delete_outline, color: _kAccentRed, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // 資訊行 Helper (保持不變)
  // 資訊行 Helper (修改為可換行)
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 確保行從頂部對齊
      children: [
        // 標籤 (e.g., '掃描時間:') 保持固定寬度
        Text(
          '$label:', 
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(width: 5),
        // 數值 (e.g., '2025-10-06 23:39:06') 設置為 Expanded 以允許換行
        Expanded( // 👈 關鍵：使用 Expanded 讓 Text 佔用剩餘空間並換行
          child: Text(
            value, 
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            // maxLines: 2, // 如果需要，可以限制行數
            // overflow: TextOverflow.ellipsis, // 如果超過行數顯示省略號
          ),
        ),
      ],
    ),
  );
}

  // 價格行 Helper (保持不變)
  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isOriginal ? Colors.black54 : _kAccentRed, // 建議價格使用紅色
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: 14
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