import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/route_logger.dart';


class ScanningPicturePage extends StatefulWidget {
  const ScanningPicturePage({Key? key}) : super(key: key);

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isCameraInitialized = false;
  String? _selectedStore; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimation();
    saveCurrentRoute('/scan');
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('沒有可用的相機');
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      print('相機初始化錯誤: $e');
    }
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox(
      height: 100, // 調整 Logo 的高度，使其更平衡
      width: double.infinity, // 保持與主要內容區塊對齊
      child: Image.asset(
        'assets/logo.png', // 確保這是你的 Logo 圖片正確路徑
        fit: BoxFit.fitWidth, // 改用 fitWidth，讓圖片盡可能佔滿寬度
      ) 
    );
  }
  
  // 點擊頭像後彈出的提示方框
  void _showGuestUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加入會員'),
          content: const Text('您目前以訪客身份使用。加入會員可以享有更多專屬服務!是否現在註冊？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 關閉對話框
              },
              child: const Text('保持訪客', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 關閉對話框
                // 導航到註冊畫面。請將 '/register' 替換為您的實際註冊頁面路由
                Navigator.pushNamed(context, '/login'); 
              },
              child: const Text('加入會員', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    const double maxContentWidth = 400; // 主要內容區域的最大寬度

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top), 
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // 頂部間距已移除
                _buildLogo(), // Logo 放置在 body 的最頂部
                // 調整後的 Logo 下方間距
                const SizedBox(height: 5), 
                _buildTopUI(), // 頁面上方 UI (包含會員/訪客頭像與賣場選擇下拉選單)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cameraController != null && _cameraController!.value.isInitialized)
                        CameraPreview(_cameraController!),
                      _buildOverlay(),
                    ],
                  ),
                ),
                _buildBottomUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 頁面上方 UI
  Widget _buildTopUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 左右 padding
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側的會員/訪客頭像和名稱
              GestureDetector(
                onTap: _showGuestUpgradeDialog, 
                child: Column(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 25),
                    ),
                    const Text('訪客', style: TextStyle(color: Color(0xFF388E3C), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // 右側的賣場選擇區
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCurrentStoreInfo(),
        ],
      ),
    );
  }
  
  // 賣場選擇下拉式選單
  Widget _buildStoreDropdown() {
    final List<String> stores = ['家樂福', '全聯', '愛買'];

    // 調整高度
    const double dropdownHeight = 45; 

    return Container(
      height: dropdownHeight, // 限制容器高度
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStore,
          hint: const Text('請選擇賣場', style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          isDense: true, 
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStore = newValue;
            });
          },
          items: stores.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 目前賣場資訊
  Widget _buildCurrentStoreInfo() {
    return Text(
      _selectedStore != null ? '目前賣場：$_selectedStore' : '尚未選擇賣場',
      style: const TextStyle(
        color: Color.fromARGB(221, 239, 41, 41),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  // 疊加在相機預覽上的 UI
  Widget _buildOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
      ],
    );
  }

  // 掃描框遮罩
  Widget _buildScanMask() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        const Color(0xFFE8F5E9).withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 320,
                height: 900,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 掃描線動畫
  Widget _buildScanLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const double scanLineWidth = 320 * 0.8;
          return Transform.translate(
            offset: Offset(0, -125 + _animationController.value * 250),
            child: Container(
              width: scanLineWidth,
              height: 3,
              color: Colors.greenAccent,
            ),
          );
        },
      ),
    );
  }

  // 引導文字
  Widget _buildHintText() {
    return const Positioned(
      top: 20,
      child: Text(
        '請對準產品名稱、價格與有效期限',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // 頁面下方 UI (拍照按鈕)
  Widget _buildBottomUI() {
    // 拍照按鈕區域的垂直 Padding 已經被調整為 5
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 5), // 原為 10
      child: Center(
        child: GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.green,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  // 拍照功能
  void _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) {
      print('相機尚未初始化或不可用');
      return;
    }
    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      
      if (!mounted) {
        return;
      }
      print('照片已儲存至: ${image.path}');
      
      await _uploadImage(image.path);
      
    } catch (e) {
      print('拍照失敗: $e');
    }
  }

  // 圖片上傳功能（假想）
  Future<void> _uploadImage(String imagePath) async {
    print('正在將照片上傳至假想後端API...');
    try {
      await Future.delayed(const Duration(seconds: 2));
      print('照片上傳成功！');

      // 上傳完成後 → 跳到辨識 Loading 頁
      if (!mounted) return;
      Navigator.pushNamed(context, '/loading');
    } catch (e) {
      print('照片上傳失敗: $e');
    }
  }
}