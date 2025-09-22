import 'dart:convert';
import 'package:flutter/foundation.dart';

class QRService {
  static const String _tag = 'QRService';

  /// Processes a scanned QR code and returns the parsed data
  static Future<QRCodeResult> processQRCode(String qrData) async {
    try {
      if (qrData.isEmpty) {
        return QRCodeResult.error('QR code is empty');
      }

      // Clean the QR data
      final cleanData = qrData.trim();
      
      // Determine QR code type and process accordingly
      final qrType = _determineQRType(cleanData);
      
      switch (qrType) {
        case QRCodeType.payment:
          return _processPaymentQR(cleanData);
        case QRCodeType.url:
          return _processUrlQR(cleanData);
        case QRCodeType.text:
          return _processTextQR(cleanData);
        case QRCodeType.json:
          return _processJsonQR(cleanData);
        default:
          return QRCodeResult.error('Unsupported QR code format');
      }
    } catch (e) {
      debugPrint('$_tag: Error processing QR code: $e');
      return QRCodeResult.error('Failed to process QR code: ${e.toString()}');
    }
  }

  /// Determines the type of QR code based on its content
  static QRCodeType _determineQRType(String data) {
    // Check for payment QR patterns
    if (_isPaymentQR(data)) {
      return QRCodeType.payment;
    }
    
    // Check for URL
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return QRCodeType.url;
    }
    
    // Check for JSON
    if (data.startsWith('{') && data.endsWith('}')) {
      return QRCodeType.json;
    }
    
