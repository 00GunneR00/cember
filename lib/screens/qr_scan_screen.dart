import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/api_client.dart';
import '../core/invite_links.dart';
import '../core/token_store.dart';
import '../data/invite_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/invite_join.dart';
import 'circle_detail_screen.dart';

/// Opened from "QR ile Katıl" on Albümler — scans a host's invite QR and joins that circle
/// as a guest, mirroring the join flow already used from Keşfet.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, required this.apiClient, this.repository, this.tokenStore = const TokenStore(), this.defaultDisplayName = ''});

  final ApiClient apiClient;
  final InviteRepository? repository;
  final TokenStore tokenStore;
  final String defaultDisplayName;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final InviteJoiner _joiner = InviteJoiner(apiClient: widget.apiClient, repository: widget.repository, tokenStore: widget.tokenStore);
  final MobileScannerController _scannerController = MobileScannerController();

  bool _handlingDetection = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingDetection) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final token = extractInviteToken(raw);
    if (token == null || token.isEmpty) return;

    setState(() => _handlingDetection = true);
    await _scannerController.stop();

    try {
      final preview = await _joiner.preview(token);
      if (!mounted) return;
      final displayName = await _joiner.askDisplayName(context, preview, defaultDisplayName: widget.defaultDisplayName);
      if (displayName == null) {
        await _resumeScanning();
        return;
      }
      await _join(token, displayName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu QR kod geçerli bir davet değil.')));
      await _resumeScanning();
    }
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    setState(() => _handlingDetection = false);
    await _scannerController.start();
  }

  Future<void> _join(String token, String displayName) async {
    try {
      final joined = await _joiner.join(token, displayName);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CircleDetailScreen(circleId: joined.circleId, apiClient: joined.guestClient),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çembere katılamadın, tekrar dene.')));
      await _resumeScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('QR ile Katıl', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: colors.secondary, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            child: Text(
              'Bir çemberin davet karekodunu kareye hizala.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
            ),
          ),
          if (_handlingDetection)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
