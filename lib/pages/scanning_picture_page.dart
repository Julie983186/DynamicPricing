import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
  late Future<CameraController> _cameraControllerFuture;
  late AnimationController _animationController;
  bool _isFlashing = false;
  bool _isUploading = false;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/scan');
    _cameraControllerFuture = _initCameraController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<CameraController> _initCameraController() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxContentWidth = 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: SizedBox(
          width: screenWidth > maxContentWidth ? maxContentWidth : screenWidth,
          child: Image.asset(
            'assets/logo.png',
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
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
                  child: FutureBuilder<CameraController>(
                    future: _cameraControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text("無法初始化相機"));
                      }
                      final controller = snapshot.data!;
                      return _buildOverlayStack(controller);
                    },
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
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        if (widget.userId != null) {
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
                                          builder: (_) =>
                                              const RegisterLoginPage(),
                                        ),
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
              Expanded(child: _buildStoreDropdown()),
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

  Widget _buildOverlayStack(CameraController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        _buildScanMask(),
        _buildScanLine(),
        _buildHintText(), // 文字置中
        if (_isFlashing) Container(color: Colors.white.withOpacity(0.7)),
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

  // 修改 _buildHintText() 文字置中
  Widget _buildHintText() {
    return const Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Text(
        '請對準產品名稱、價格與有效期限',
        textAlign: TextAlign.center,
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
        child: FutureBuilder<CameraController>(
          future: _cameraControllerFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _takePicture(snapshot.data!),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                  color: Colors.green,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 30),
              ),
            );
          },
        ),
      ),
    );
  }

  void _takePicture(CameraController controller) async {
    try {
      _animationController.stop();
      setState(() => _isFlashing = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _isFlashing = false);

      final image = await controller.takePicture();
      print('照片已儲存至: ${image.path}');

      setState(() => _isUploading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isUploading = false);

      if (!mounted) return;
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
      _animationController.repeat(reverse: true);
    }
  }
}
