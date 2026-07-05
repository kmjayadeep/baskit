import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/crash_reporting_service.dart';

void main() {
  late FakeCrashReporter reporter;

  setUp(() {
    reporter = FakeCrashReporter();
    CrashReportingService.setReporterForTest(reporter);
  });

  tearDown(() {
    CrashReportingService.setReporterForTest(
      FakeCrashReporter(),
      enabled: false,
    );
  });

  test('records sanitized non-fatal errors without PII', () async {
    final stackTrace = StackTrace.current;

    await CrashReportingService.recordNonFatal(
      context: 'firestore_create_list',
      error: Exception('failed for user@example.com on Groceries'),
      stackTrace: stackTrace,
      metadata: {
        'operation': 'create_list',
        'unsafe_value': 'Groceries for user@example.com',
      },
    );

    expect(reporter.errors, hasLength(1));
    final event = reporter.errors.single;

    expect(event.fatal, isFalse);
    expect(event.stack, same(stackTrace));
    expect(event.reason, 'non_fatal_firestore_create_list');

    final recordedText = [
      event.exception.toString(),
      event.reason,
      ...event.information.map((value) => value.toString()),
    ].join('\n');

    expect(recordedText, contains('firestore_create_list'));
    expect(recordedText, contains('operation=create_list'));
    expect(recordedText, isNot(contains('user@example.com')));
    expect(recordedText, isNot(contains('Groceries')));
    expect(recordedText, contains('unsafe_value=redacted'));
  });

  test('records fatal errors when enabled', () async {
    final stackTrace = StackTrace.current;
    final error = StateError('fatal failure');

    await CrashReportingService.recordFatal(error, stackTrace);

    expect(reporter.errors, hasLength(1));
    final event = reporter.errors.single;
    expect(event.exception, same(error));
    expect(event.stack, same(stackTrace));
    expect(event.fatal, isTrue);
  });

  test('records Flutter fatal errors when enabled', () async {
    final details = FlutterErrorDetails(exception: StateError('widget failed'));

    await CrashReportingService.recordFlutterFatal(details);

    expect(reporter.flutterFatalErrors, hasLength(1));
    expect(reporter.flutterFatalErrors.single, same(details));
  });

  test('skips expected offline Firebase errors', () async {
    await CrashReportingService.recordNonFatal(
      context: 'firestore_update_list',
      error: FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'offline for user@example.com',
      ),
      stackTrace: StackTrace.current,
    );

    expect(reporter.errors, isEmpty);
  });

  test('does not record while disabled', () async {
    CrashReportingService.setReporterForTest(reporter, enabled: false);

    await CrashReportingService.recordNonFatal(
      context: 'startup_storage_init',
      error: StateError('storage failed'),
      stackTrace: StackTrace.current,
    );

    expect(reporter.errors, isEmpty);
  });
}

class FakeCrashReporter implements CrashReporter {
  final List<RecordedError> errors = [];
  final List<FlutterErrorDetails> flutterFatalErrors = [];

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Iterable<Object> information = const [],
  }) async {
    errors.add(
      RecordedError(
        exception: exception,
        stack: stack,
        fatal: fatal,
        reason: reason,
        information: information.toList(),
      ),
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    flutterFatalErrors.add(details);
  }
}

class RecordedError {
  final Object exception;
  final StackTrace? stack;
  final bool fatal;
  final String? reason;
  final List<Object> information;

  const RecordedError({
    required this.exception,
    required this.stack,
    required this.fatal,
    required this.reason,
    required this.information,
  });
}
