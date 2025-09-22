import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../constants/colors.dart';
import '../services/qr_service.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String)? onQRCodeScanned;
  final String? title;
  final String? subtitle;

  const QRScannerScreen({
    Key? key,
    this.onQRCodeScanned,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _hasPermission = false;
  String? _errorMessage;
  bool _isProcessing = false;
  String? _lastScannedCode;
  bool _isFrontCamera = false;
  DateTime? _lastScanTime;
  QRCodeResult? _scanResult;
  Timer? _cameraHealthTimer;
  bool _isAutoFocusEnabled = true;
  bool _isAdaptiveScanningEnabled = true;
  Timer? _adaptiveScanTimer;
  int _scanAttempts = 0;
  double _currentZoom = 1.0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkCameraPermission();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkCameraPermission() async {
    try {
      var status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      setState(() {
        _hasPermission = status == PermissionStatus.granted;
        if (!_hasPermission) {
          if (status == PermissionStatus.permanentlyDenied) {
            _errorMessage =
                'Camera permission permanently denied. Please enable it in Settings.';
          } else if (status == PermissionStatus.denied) {
            _errorMessage = 'Camera permission is required to scan QR codes';
          } else {
            _errorMessage = 'Camera permission status: ${status.toString()}';
          }
        } else {
          _errorMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !_isProcessing) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _handleQRCodeDetected(barcode.rawValue!);
      }
    }
  }

  void _handleScanError(String errorMessage) {
    setState(() {
      _errorMessage = errorMessage;
      _isProcessing = false;
    });
  }

  void _setupCameraErrorHandling() {
    // Monitor camera state and handle disconnections
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _checkCameraHealth();
    });
  }

  void _checkCameraHealth() async {
    if (controller == null || !_hasPermission) return;

    // Camera health check - mobile_scanner handles this internally
    // Just check if controller is still valid
    if (!mounted) {
      return;
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = null;
      _hasPermission = false;
    });

    await _checkCameraPermission();

    if (_hasPermission && mounted) {
      // Recreate the QR view
      setState(() {});
    }
  }

  void _startAdaptiveScanning() {
    _adaptiveScanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _adaptLightingConditions();
    });
  }

  void _adaptLightingConditions() async {
    if (controller == null) return;

    try {
      // Adjust flash based on scan attempts
      if (_scanAttempts > 3 && !_isFlashOn) {
        await controller!.toggleTorch();
        setState(() {
          _isFlashOn = true;
        });
      }

      // Auto-focus periodically
      if (_isAutoFocusEnabled) {
        await controller.start();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Adaptive scanning error: $e');
      }
    }
  }

  void _showScanFeedback({required bool success, String? message}) {
    // Visual feedback
    setState(() {
      _scanResult = success ? _scanResult : null;
    });

    // Haptic feedback
    if (success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    // Audio feedback would go here if needed

    // Show snackbar for failed scans
    if (!success && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleQRCodeDetected(String qrCode) async {
    if (_isProcessing) return;

    // Prevent duplicate scans
    if (_lastScannedCode == qrCode &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 2)) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = qrCode;
      _lastScanTime = DateTime.now();
      _scanAttempts++;
    });

    try {
      // Provide haptic feedback
      await _triggerHapticFeedback();

      // Pause scanning temporarily
      await _pauseCameraWithRetry();

      // Process the QR code using QRService with timeout
      final result = await QRService.processQRCode(qrCode)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (result.isSuccess) {
          setState(() {
            _scanAttempts = 0; // Reset on successful scan
          });

          _showSuccessAnimation();

          // Show success feedback
          _showScanFeedback(success: true);

          // Call the callback if provided
          if (widget.onQRCodeScanned != null) {
            widget.onQRCodeScanned!(qrCode);
          } else {
            // Default behavior - show result based on type
            _handleQRResult(result);
          }
        } else {
          _showScanFeedback(
              success: false,
              message: result.errorMessage ?? 'Invalid QR Code');
          _showErrorDialog('Invalid QR Code',
              result.errorMessage ?? 'Unknown error occurred');
          await _resumeScanningWithDelay();
        }
      }
    } on TimeoutException {
      if (mounted) {
        _showScanFeedback(
            success: false, message: 'QR code processing timed out');
        _showErrorDialog(
            'Timeout Error', 'QR code processing timed out. Please try again.');
        await _resumeScanningWithDelay();
      }
    } catch (e) {
      if (mounted) {
        _showScanFeedback(success: false, message: 'Failed to process QR code');
        _showErrorDialog(
            'Scan Error', 'Failed to process QR code: ${e.toString()}');
        await _resumeScanningWithDelay();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pauseCameraWithRetry() async {
    try {
      await controller.stop();
    } catch (e) {
      debugPrint('Failed to pause camera: $e');
      // Continue without pausing if it fails
    }
  }

  Future<void> _resumeScanningWithDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      try {
        await controller.start();
      } catch (e) {
        debugPrint('Failed to resume camera: $e');
        setState(() {
          _errorMessage = 'Camera error: Failed to resume scanning';
        });
      }
    }
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Vibrate if available
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Ignore haptic feedback errors
      debugPrint('Haptic feedback error: $e');
    }
  }

  void _showSuccessAnimation() {
    _pulseController.stop();
    _pulseController.reset();
    _pulseController.forward();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        content: Text(message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                )),
          ),
        ],
      ),
    );
  }

  void _handleQRResult(QRCodeResult result) {
    switch (result.type!) {
      case QRCodeType.payment:
        _showPaymentQRResult(result.paymentData!);
        break;
      case QRCodeType.url:
        _showUrlQRResult(result.url!);
        break;
      case QRCodeType.text:
      case QRCodeType.json:
      default:
        _showGenericQRResult(result.data!);
        break;
    }
  }

  void _showPaymentQRResult(PaymentQRData paymentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Account Number', paymentData.accountNumber),
            _buildInfoRow('Account Name', paymentData.accountName),
            _buildInfoRow('Bank', paymentData.bankCode),
            if (paymentData.amount != null)
              _buildInfoRow(
                  'Amount', 'Rp ${paymentData.amount!.toStringAsFixed(0)}'),
            if (paymentData.description != null &&
                paymentData.description!.isNotEmpty)
              _buildInfoRow('Description', paymentData.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(paymentData);
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  void _showUrlQRResult(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Website QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This QR code contains a website URL:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(url);
            },
            child: const Text('Open URL'),
          ),
        ],
      ),
    );
  }

  void _showGenericQRResult(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanned content:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                qrCode,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(qrCode);
            },
            child: const Text('Use This Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    if (controller == null) {
      _showErrorDialog('Camera Error', 'Camera not initialized');
      return;
    }

    try {
      await controller!.toggleTorch();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      _showErrorDialog(
          'Flash Error', 'Failed to toggle flash: ${e.toString()}');
    }
  }

  void _flipCamera() async {
    if (controller == null) {
      _showErrorDialog('Camera Error', 'Camera not initialized');
      return;
    }

    try {
      await controller!.switchCamera();
      setState(() {
        _isFlashOn = false; // Reset flash when flipping camera
      });
    } catch (e) {
      _showErrorDialog(
          'Camera Error', 'Failed to flip camera: ${e.toString()}');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.stop();
    }
    controller.start();
  }

  @override
  void dispose() {
    _cameraHealthTimer?.cancel();
    _adaptiveScanTimer?.cancel();
    controller?.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Scan QR Code',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _hasPermission ? _toggleFlash : null,
          ),
          IconButton(
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
            ),
            onPressed: _hasPermission ? _flipCamera : null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _buildPermissionError();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return Stack(
      children: [
        _buildQRView(),
        _buildOverlay(),
        _buildInstructions(),
        _buildControls(),
      ],
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ??
                  'Please grant camera permission to scan QR codes',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildQRView() {
    return MobileScanner(
      controller: controller,
      onDetect: _onDetect,
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isProcessing ? Colors.green : AppColors.primary,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              if (!_isProcessing) _buildScanningLine(),
              if (_isProcessing) _buildSuccessIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value * (MediaQuery.of(context).size.width * 0.7 - 4),
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessIndicator() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              widget.subtitle ?? 'Position the QR code within the frame',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the QR code is well-lit and clearly visible',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
            label: 'Flash',
            onPressed: _toggleFlash,
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onPressed: _flipCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
