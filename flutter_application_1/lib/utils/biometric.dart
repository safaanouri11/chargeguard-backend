// Thin wrapper around local_auth so the rest of the app doesn't have to
// care about the plugin's quirks or the (web) platform's lack of biometrics.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'storage.dart';

class Biometric {
  static final _auth = LocalAuthentication();
  static const _kEnabledKey = 'cg_biometric_enabled';

  // True when the OS exposes biometrics (or device PIN/pattern as a fallback)
  // AND at least one biometric is enrolled.
  static Future<bool> available() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Whether the user previously opted in to biometric unlock.
  static Future<bool> isEnabled() async {
    final v = await Storage.get(_kEnabledKey);
    return v == 'true';
  }

  static Future<void> setEnabled(bool enabled) async {
    await Storage.set(_kEnabledKey, enabled ? 'true' : 'false');
  }

  // Prompt the OS for biometric / device-credential auth. Returns true on
  // success, false on cancel, any error, or if biometrics aren't available.
  static Future<bool> authenticate({String reason = 'Unlock ChargeGuard'}) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN/pattern as fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