    // Default to text
    return QRCodeType.text;
  }

  /// Checks if the QR code is a payment QR
  static bool _isPaymentQR(String data) {
    // Common payment QR patterns
    final paymentPatterns = [
      RegExp(r'^\d{10,}$'), // Account number pattern
      RegExp(r'pay:', caseSensitive: false),
      RegExp(r'upi:', caseSensitive: false),
      RegExp(r'qris:', caseSensitive: false),
      RegExp(r'bca:', caseSensitive: false),
    ];
    
    return paymentPatterns.any((pattern) => pattern.hasMatch(data));
  }

  /// Processes payment QR codes
  static QRCodeResult _processPaymentQR(String data) {
    try {
      PaymentQRData? paymentData;
      
      // Try different payment QR formats
      if (data.toLowerCase().startsWith('bca:')) {
        paymentData = _parseBCAQR(data);
      } else if (data.toLowerCase().startsWith('upi:')) {
        paymentData = _parseUPIQR(data);
      } else if (RegExp(r'^\d{10,}$').hasMatch(data)) {
        // Simple account number
        paymentData = PaymentQRData(
          accountNumber: data,
          bankCode: 'BCA',
          accountName: 'Unknown',
        );
      } else {
        // Try to parse as JSON
        try {
          final json = jsonDecode(data);
          paymentData = PaymentQRData.fromJson(json);
        } catch (e) {
          return QRCodeResult.error('Invalid payment QR format');
        }
      }
      
      if (paymentData == null) {
        return QRCodeResult.error('Could not parse payment information');
      }
      
      // Validate payment data
      final validation = _validatePaymentData(paymentData);
      if (!validation.isValid) {
        return QRCodeResult.error(validation.errorMessage!);
      }
      
      return QRCodeResult.success(
        type: QRCodeType.payment,
        data: data,
        paymentData: paymentData,
      );
    } catch (e) {
      return QRCodeResult.error('Failed to process payment QR: ${e.toString()}');
    }
  }

  /// Parses BCA-specific QR format
  static PaymentQRData? _parseBCAQR(String data) {
    try {
      // Example: bca://pay?account=1234567890&name=John%20Doe&amount=100000
      final uri = Uri.parse(data);
      
      return PaymentQRData(
        accountNumber: uri.queryParameters['account'] ?? '',
        accountName: Uri.decodeComponent(uri.queryParameters['name'] ?? 'Unknown'),
        bankCode: 'BCA',
        amount: double.tryParse(uri.queryParameters['amount'] ?? '0'),
        description: Uri.decodeComponent(uri.queryParameters['desc'] ?? ''),
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses UPI QR format
  static PaymentQRData? _parseUPIQR(String data) {
    try {
      // Example: upi://pay?pa=user@bank&pn=User%20Name&am=100.00
      final uri = Uri.parse(data);
      
      return PaymentQRData(
        accountNumber: uri.queryParameters['pa'] ?? '',
        accountName: Uri.decodeComponent(uri.queryParameters['pn'] ?? 'Unknown'),
        bankCode: 'UPI',
        amount: double.tryParse(uri.queryParameters['am'] ?? '0'),
        description: Uri.decodeComponent(uri.queryParameters['tn'] ?? ''),
      );
    } catch (e) {
      return null;
    }
  }

  /// Validates payment data
  static ValidationResult _validatePaymentData(PaymentQRData data) {
    if (data.accountNumber.isEmpty) {
      return ValidationResult(false, 'Account number is required');
    }
    
    if (data.accountNumber.length < 8) {
      return ValidationResult(false, 'Invalid account number format');
    }
    
    if (data.amount != null && data.amount! < 0) {
      return ValidationResult(false, 'Amount cannot be negative');
    }
    
    return ValidationResult(true, null);
  }

  /// Processes URL QR codes
  static QRCodeResult _processUrlQR(String data) {
    try {
      final uri = Uri.parse(data);
      if (!uri.hasScheme) {
        return QRCodeResult.error('Invalid URL format');
      }
      
      return QRCodeResult.success(
        type: QRCodeType.url,
        data: data,
        url: data,
      );
    } catch (e) {
      return QRCodeResult.error('Invalid URL: ${e.toString()}');
    }
  }

  /// Processes JSON QR codes
  static QRCodeResult _processJsonQR(String data) {
    try {
      final json = jsonDecode(data);
      return QRCodeResult.success(
        type: QRCodeType.json,
        data: data,
        jsonData: json,
      );
    } catch (e) {
      return QRCodeResult.error('Invalid JSON format: ${e.toString()}');
    }
  }

  /// Processes text QR codes
  static QRCodeResult _processTextQR(String data) {
    return QRCodeResult.success(
      type: QRCodeType.text,
      data: data,
    );
  }
}

/// QR Code types
enum QRCodeType {
  payment,
  url,
  text,
  json,
}

/// QR Code processing result
class QRCodeResult {
  final bool isSuccess;
  final String? errorMessage;
  final QRCodeType? type;
  final String? data;
  final PaymentQRData? paymentData;
  final String? url;
  final Map<String, dynamic>? jsonData;

  QRCodeResult._({
    required this.isSuccess,
    this.errorMessage,
    this.type,
    this.data,
    this.paymentData,
    this.url,
    this.jsonData,
  });

  factory QRCodeResult.success({
    required QRCodeType type,
    required String data,
    PaymentQRData? paymentData,
    String? url,
    Map<String, dynamic>? jsonData,
  }) {
    return QRCodeResult._(
      isSuccess: true,
      type: type,
      data: data,
      paymentData: paymentData,
      url: url,
      jsonData: jsonData,
    );
  }

  factory QRCodeResult.error(String message) {
    return QRCodeResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Payment QR data model
class PaymentQRData {
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final double? amount;
  final String? description;

  PaymentQRData({
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    this.amount,
    this.description,
  });

  factory PaymentQRData.fromJson(Map<String, dynamic> json) {
    return PaymentQRData(
      accountNumber: json['accountNumber'] ?? json['account'] ?? '',
      accountName: json['accountName'] ?? json['name'] ?? 'Unknown',
      bankCode: json['bankCode'] ?? json['bank'] ?? 'Unknown',
      amount: double.tryParse(json['amount']?.toString() ?? '0'),
      description: json['description'] ?? json['desc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'accountName': accountName,
      'bankCode': bankCode,
      'amount': amount,
      'description': description,
    };
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult(this.isValid, this.errorMessage);
}