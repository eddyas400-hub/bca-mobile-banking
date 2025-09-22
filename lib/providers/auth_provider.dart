import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isPinSet = false;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isPinSet => _isPinSet;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isLoading => _state == AuthState.loading;

  // Initialize authentication state
  Future<void> initialize() async {
    _setState(AuthState.loading);
    
    try {
      // Check if user is already logged in
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
      
      // Check biometric availability and settings
      _isBiometricAvailable = await _authService.isBiometricAvailable();
      _isBiometricEnabled = await _authService.isBiometricEnabled();
      _isPinSet = await _authService.isPinSet();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize: $e');
    }
  }

  // Login with username and password
  Future<bool> login(String userId, String password) async {
    _setState(AuthState.loading);
    
    try {
      final user = await _authService.login(userId, password);
      if (user != null) {
        _user = user;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError('Invalid credentials');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    if (!_isBiometricAvailable || !_isBiometricEnabled) {
      _setError('Biometric authentication is not available or enabled');
      return false;
    }
    
    _setState(AuthState.loading);
    
    try {
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated) {
        // Get stored user data
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _user = user;
          _setState(AuthState.authenticated);
          return true;
        }
      }
      
      _setError('Biometric authentication failed');
      return false;
    } catch (e) {
      _setError('Biometric authentication error: $e');
      return false;
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    if (!_isPinSet) {
      _setError('PIN is not set');
      return false;
    }
    
    _setState(AuthState.loading);
    
    try {
      final isValid = await _authService.verifyPin(pin);
      if (isValid) {
        // Get stored user data
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _user = user;
          _setState(AuthState.authenticated);
          return true;
        }
      }
      
      _setError('Invalid PIN');
      return false;
    } catch (e) {
      _setError('PIN authentication error: $e');
      return false;
    }
  }

  // Set PIN
  Future<bool> setPin(String pin) async {
    try {
      final success = await _authService.setPin(pin);
      if (success) {
        _isPinSet = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to set PIN: $e');
      return false;
    }
  }

  // Enable/Disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _authService.setBiometricEnabled(enabled);
      _isBiometricEnabled = enabled;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update biometric settings: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    _setState(AuthState.loading);
    
    try {
      await _authService.logout();
      _user = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError('Logout failed: $e');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private methods
  void _setState(AuthState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }

  // Reset to unauthenticated state
  void reset() {
    _state = AuthState.unauthenticated;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
