import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';

class StickerCameraResult {
  final String? imagePath;
  final bool enterManually;

  const StickerCameraResult({
    this.imagePath,
    this.enterManually = false,
  });
}

class StickerCameraScreen extends StatefulWidget {
  const StickerCameraScreen({super.key});

  @override
  State<StickerCameraScreen> createState() => _StickerCameraScreenState();
}

class _StickerCameraScreenState extends State<StickerCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        final backCam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        final controller = CameraController(
          backCam,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization info: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      if (_cameraController != null && _isCameraInitialized) {
        final file = await _cameraController!.takePicture();
        if (mounted) {
          Navigator.of(context).pop(StickerCameraResult(imagePath: file.path));
        }
      } else {
        // Fallback for desktop/simulators without direct camera feed
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 90,
        );
        if (picked != null && mounted) {
          Navigator.of(context).pop(StickerCameraResult(imagePath: picked.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      Navigator.of(context).pop(StickerCameraResult(imagePath: picked.path));
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newMode);
        setState(() => _isFlashOn = !_isFlashOn);
      } catch (e) {
        debugPrint('Flash toggle error: $e');
      }
    } else {
      setState(() => _isFlashOn = !_isFlashOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final viewfinderWidth = screenSize.width * 0.85;
    final viewfinderHeight = viewfinderWidth * 0.58; // Standard sticker aspect ratio

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera View or Stylized Fallback Surface
            if (_cameraController != null && _isCameraInitialized)
              Center(
                child: CameraPreview(_cameraController!),
              )
            else
              Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Align laptop label inside the frame',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Viewfinder Overlay Mask with Cutout
            Center(
              child: SizedBox(
                width: viewfinderWidth,
                height: viewfinderHeight,
                child: CustomPaint(
                  painter: ViewfinderBracketsPainter(
                    color: const Color(0xFF14B8A6), // Vibrant teal / cyan
                    cornerLength: 30.0,
                    strokeWidth: 3.5,
                    borderRadius: 8.0,
                  ),
                ),
              ),
            ),

            // 3. Guidance Text below Viewfinder
            Positioned(
              left: 0,
              right: 0,
              top: (screenSize.height / 2) + (viewfinderHeight / 2) + 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Keep the sticker clear and in focus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Top Navigation Bar (Back, Title, Flash toggle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.black.withValues(alpha: 0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Scan label',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.amber : Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),

            // 5. Bottom Controls (Gallery, Shutter Button, Enter Manually)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Gallery button
                        IconButton(
                          onPressed: _pickFromGallery,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Choose from gallery',
                        ),

                        // Center: Large circular shutter button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF14B8A6),
                                width: 3.5,
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: _isCapturing
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        // Right: Spacer to keep shutter centered
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Bottom: Enter details manually link
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          const StickerCameraResult(enterManually: true),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Enter details manually',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
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
}

class ViewfinderBracketsPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  ViewfinderBracketsPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final l = cornerLength;

    // Top-Left corner
    final pathTL = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right corner
    final pathTR = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left corner
    final pathBL = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(l, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right corner
    final pathBR = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - l);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
