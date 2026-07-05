import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/shopping_repository.dart';
import 'crash_reporting_service.dart';
import 'firebase_auth_service.dart';
import 'local_storage_service.dart';

/// Migrates guest/local lists to the authenticated cloud repository.
class MigrationService {
  static const String _migrationCompleteKey = 'migration_complete_';

  final LocalStorageService _localStorage;
  final ShoppingRepository _cloudRepository;

  const MigrationService({
    required LocalStorageService localStorage,
    required ShoppingRepository cloudRepository,
  }) : _localStorage = localStorage,
       _cloudRepository = cloudRepository;

  String get _currentUserMigrationKey {
    final userId = FirebaseAuthService.currentUser?.uid ?? 'anonymous';
    return '$_migrationCompleteKey$userId';
  }

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_currentUserMigrationKey) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_currentUserMigrationKey, true);
  }

  Future<void> clearForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserMigrationKey);
  }

  /// Ensures migration has completed.
  ///
  /// Local data is cleared only after every local list is successfully copied to
  /// the cloud repository. Partial failures leave the migration pending so the
  /// next authenticated access can retry safely.
  Future<bool> ensureComplete() async {
    if (await isComplete()) return true;

    debugPrint('🔄 Starting migration of local data to Firebase...');

    try {
      final localLists = await _localStorage.getAllLists();
      var allListsMigrated = true;

      for (final list in localLists) {
        try {
          final success = await _cloudRepository.createList(list);
          if (success) {
            debugPrint('✅ Migrated list "${list.name}" to Firebase');
          } else {
            debugPrint('❌ Failed to migrate list "${list.name}"');
            allListsMigrated = false;
          }
        } catch (error, stackTrace) {
          unawaited(
            CrashReportingService.recordNonFatal(
              context: 'migration_list_create',
              error: error,
              stackTrace: stackTrace,
            ),
          );
          debugPrint('❌ Error migrating list "${list.name}": $error');
          allListsMigrated = false;
        }
      }

      if (!allListsMigrated) {
        debugPrint(
          '⚠️ Migration incomplete: keeping local data and leaving migration pending for retry',
        );
        return false;
      }

      if (localLists.isNotEmpty) {
        debugPrint(
          '✅ Migration completed: ${localLists.length} lists migrated',
        );
      }

      await markComplete();
      await _localStorage.clearAllData();
      debugPrint('🗑️ Local data cleared after migration');
      return true;
    } catch (error, stackTrace) {
      unawaited(
        CrashReportingService.recordNonFatal(
          context: 'migration_failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      debugPrint('❌ Migration failed: $error');
      return false;
    }
  }
}
