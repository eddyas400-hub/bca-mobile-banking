import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';
  static const String _keyUserPin = 'user_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Mock user data for demo purposes
  final Map<String, Map<String, dynamic>> _mockUsers = {
    'demo123': {
      'password': 'password123',
      'user': {
        'id': '1',
        'userId': 'demo123',
        'name': 'John Doe',
        'email': 'john.doe@email.com',
        'phoneNumber': '+62812345678',
        'profileImage': '',
        'lastLogin': DateTime.now().toIso8601String(),
        'isActive': true,
      }
    },
    'user456': {
      'password': 'mypassword',
      'user': {
        'id': '2',
        'userId': 'user456',
        'name': 'Jane Smith',
        'email': 'jane.smith@email.com',
        'phoneNumber': '+62887654321',
        'profileImage': '',
        'lastLogin': DateTime.now().toIso8601String(),
        'isActive': true,
      }
    },
  };

  // Login with username and password
  Future<User?> login(String userId, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check mock users
      if (_mockUsers.containsKey(userId)) {
        final userData = _mockUsers[userId]!;
        if (userData['password'] == password) {
          final user = User.fromJson(userData['user']);
          await _saveUserSession(user);
          return user;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Set PIN
  Future<bool> setPin(String pin) async {
    try {
      final hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _keyUserPin, value: hashedPin);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _keyUserPin);
      if (storedPin == null) return false;
      
      final hashedPin = _hashPin(pin);
      return storedPin == hashedPin;
    } catch (e) {
      return false;
    }
  }

  // Check if PIN is set
  Future<bool> isPinSet() async {
    try {
      final pin = await _secureStorage.read(key: _keyUserPin);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Enable/Disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return null;
      
      final userDataString = prefs.getString(_keyUserData);
      if (userDataString == null) return null;
      
      final userData = jsonDecode(userDataString);
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserData);
    // Keep PIN and biometric settings for next login
  }

  // Save user session
  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  // Hash PIN for security
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'bca_mobile_salt'); // Add salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
