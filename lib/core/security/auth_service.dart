import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

// All possible outcomes of an auth attempt
enum AuthResult { success, failed, notAvailable, notEnrolled, cancelled }

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _auth = LocalAuthentication();

  // Check if the device has biometric hardware
  Future<bool> isSupported() async {
    try {
      return await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // Show the biometric prompt and return the result
  Future<AuthResult> authenticate() async {
    try {
      if (!await isSupported()) return AuthResult.notAvailable;

      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.isEmpty) return AuthResult.notEnrolled;

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Artha to access your finances',
        options: const AuthenticationOptions(
          biometricOnly: false,   // allow PIN fallback
          stickyAuth: true,       // don't cancel if user switches apps
          sensitiveTransaction: true, // show extra security warning
        ),
      );

      return ok ? AuthResult.success : AuthResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) return AuthResult.notEnrolled;
      if (e.code == auth_error.notAvailable) return AuthResult.notAvailable;
      return AuthResult.failed;
    }
  }

  // Human readable message for each result
  String label(AuthResult r) {
    switch (r) {
      case AuthResult.success:      return 'Authenticated';
      case AuthResult.failed:       return 'Authentication failed. Try again.';
      case AuthResult.notAvailable: return 'Biometrics not available on this device.';
      case AuthResult.notEnrolled:  return 'Set up fingerprint in phone settings first.';
      case AuthResult.cancelled:    return 'Cancelled.';
    }
  }
}