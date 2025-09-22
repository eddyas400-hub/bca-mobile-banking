import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () {
          print('DEBUG: CustomButton onPressed called');
          print('DEBUG: isDisabled: $isDisabled, isLoading: $isLoading, onPressed != null: ${onPressed != null}');
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(isDisabled),
          foregroundColor: _getTextColor(isDisabled),
          elevation: type == ButtonType.primary ? 2 : 0,
          shadowColor: AppColors.primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: _getBorderSide(isDisabled),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: _getTextColor(isDisabled),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: textStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(isDisabled),
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (backgroundColor != null) return backgroundColor!;
    
    if (isDisabled) {
      return AppColors.lightGrey;
    }
    
    switch (type) {
      case ButtonType.primary:
        return AppColors.primaryBlue;
      case ButtonType.secondary:
        return AppColors.lightBlue;
      case ButtonType.outline:
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (textColor != null) return textColor!;
    
    if (isDisabled) {
      return AppColors.textLight;
    }
    
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return AppColors.white;
      case ButtonType.outline:
      case ButtonType.text:
        return AppColors.primaryBlue;
    }
  }

  BorderSide _getBorderSide(bool isDisabled) {
    if (borderColor != null) {
      return BorderSide(color: borderColor!, width: 1);
    }
    
    if (type == ButtonType.outline) {
      return BorderSide(
        color: isDisabled ? AppColors.lightGrey : AppColors.primaryBlue,
        width: 1,
      );
    }
    
    return BorderSide.none;
  }
}

// Specialized button variants
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          type: ButtonType.primary,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          type: ButtonType.secondary,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );
}

class OutlineButton extends CustomButton {
  const OutlineButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          type: ButtonType.outline,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );
}