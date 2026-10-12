import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';


/// InAppCameraPage
/// - Return File? via Navigator.pop(context, File)
/// - Features: switch camera (front/back), flash modes (off/auto/on),
///   take picture, retake, use photo
class InAppCameraPage extends StatefulWidget {
  final CameraLensDirection preferredLensDirection;
  const InAppCameraPage({super.key, this.preferredLensDirection = CameraLensDirection.back});

  /// Usage:
  /// final File? file = await Navigator.push(context, MaterialPageRoute(builder: (_) => const InAppCameraPage()));
  @override
  State<InAppCameraPage> createState() => _InAppCameraPageState();
}

class _InAppCameraPageState extends State<InAppCameraPage> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _initialized = false;
  bool _isTakingPicture = false;
  File? _capturedFile;

  /// flash state cycle: off -> auto -> always
  FlashMode _flashMode = FlashMode.off;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // handle app lifecycle to pause/resume camera
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      final cams = await availableCameras();
      if (!mounted) return;
      setState(() => _cameras = cams);

      if (_cameras.isNotEmpty) {
        final preferredIndex = _cameras.indexWhere(
          (cam) => cam.lensDirection == widget.preferredLensDirection,
        );
        _cameraIndex = preferredIndex >= 0 ? preferredIndex : 0;
        await _onNewCameraSelected(_cameras[_cameraIndex]);
      }
    } catch (e, st) {
      debugPrint('Error initializing cameras: $e\n$st');
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final previous = _controller;

    setState(() {
      _controller = null;
      _initialized= false;
    });

    if (previous != null) {
      await previous.dispose();
      await Future.delayed(Duration(milliseconds: 200));
    }

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      // set last known flash mode (best effort)
      await controller.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Camera initialize error: $e');
    }

    if (!mounted) return;
    setState(() {
      _initialized = controller.value.isInitialized;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _onNewCameraSelected(_cameras[_cameraIndex]);
  }

  Future<void> _cycleFlashMode() async {
    // cycle: off -> auto -> always
    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      _flashMode = FlashMode.always;
    } else {
      _flashMode = FlashMode.off;
    }

    try {
      await _controller?.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
    setState(() {});
  }

  IconData _flashIconFor(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  String _flashLabelFor(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      case FlashMode.off:
      default:
        return 'Off';
    }
  }

  Future<File?> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return null;

    setState(() => _isTakingPicture = true);
    try {
      // ensure directory exists - camera plugin returns XFile already in temp
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      img.Image image = img.decodeImage(bytes)!;

      if(_cameras[_cameraIndex].lensDirection == CameraLensDirection.front) {
        image = img.flipHorizontal(image);
      }
      final flippedFile = File(file.path)..writeAsBytesSync(img.encodeJpg(image));
      int targetHeight = (image.width * 3 / 4).toInt();
      if(targetHeight > image.height) {
        int targetWidth = (image.height * 3 / 4).toInt();
        int xOffset = (image.width - targetWidth) ~/2;
        final cropped = img.copyCrop(image, x: xOffset, y: 0, width: targetWidth, height: image.height);
        await File(flippedFile.path).writeAsBytes(img.encodeJpg(cropped));
      } else {
        int yOffset = (image.height - targetHeight) ~/2;
        final cropped = img.copyCrop(image, x: 0, y: yOffset, width: image.width, height: targetHeight);
        await File(flippedFile.path).writeAsBytes(img.encodeJpg(cropped));
      }
      // optionally move to app directory (kept in temp by default)
      // final saved = await _saveFileToAppDir(file);
      // For simplicity, return the file directly
      return flippedFile;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview or captured image
        Positioned.fill(
          child: _capturedFile == null 
          ? Center(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),
            )
          : _buildCapturedPreview(),
        ),

        // Top controls
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // close
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                icon: Icon(Icons.close, color: Colors.white, size: 32),
              ),

              // flash + switch camera
              Row(
                children: [
                  _capturedFile == null
                  ? IconButton(
                      onPressed: _cycleFlashMode,
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_flashIconFor(_flashMode), color: Colors.white),
                          Text(_flashLabelFor(_flashMode), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    )
                  : SizedBox(),
                  if (_capturedFile == null && _cameras.length > 1)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _capturedFile == null ? _captureControls(context) : _captureConfirmControls(context),
        ),
      ],
    );
  }

  Widget _buildCapturedPreview() {
    return Center(
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: Image.file(
                File(_capturedFile!.path),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _captureControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // capture button
              GestureDetector(
                onTap: () async {
                  final file = await _takePicture();
                  if (file != null) {
                    // show captured preview
                    setState(() => _capturedFile = file);
                    // pause preview (optional)
                    try {
                      await _controller?.pausePreview();
                    } catch (_) {}
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white24,
                  ),
                  child: _isTakingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _captureConfirmControls(BuildContext context) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Retake
          IconButton(
            onPressed: () async {
              setState(() => _capturedFile = null);
              try {
                await _controller?.resumePreview();
              } catch (_) {}
              await Future.delayed(Duration(milliseconds: 100));
              _onNewCameraSelected(_cameras[_cameraIndex]);
            },
            icon: Icon(Icons.refresh, color: Colors.white, size: 32),
          ),

          // Use Photo (return file)
          IconButton(
            onPressed: () async {
              if (_capturedFile != null) {
                final extension = p.extension(_capturedFile!.path);
                final targetPath = "${_capturedFile!.parent.path}/${DateTime.now().millisecondsSinceEpoch}$extension";
                final result = await FlutterImageCompress.compressAndGetFile(
                  _capturedFile!.absolute.path,
                  targetPath,
                  quality: 25
                );
                Navigator.of(context).pop(File(result!.path));
              } else {
                Navigator.of(context).pop(null);
              }
            },
            icon: Icon(Icons.check, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

