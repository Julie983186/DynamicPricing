import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class ScanningPicturePage extends StatefulWidget {
  const ScanningPicturePage({Key? key}) : super(key: key);

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isCameraInitialized = false;
  // 將 _selectedStore 的初始值設為 null，使其沒有預設選項
  String? _selectedStore; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimation();
  }

  // 初始化相機
  // 此方法會取得可用的相機，並初始化 CameraController
  // 確保相機在頁面載入時已準備好進行預覽
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('沒有可用的相機');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
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

  // 初始化掃描框動畫
  // 負責創建一個 AnimationController，用於控制掃描線的上下移動
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

  // 頁面主體 UI
  // 負責建構整個頁面的視覺佈局
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
    
    const double maxContentWidth = 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'LOGO',
          style: TextStyle(
            color: Color(0xFF388E3C),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
        centerTitle: true,
        // 設置此屬性為 false，才能強制移除返回鍵
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _buildTopUI(),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 鏡頭即時預覽
                      CameraPreview(_cameraController!),
                      // 疊加UI (掃描框、文字)
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
  // 包含會員/訪客頭像與賣場選擇下拉選單
  // 頁面上方 UI
Widget _buildTopUI() {
  return Container(
    color: const Color(0xFFE8F5E9),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column( // 將 Row 改為 Column，以便垂直排列
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 確保元素靠上對齊
          children: [
            // 左側的會員/訪客頭像和名稱
            GestureDetector(
              onTap: () {
                print('頭像被點擊');
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
        // 將 _buildCurrentStoreInfo() 從 Expanded 外部移出，並用 Center 包住
        const SizedBox(height: 10),
        _buildCurrentStoreInfo(),
      ],
    ),
  );
}
  
  // 賣場選擇下拉式選單
  Widget _buildStoreDropdown() {
    // 定義選項列表
    final List<String> stores = ['家樂福', '全聯', '愛買'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // 將 value 設為 _selectedStore
          value: _selectedStore,
          // 新增 hint 屬性作為提示文字
          hint: const Text('請選擇賣場', style: TextStyle(color: Colors.grey)),
          isExpanded: true,
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
  // 包含掃描框、掃描線和提示文字
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
  // 創建一個帶有透明中心矩形的遮罩，用於突出顯示掃描區域
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
                // 調整掃描框的高度，使其變長
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
  // 創建一條上下移動的掃描線，模擬掃描過程
  Widget _buildScanLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const double scanLineWidth = 320 * 0.8;
          // 根據動畫值計算掃描線的 Y 軸位移
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
  // 提醒使用者如何對準商品資訊
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
  // 提供一個可點擊的圓形按鈕來觸發拍照功能
  Widget _buildBottomUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: GestureDetector(
          onTap: _takePicture,
          child: Container(
            // 調整按鈕的尺寸，使其變小
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
  // 呼叫相機控制器的 takePicture() 方法來拍照
  void _takePicture() async {
    if (!_isCameraInitialized) {
      print('相機尚未初始化');
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
  // 模擬將照片上傳到後端 API 並接收結果
  Future<void> _uploadImage(String imagePath) async {
    print('正在將照片上傳至假想後端API...');
    try {
      await Future.delayed(const Duration(seconds: 2));
      print('照片上傳成功！');
      
      final mockApiResponse = {
        'status': 'success',
        'message': '圖片已成功處理',
        'data': {
          'product_name': '瑞穗鮮乳',
          'price': '65',
          'expiration_date': '2025-10-30',
        }
      };
      
      print('後端回傳結果: $mockApiResponse');
      
    } catch (e) {
      print('照片上傳失敗: $e');
    }
  }
}