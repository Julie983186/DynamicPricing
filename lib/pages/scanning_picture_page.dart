import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/route_logger.dart';
import 'recognition_loading_page.dart';
import 'member_profile_page.dart'; 
import 'register_login_page.dart';


class ScanningPicturePage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const ScanningPicturePage({
    Key? key,
    this.userId,
    this.userName,
    this.token,
  }) : super(key: key);

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isCameraInitialized = false;
  String? _selectedStore;

  // 拍照閃光效果
  bool _isFlashing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimation();
    saveCurrentRoute('/scan');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 👉 回到這頁時，如果相機被清掉就重新初始化
    if (_cameraController == null) {
      _initializeCamera();
    }
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
      if (!mounted) return;
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
        backgroundColor: Color(0xFFE8F5E9),
        centerTitle: true,
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

  Widget _buildTopUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 會員頭像改成 InkWell + Material
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        if (widget.userId != null) {
                          // 已登入 → 跳會員中心
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberProfilePage(
                                userId: widget.userId!,
                                userName: widget.userName ?? "會員",
                                token: widget.token ?? "",
                              ),
                            ),
                          );
                        } else {
                          // 訪客 → 顯示登入/註冊彈窗
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("需要登入"),
                                content: const Text("請先登入或註冊以使用會員功能"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("取消"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const RegisterLoginPage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text("登入/註冊"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_circle,
                            color: Colors.white, size: 25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userId != null ? widget.userName ?? "會員" : "訪客",
                    style: const TextStyle(
                        color: Color(0xFF388E3C), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 15),
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


  Widget _buildStoreDropdown() {
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
          value: _selectedStore,
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

  Widget _buildOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
        if (_isFlashing) Container(color: Colors.white.withOpacity(0.7)),
      ],
    );
  }

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

  Widget _buildBottomUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 10),
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
            child:
                const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  // 新增一個狀態
  bool _isUploading = false;

  Widget _buildOverlayStack() {
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
        if (_isFlashing)
          Container(color: Colors.white.withOpacity(0.7)),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  void _takePicture() async {
    if (!_isCameraInitialized || _cameraController!.value.isTakingPicture) return;

    try {
      // 停止掃描線 & 閃光效果
      _animationController.stop();
      setState(() => _isFlashing = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _isFlashing = false);

      // 拍照
      final image = await _cameraController!.takePicture();
      print('照片已儲存至: ${image.path}');

      if (!mounted) return;

      // 顯示 loading overlay
      setState(() => _isUploading = true);

      // 模擬上傳
      await Future.delayed(const Duration(seconds: 2));
      print('照片上傳成功！');

      if (!mounted) return;

      setState(() => _isUploading = false);

      // 導到 RecognitionLoadingPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionLoadingPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      print('拍照或上傳失敗: $e');
      setState(() => _isUploading = false);
    } finally {
      _animationController.repeat(reverse: true); // 拍完恢復掃描線
    }
  }
}
