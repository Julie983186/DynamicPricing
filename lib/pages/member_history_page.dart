import 'package:flutter/material.dart';

class MemberHistoryPage extends StatelessWidget {
  const MemberHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 淺綠色背景
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 讓 AppBar 背景透明
        elevation: 0, // 移除 AppBar 的陰影
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)), // 返回箭頭顏色
        title: const Text(
          '', // 不顯示 AppBar 標題
          style: TextStyle(color: Color(0xFF388E3C)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部搜尋欄與月曆圖示
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildSearchBar(context),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 標題 (往下移動一點)
              const SizedBox(height: 10),
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ListView(
                      children: [
                        _buildHistoryCard(context),
                        const SizedBox(height: 15),
                        _buildHistoryCard(context),
                        const SizedBox(height: 15),
                        _buildHistoryCard(context),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 輔助方法：創建搜尋欄
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
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // 月曆圖示
          GestureDetector(
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              ).then((pickedDate) {
                if (pickedDate != null) {
                  print('選擇的日期: ${pickedDate.toString()}');
                }
              });
            },
            child: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 輔助方法：創建歷史記錄卡片
  Widget _buildHistoryCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
              // 商品圖片和掃描地點資訊
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: constraints.maxWidth * 0.18,
                    height: constraints.maxWidth * 0.25,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '家樂福',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const Text(
                    '內壢店',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '瑞穗鮮乳-全脂290ml',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _buildInfoRow('掃描時間', '2025/05/28 14:32'),
                    _buildInfoRow('有效期限', '2025/05/30'),
                    const SizedBox(height: 5),
                    _buildPriceRow('原價', '\$100', isOriginal: true),
                    _buildPriceRow('建議價格', '\$55', isOriginal: false),
                  ],
                ),
              ),
              
              // 刪除圖示（可點擊）
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
      },
    );
  }
  
  // 輔助方法：創建資訊行
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

  // 輔助方法：創建價格行
  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(
            color: isOriginal ? Colors.black54 : Colors.green[700],
            fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
          )),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(
            color: isOriginal ? Colors.black87 : Colors.red,
            fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
            fontSize: isOriginal ? 14 : 16,
          )),
        ],
      ),
    );
  }
}