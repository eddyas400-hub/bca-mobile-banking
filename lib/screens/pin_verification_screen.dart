import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class PinVerificationScreen extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? transactionData;

  const PinVerificationScreen({
    Key? key,
    required this.title,
    required this.description,
    this.onSuccess,
    this.transactionData,
  }) : super(key: key);

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _pin = '';
  bool _isLoading = false;
  int _attempts = 0;
  final int _maxAttempts = 3;
  final int _pinLength = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildPinDisplay(),
                    const SizedBox(height: 48),
                    if (widget.transactionData != null) _buildTransactionSummary(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildKeypad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.security,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'PIN Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (_attempts > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Attempts remaining: ${_maxAttempts - _attempts}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? AppColors.primary : AppColors.divider,
          ),
        );
      }),
    );
  }

  Widget _buildTransactionSummary() {
    final data = widget.transactionData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (data['type'] != null) _buildSummaryRow('Type', data['type']),
          if (data['amount'] != null) _buildSummaryRow('Amount', data['amount']),
          if (data['recipient'] != null) _buildSummaryRow('To', data['recipient']),
          if (data['account'] != null) _buildSummaryRow('From', data['account']),
          if (data['provider'] != null) _buildSummaryRow('Provider', data['provider']),
          if (data['phone'] != null) _buildSummaryRow('Phone', data['phone']),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int col = 1; col <= 3; col++)
                _buildKeypadButton((row * 3 + col).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(''),
            _buildKeypadButton('0'),
            _buildKeypadButton('⌫', isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String text, {bool isBackspace = false}) {
    if (text.isEmpty && !isBackspace) {
      return const SizedBox(width: 80, height: 80);
    }

    return GestureDetector(
      onTap: _isLoading ? null : () => _onKeypadTap(text, isBackspace),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  void _onKeypadTap(String value, bool isBackspace) {
    if (isBackspace) {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    } else {
      if (_pin.length < _pinLength) {
        setState(() {
          _pin += value;
        });
        
        if (_pin.length == _pinLength) {
          _verifyPin();
        }
      }
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isValid = await authProvider.authenticateWithPin(_pin);

      if (isValid && mounted) {
        Navigator.of(context).pop(true);
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      } else {
        _attempts++;
        if (_attempts >= _maxAttempts) {
          if (mounted) {
            Navigator.of(context).pop(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Too many failed attempts. Please try again later.'),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else {
          _showErrorAndReset('Incorrect PIN. Please try again.');
        }
      }
    } catch (e) {
      _showErrorAndReset('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorAndReset(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
      ),
    );
    
    setState(() {
      _pin = '';
    });
  }
}