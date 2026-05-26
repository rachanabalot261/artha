import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/auth_service.dart';
import '../security/key_manager.dart';

// FIX: Renamed from LockState → AppLockState to avoid conflict with
// Flutter's own LockState class in package:flutter/src/widgets/...
// This eliminates all 4 ambiguous_import errors in app.dart
enum AppLockState {
  checking,  // figuring out what state we're in
  locked,    // show lock screen
  unlocked,  // show main app
  noAuth,    // device has no biometrics — skip lock
}

class AppStateNotifier extends StateNotifier<AppLockState> {
  AppStateNotifier() : super(AppLockState.checking) {
    _init();
  }

  Future<void> _init() async {
    final hasKey = await KeyManager.instance.hasKey();
    if (!hasKey) {
      await KeyManager.instance.getOrCreateKey();
      state = AppLockState.unlocked;
      return;
    }
    final supported = await AuthService.instance.isSupported();
    state = supported ? AppLockState.locked : AppLockState.noAuth;
  }

  void unlock() => state = AppLockState.unlocked;
  void lock()   => state = AppLockState.locked;
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppLockState>(
        (ref) => AppStateNotifier());