import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashReporter {
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Iterable<Object> information = const [],
  });

  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
}

class FirebaseCrashReporter implements CrashReporter {
  final FirebaseCrashlytics _crashlytics;

  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Iterable<Object> information = const [],
  }) {
    return _crashlytics.recordError(
      exception,
      stack,
      fatal: fatal,
      reason: reason,
      information: information,
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return _crashlytics.recordFlutterFatalError(details);
  }
}

class CrashReportingService {
  static CrashReporter? _reporter;
  static bool _enabled = false;

  static CrashReporter get _activeReporter =>
      _reporter ??= FirebaseCrashReporter();

  const CrashReportingService._();

  static void configure({CrashReporter? reporter, required bool enabled}) {
    if (reporter != null) _reporter = reporter;
    _enabled = enabled;
  }

  static Future<void> recordFlutterFatal(FlutterErrorDetails details) async {
    if (!_enabled) return;

    await _recordSafely(() => _activeReporter.recordFlutterFatalError(details));
  }

  static Future<void> recordFatal(Object error, StackTrace stackTrace) async {
    if (!_enabled) return;

    await _recordSafely(
      () => _activeReporter.recordError(error, stackTrace, fatal: true),
    );
  }

  static Future<void> recordNonFatal({
    required String context,
    required Object error,
    StackTrace? stackTrace,
    Map<String, String> metadata = const {},
  }) async {
    if (!_enabled || _isExpectedOfflineError(error)) return;

    final report = SanitizedCrashReport(
      context: context,
      error: error,
      metadata: metadata,
    );

    await _recordSafely(
      () => _activeReporter.recordError(
        report,
        stackTrace,
        reason: report.reason,
        information: report.information,
      ),
    );
  }

  static bool _isExpectedOfflineError(Object error) {
    if (error is! FirebaseException) return false;

    return const {
      'aborted',
      'cancelled',
      'deadline-exceeded',
      'network-request-failed',
      'unavailable',
    }.contains(error.code);
  }

  static Future<void> _recordSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Crash reporting failed: $error');
    }
  }

  @visibleForTesting
  static void setReporterForTest(
    CrashReporter reporter, {
    bool enabled = true,
  }) {
    _reporter = reporter;
    _enabled = enabled;
  }

  @visibleForTesting
  static void resetForTest() {
    _reporter = null;
    _enabled = false;
  }
}

class SanitizedCrashReport implements Exception {
  final String context;
  final String errorType;
  final String? firebasePlugin;
  final String? firebaseCode;
  final Map<String, String> metadata;

  SanitizedCrashReport({
    required String context,
    required Object error,
    Map<String, String> metadata = const {},
  }) : context = _safeValue(context),
       errorType = _safeValue(error.runtimeType.toString()),
       firebasePlugin =
           error is FirebaseException ? _safeValue(error.plugin) : null,
       firebaseCode =
           error is FirebaseException ? _safeValue(error.code) : null,
       metadata = metadata.map(
         (key, value) => MapEntry(_safeValue(key), _safeValue(value)),
       );

  String get reason => 'non_fatal_$context';

  Iterable<Object> get information sync* {
    yield 'context=$context';
    yield 'error_type=$errorType';
    if (firebasePlugin != null) yield 'firebase_plugin=$firebasePlugin';
    if (firebaseCode != null) yield 'firebase_code=$firebaseCode';
    for (final entry in metadata.entries) {
      yield '${entry.key}=${entry.value}';
    }
  }

  @override
  String toString() {
    final parts = <String>[
      'context=$context',
      'errorType=$errorType',
      if (firebasePlugin != null) 'firebasePlugin=$firebasePlugin',
      if (firebaseCode != null) 'firebaseCode=$firebaseCode',
      ...metadata.entries.map((entry) => '${entry.key}=${entry.value}'),
    ];

    return 'SanitizedCrashReport(${parts.join(', ')})';
  }

  static String _safeValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 64) return 'redacted';
    if (trimmed.contains('@')) return 'redacted';
    if (!RegExp(r'^[a-zA-Z0-9_.:-]+$').hasMatch(trimmed)) {
      return 'redacted';
    }
    return trimmed;
  }
}
