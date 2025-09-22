import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class PinScreen extends StatefulWidget {
  final bool isLogin;
  final bool isSetup;

  const PinScreen({
    Key? key,
    this.isLogin = false,
    this.isSetup = false,
  }) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;
  bool _isLoading = false;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildPinDisplay(),
              const SizedBox(height: 40),
              Expanded(child: _buildKeypad()),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: AppColors.primaryBlue,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _getSubtitle(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _getDescription(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    final currentPin = _isConfirmingPin ? _confirmPin : _pin;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final bool isFilled = index < currentPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primaryBlue : AppColors.lightGrey,
            border: Border.all(
              color: isFilled ? AppColors.primaryBlue : AppColors.divider,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...List.generate(9, (index) {
                final number = index + 1;
                return _buildKeypadButton(
                  text: number.toString(),
                  onPressed: () => _onNumberPressed(number.toString()),
                );
              }),
              _buildKeypadButton(
                text: '',
                onPressed: null,
              ),
              _buildKeypadButton(
                text: '0',
                onPressed: () => _onNumberPressed('0'),
              ),
              _buildKeypadButton(
                icon: Icons.backspace_outlined,
                onPressed: _onBackspacePressed,
              ),
            ],
          ),
        ),
        if (widget.isSetup && !_isConfirmingPin && _pin.length == _pinLength)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CustomButton(
              text: AppStrings.next,
              onPressed: _onNextPressed,
              width: double.infinity,
            ),
          ),
      ],
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPressed != null ? AppColors.white : Colors.transparent,
              border: onPressed != null
                  ? Border.all(color: AppColors.divider)
                  : null,
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: AppColors.textPrimary,
                      size: 24,
                    )
                  : Text(
                      text ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_isLoading) return;
    
    setState(() {
      if (_isConfirmingPin) {
        if (_confirmPin.length < _pinLength) {
          _confirmPin += number;
          if (_confirmPin.length == _pinLength) {
            _handlePinComplete();
          }
        }
      } else {
        if (_pin.length < _pinLength) {
          _pin += number;
          if (_pin.length == _pinLength && widget.isLogin) {
            _handlePinComplete();
          }
        }
      }
    });
  }

  void _onBackspacePressed() {
    if (_isLoading) return;
    
    setState(() {
      if (_isConfirmingPin) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _onNextPressed() {
    if (_pin.length == _pinLength) {
      setState(() {
        _isConfirmingPin = true;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isLogin) {
        await _handlePinLogin();
      } else if (widget.isSetup) {
        await _handlePinSetup();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePinLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.authenticateWithPin(_pin);
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (mounted) {
      _showErrorAndReset('Invalid PIN. Please try again.');
    }
  }

  Future<void> _handlePinSetup() async {
    if (_pin != _confirmPin) {
      _showErrorAndReset('PINs do not match. Please try again.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.setPin(_pin);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN set successfully!'),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (mounted) {
      _showErrorAndReset('Failed to set PIN. Please try again.');
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
      _confirmPin = '';
      _isConfirmingPin = false;
    });
  }

  String _getTitle() {
    if (widget.isLogin) return 'PIN Login';
    if (widget.isSetup) return 'Set PIN';
    return 'Enter PIN';
  }

  String _getSubtitle() {
    if (widget.isLogin) return AppStrings.enterPin;
    if (widget.isSetup) {
      return _isConfirmingPin ? AppStrings.confirmPin : AppStrings.createPin;
    }
    return AppStrings.enterPin;
  }

  String _getDescription() {
    if (widget.isLogin) {
      return 'Enter your 6-digit PIN to access your account';
    }
    if (widget.isSetup) {
      if (_isConfirmingPin) {
        return 'Please confirm your 6-digit PIN';
      }
      return 'Create a 6-digit PIN for quick access to your account';
    }
    return 'Enter your 6-digit PIN';
  }
}
