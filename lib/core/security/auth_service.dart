import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter/services.dart';

enum AuthResult { success, failed, notAvailable, notEnrolled, cancelled }

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      return await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> authenticate() async {
    try {
      if (!await isSupported()) return AuthResult.notAvailable;

      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.isEmpty) return AuthResult.notEnrolled;

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Artha to access your finances',
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'Artha Authentication',
            cancelButton: 'Cancel',
          ),
        ],
      );

      return ok ? AuthResult.success : AuthResult.failed;
    } on PlatformException {
      return AuthResult.failed;
    }
  }

  String label(AuthResult r) {
    switch (r) {
      case AuthResult.success:      return 'Authenticated';
      case AuthResult.failed:       return 'Authentication failed. Try again.';
      case AuthResult.notAvailable: return 'Biometrics not available.';
      case AuthResult.notEnrolled:  return 'Set up fingerprint in settings first.';
      case AuthResult.cancelled:    return 'Cancelled.';
    }
  }
}