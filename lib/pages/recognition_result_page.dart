import 'package:flutter/material.dart';

class RecognitionResultPage extends StatelessWidget {
  const RecognitionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // LOGO
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 140,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 商品圖像
            Center(
              child: Image.asset(
                'assets/milk.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // 商品資訊
            const Text(
              "商品名稱：瑞穂鮮乳-全脂290ml\n有效期限：2025-05-30",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              "商品名稱及有效期限是否正確？",
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // 按鈕區
            Column(
              children: [
                // 正確
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/counting');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF274E13), width: 1),
                        ),
                      ),
                      child: const Text("正確", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 手動修改
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF274E13), width: 1),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text("手動修改",
                          style: TextStyle(fontSize: 18, color: Color(0xFF274E13))),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 重新掃描
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/scan');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF274E13), width: 1),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text("重新掃描",
                          style: TextStyle(fontSize: 18, color: Color(0xFF274E13))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}