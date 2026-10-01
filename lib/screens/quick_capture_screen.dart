import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/upload_policy.dart';
import '../data/http/http_upload_repository.dart';
import '../data/upload_repository.dart';
import '../models/brand_profile.dart';
import '../models/photo_source.dart';
import '../theme/app_theme.dart';

/// Instagram "Şipşak" style instant capture: open the live camera, tap to shoot,
/// and the photo uploads the moment it's taken — no gallery, no review-and-send step.
class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({
    super.key,
    required this.circleId,
    this.uploadRepository = const MockUploadRepository(),
    this.apiClient,
    this.brand,
  });

  final String circleId;
  final UploadRepository uploadRepository;
  final ApiClient? apiClient;

  /// Non-null when this circle is a branded circle — shows a commercial-use consent toggle.
  final BrandProfile? brand;

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen>
    with WidgetsBindingObserver {
  late final UploadRepository _effectiveRepository = widget.apiClient != null
      ? HttpUploadRepository(widget.apiClient!)
      : widget.uploadRepository;

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;
  bool _showFlash = false;
  int _pendingUploads = 0;
  int _uploadedCount = 0;
  bool _commercialConsentAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(_cameraIndex);
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'Bu cihazda kullanılabilir bir kamera bulunamadı.';
          _initializing = false;
        });
        return;
      }
      await _startController(_cameraIndex);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Kameraya erişilemedi. Ayarlardan kamera iznini kontrol et.';
        _initializing = false;
      });
    }
  }

  Future<void> _startController(int index) async {
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Kameraya erişilemedi. Ayarlardan kamera iznini kontrol et.';
        _initializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    setState(() => _initializing = true);
    await _startController(_cameraIndex);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashMode = next);
    } catch (_) {
      // Some devices/cameras don't support torch — ignore, the toggle just stays off.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _showFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _showFlash = false);
    });

    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _pendingUploads++;
      });
      _uploadImmediately(file);
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf çekilemedi, tekrar dene.')),
      );
    }
  }

  void _uploadImmediately(XFile file) {
    _effectiveRepository
        .uploadPhotos(
          widget.circleId,
          [file],
          source: PhotoSource.quickCapture,
          commercialConsent: _commercialConsentAccepted,
        )
        .listen(
          (progress) {
            if (!progress.done || !mounted) return;
            setState(() {
              _pendingUploads--;
              _uploadedCount++;
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() => _pendingUploads--);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e is WifiRequiredException ? WifiRequiredException.message : 'Bir fotoğraf gönderilemedi.'),
              ),
            );
          },
        );
  }

  void _done() => Navigator.of(context).pop(_uploadedCount > 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography,
                      color: Colors.white70,
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _initCamera,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            Center(child: CameraPreview(_controller!)),
          if (_showFlash) const ColoredBox(color: Colors.white),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    _RoundIconButton(icon: Icons.close, onTap: _done),
                    if (widget.brand != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _ConsentToggleChip(
                        brand: widget.brand!,
                        value: _commercialConsentAccepted,
                        onTap: () => setState(() => _commercialConsentAccepted = !_commercialConsentAccepted),
                      ),
                    ],
                    const Spacer(),
                    if (_pendingUploads > 0)
                      _StatusChip(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Gönderiliyor...',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_uploadedCount > 0)
                      _StatusChip(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_uploadedCount gönderildi',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    _RoundIconButton(
                      icon: _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_cameras.length > 1)
            Positioned(
              right: AppSpacing.marginMobile,
              bottom: 148,
              child: _RoundIconButton(
                icon: Icons.cameraswitch,
                onTap: _switchCamera,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: _capturing ? 52 : 60,
                          height: _capturing ? 52 : 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ConsentToggleChip extends StatelessWidget {
  const _ConsentToggleChip({required this.brand, required this.value, required this.onTap});

  final BrandProfile brand;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? brand.primaryColor : Colors.black45,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_circle : Icons.campaign_outlined, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text('${brand.name} kullanımına izin ver', style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: child,
    );
  }
}
