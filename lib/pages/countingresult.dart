import 'dart:io';
import 'package:flutter/material.dart';
import 'adviceproduct.dart';
import '../services/route_logger.dart';
import 'register_login_page.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import '../services/api_service.dart';

class CountingResult extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;
  final bool autoUpdateAIPrice;

  const CountingResult({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
    this.autoUpdateAIPrice = false,
  });

  @override
  State<CountingResult> createState() => _CountingResultState();
}

class _CountingResultState extends State<CountingResult> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  bool _hasShownGuestDialog = false;

  double? AiPrice;
  int? productId;
  String? reason;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/countingResult');

    final info = widget.productInfo ?? {};
    productId = info["ProductID"];
    reason = info["Reason"];
    AiPrice = (info["AiPrice"] != null)
        ? double.tryParse(info["AiPrice"].toString())
        : null;

    if (widget.autoUpdateAIPrice && productId != null) {
      _fetchAIPrice();
    }
  }

  bool _isGuest() => widget.userId == null || widget.token == null;

  Future<void> _discardScanRecord() async {
    // 可留空
  }

  /// 訪客按「再次掃描」時提示登入或保留
  void _showGuestDialog() {
    if (_hasShownGuestDialog) return;
    _hasShownGuestDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("提示"),
          content: const Text(
              "您目前是訪客，要不要保留這筆掃描紀錄？若要保留需要先登入"),
          actions: [
            TextButton(
              child: const Text("不保留"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _discardScanRecord();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanningPicturePage(),
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              child: const Text("保留"),
              onPressed: () async {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterLoginPage(
                      returnRoute: '/member_history',
                      returnAction: "saveRecord",
                      returnArgs: {
                        "productId": productId,
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    ).then((_) => _hasShownGuestDialog = false);
  }

  /// 已登入會員按下會員圖示但未登入
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("需要登入"),
          content: const Text("請先登入會員以使用此功能"),
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("登入/註冊"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterLoginPage(
                      returnRoute: '/member_profile',
                      returnAction: null, // 可以保留
                      returnArgs: {},
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAIPrice() async {
    if (productId == null) return;
    final value = await fetchAIPrice(productId!);
    if (mounted && value != null) {
      setState(() {
        AiPrice = value;
      });
    }
  }

  Color getReasonColor(String? reason) {
    if (reason == "合理") return Colors.green;
    if (reason == "不合理") return Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.productInfo ?? {};
    final name = info["ProName"] ?? "未知商品";
    final expireDate = info["ExpireDate"] ?? "未知日期";
    final price = info["Price"]?.toString() ?? "未知";
    final proPrice = info["ProPrice"]?.toString() ?? "未知";

    return Scaffold(
      backgroundColor: _standardBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 250),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 左側會員圖示
                        InkWell(
                          onTap: () {
                            if (_isGuest()) {
                              _showLoginRequiredDialog();
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/member_profile',
                                arguments: {
                                  'userId': widget.userId,
                                  'userName': widget.userName,
                                  'token': widget.token,
                                },
                              );
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF388E3C).withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_circle,
                                    color: Colors.white, size: 25),
                              ),
                              Text(
                                _isGuest()
                                    ? "訪客"
                                    : (widget.userName ?? "會員"),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // LOGO
                        Image.asset('assets/logo.png', height: 90, fit: BoxFit.contain),

                        // 再次掃描
                        InkWell(
                          onTap: () {
                            if (_isGuest()) {
                              _showGuestDialog();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScanningPicturePage(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Icon(
                            Icons.fullscreen,
                            size: 30,
                            color: Color.fromARGB(221, 38, 92, 31),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 商品卡片
                  Container(
                    width: 330,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (widget.imagePath != null)
                          Container(
                            width: 220,
                            height: 200,
                            child: Image.file(File(widget.imagePath!), fit: BoxFit.contain),
                          ),
                        const SizedBox(height: 12),
                        Text("商品名稱：$name",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text("有效期限：$expireDate", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("原價：\$$price", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("即期價格：\$$proPrice", style: const TextStyle(fontSize: 16, color: Colors.red)),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildPriceBox("即期價格", "\$$proPrice", isDiscount: false),
                            buildPriceBox(
                              "AI定價",
                              AiPrice != null ? "\$${AiPrice!.toInt()}" : "計算中…",
                              isDiscount: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (reason != null)
                          Text(
                            reason == "合理"
                                ? "✅ 價格落於合理範圍"
                                : "❗ 價格不合理，建議勿購買",
                            style: TextStyle(
                              color: getReasonColor(reason),
                              fontSize: 18,
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

            // 推薦商品
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              maxChildSize: 0.85,
              minChildSize: 0.15,
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
                  child: AdviceProductList(
                    scrollController: scrollController,
                    productId: productId,
                    reason: reason,
                  ),
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
            Text(title,
                style: TextStyle(fontSize: isDiscount ? 16 : 18, fontWeight: FontWeight.w600)),
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
