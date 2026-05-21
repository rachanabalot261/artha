import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/auth_service.dart';
import '../security/key_manager.dart';

// The four possible states of the app on launch
enum LockState {
  checking,  // figuring out what state we're in
  locked,    // show lock screen
  unlocked,  // show main app
  noAuth     // device has no biometrics — skip lock
}

class AppStateNotifier extends StateNotifier<LockState> {
  AppStateNotifier() : super(LockState.checking) {
    _init(); // immediately figure out state on creation
  }

  Future<void> _init() async {
    final hasKey = await KeyManager.instance.hasKey();
    if (!hasKey) {
      // First ever launch — generate key, skip lock this time
      await KeyManager.instance.getOrCreateKey();
      state = LockState.unlocked;
      return;
    }
    final supported = await AuthService.instance.isSupported();
    state = supported ? LockState.locked : LockState.noAuth;
  }

  void unlock() => state = LockState.unlocked;
  void lock()   => state = LockState.locked;
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, LockState>(
        (ref) => AppStateNotifier());