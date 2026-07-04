import 'dart:async' show unawaited;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Utility for recording non-fatal Crashlytics events.
///
/// **PII WARNING**: Never include personally identifiable information
/// (emails, list names, item names, user display names, etc.) in any
/// Crashlytics log, key, or error message. Record only error codes,
/// operation names, and non-identifiable metadata.
class CrashlyticsUtil {
  CrashlyticsUtil._();

  /// Whether Crashlytics is available (Firebase initialized).
  static bool get _isAvailable {
    try {
      // Crashlytics is a no-op if Firebase is not initialized, but checking
      // avoids unnecessary work.
      return FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Record a non-fatal error to Crashlytics.
  ///
  /// [message] should describe the operation that failed (e.g. "signInWithGoogle").
  /// Do NOT include PII such as emails, list names, or item names.
  ///
  /// [error] is the caught exception/error object.
  /// [stack] is the optional stack trace.
  static void recordError(String message, [Object? error, StackTrace? stack]) {
    if (!_isAvailable) return;

    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stack,
        reason: message,
        fatal: false,
      ),
    );
  }

  /// Record a non-fatal Firebase exception with its error code.
  ///
  /// Logs the Firebase error code as a Crashlytics key for filtering.
  static void recordFirebaseError(
    String operation,
    String errorCode,
    String? errorMessage, [
    StackTrace? stack,
  ]) {
    if (!_isAvailable) return;

    unawaited(
      FirebaseCrashlytics.instance.recordError(
        'Firebase $operation failed: [$errorCode] $errorMessage',
        stack,
        reason: operation,
        information: [
          // errorCode is a Firebase error code like "permission-denied",
          // not PII — safe to record.
          {'error_code': errorCode},
        ],
        fatal: false,
      ),
    );
  }
}
