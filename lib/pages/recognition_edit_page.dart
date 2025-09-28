import 'package:flutter/material.dart';

class RecognitionEditPage extends StatefulWidget {
  const RecognitionEditPage({super.key});

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

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

            const SizedBox(height: 30),

            // 商品名稱 & 有效期限
            // 商品名稱 & 有效期限
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 商品名稱label
                  const Text(
                    "商品名稱：",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),

                  // 輸入欄位
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 1), 
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 1), 
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 有效期限label
                  const Text(
                    "有效期限：",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),

                  // 日付入力
                  SizedBox(
                    width: 250,
                    child: GestureDetector(
                      onTap: () => _pickDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${_selectedDate.toLocal()}".split(' ')[0],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 送出 & 重新掃描
            Column(
              children: [
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/counting');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Color(0xFF274E13), width: 1),
                        ),
                      ),
                      child: const Text("送出", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

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