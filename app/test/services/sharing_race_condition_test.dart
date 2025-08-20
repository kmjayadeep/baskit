import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/sync_service.dart';
import 'package:baskit/models/shopping_list.dart';

void main() {
  group('Sharing Race Condition Prevention Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService.instance;
      syncService.reset();
    });

    group('Members Field Conflict Resolution', () {
      test('should detect members list changes in _shouldUpdateLocal', () {
        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['user1@example.com'], // Local has one member
        );

        final mergedList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: [
            'user1@example.com',
            'user2@example.com',
          ], // Merged has two members
        );

        // Act
        final shouldUpdate = syncService.testShouldUpdateLocal(
          localList,
          mergedList,
        );

        // Assert
        expect(
          shouldUpdate,
          isTrue,
          reason: 'Should detect members list changes',
        );
      });

      test('should not trigger update when members lists are identical', () {
        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['user1@example.com', 'user2@example.com'],
        );

        final mergedList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: [
            'user2@example.com',
            'user1@example.com',
          ], // Same members, different order
        );

        // Act
        final shouldUpdate = syncService.testShouldUpdateLocal(
          localList,
          mergedList,
        );

        // Assert
        expect(
          shouldUpdate,
          isFalse,
          reason:
              'Should not update when members are the same (order independent)',
        );
      });

      test('should merge members using union strategy in mergeLists', () {
        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['local@example.com'],
        );

        final remoteList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now.add(const Duration(seconds: 1)), // Remote is newer
          updatedAt: now.add(const Duration(seconds: 1)),
          items: [],
          members: ['remote@example.com'],
        );

        // Act
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Assert
        expect(
          mergedList.members.length,
          equals(2),
          reason: 'Should have both members',
        );
        expect(
          mergedList.members,
          containsAll(['local@example.com', 'remote@example.com']),
        );
        expect(
          mergedList.name,
          equals('Test List'),
          reason: 'Should use newer list properties',
        );
      });

      test('should prevent duplicate members in merge', () {
        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['shared@example.com', 'local@example.com'],
        );

        final remoteList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
          items: [],
          members: [
            'shared@example.com',
            'remote@example.com',
          ], // shared@example.com exists in both
        );

        // Act
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Assert
        expect(
          mergedList.members.length,
          equals(3),
          reason: 'Should not duplicate shared member',
        );
        expect(
          mergedList.members,
          containsAll([
            'shared@example.com',
            'local@example.com',
            'remote@example.com',
          ]),
        );
      });
    });

    group('Race Condition Scenarios', () {
      test('should handle sharing update followed by local content update', () {
        // This simulates Race Condition #4: Local Update During Share
        // Scenario:
        // 1. Firebase has list with new member (from sharing)
        // 2. Local has same list with newer updatedAt but missing member
        // 3. Merge should preserve both the newer content AND the member

        // Arrange - Simulate Firebase state after sharing
        final baseTime = DateTime.now();
        final firebaseList = ShoppingList(
          id: 'test-list',
          name: 'Original Name',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime.add(
            const Duration(seconds: 1),
          ), // Updated due to sharing
          items: [],
          members: ['newmember@example.com'], // New member from sharing
        );

        // Local state - user updated content after sharing
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Updated Name', // User changed the name
          description: 'Updated Description', // User changed description
          color: '#00FF00', // User changed color
          createdAt: baseTime,
          updatedAt: baseTime.add(
            const Duration(seconds: 2),
          ), // Newer due to local update
          items: [],
          members: [], // Missing the shared member!
        );

        // Act - Merge should resolve the conflict
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: firebaseList,
        );

        // Assert - Should have BOTH newer content AND the shared member
        expect(
          mergedList.name,
          equals('Updated Name'),
          reason: 'Should use newer local content',
        );
        expect(
          mergedList.description,
          equals('Updated Description'),
          reason: 'Should use newer local content',
        );
        expect(
          mergedList.color,
          equals('#00FF00'),
          reason: 'Should use newer local content',
        );
        expect(
          mergedList.members,
          contains('newmember@example.com'),
          reason: 'Should preserve shared member',
        );
        expect(
          mergedList.updatedAt,
          equals(localList.updatedAt),
          reason: 'Should use newer timestamp',
        );
      });

      test('should handle multiple sharing operations in merge', () {
        // This simulates multiple users being added to the same list

        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['original@example.com'],
        );

        final remoteList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)),
          items: [],
          members: [
            'original@example.com',
            'user1@example.com',
            'user2@example.com',
          ], // Multiple sharing operations
        );

        // Act
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Assert
        expect(
          mergedList.members.length,
          equals(3),
          reason: 'Should have all members',
        );
        expect(
          mergedList.members,
          containsAll([
            'original@example.com',
            'user1@example.com',
            'user2@example.com',
          ]),
        );
      });

      test('should preserve members when only local has content changes', () {
        // Scenario: User updates list content but Firebase has newer sharing info

        // Arrange
        final now = DateTime.now();
        final localList = ShoppingList(
          id: 'test-list',
          name: 'Updated by User', // User changed name
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now.add(
            const Duration(seconds: 2),
          ), // Newer local timestamp
          items: [],
          members: [], // No members locally
        );

        final remoteList = ShoppingList(
          id: 'test-list',
          name: 'Original Name',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)), // Older timestamp
          items: [],
          members: ['shared@example.com'], // Has shared member
        );

        // Act
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Assert
        expect(
          mergedList.name,
          equals('Updated by User'),
          reason: 'Should use newer local content',
        );
        expect(
          mergedList.members,
          contains('shared@example.com'),
          reason: 'Should preserve Firebase members',
        );
      });
    });

    group('Member List Comparison', () {
      test('should handle empty member lists correctly', () {
        // Arrange
        final now = DateTime.now();
        final listWithMembers = ShoppingList(
          id: 'test-list',
          name: 'Test',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['user@example.com'],
        );

        final listWithoutMembers = ShoppingList(
          id: 'test-list',
          name: 'Test',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: [],
        );

        // Act & Assert
        expect(
          syncService.testShouldUpdateLocal(
            listWithoutMembers,
            listWithMembers,
          ),
          isTrue,
          reason: 'Should detect change from empty to populated members',
        );

        expect(
          syncService.testShouldUpdateLocal(
            listWithMembers,
            listWithoutMembers,
          ),
          isTrue,
          reason: 'Should detect change from populated to empty members',
        );
      });

      test('should handle member order independence', () {
        // Arrange
        final now = DateTime.now();
        final list1 = ShoppingList(
          id: 'test-list',
          name: 'Test',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: ['a@example.com', 'b@example.com', 'c@example.com'],
        );

        final list2 = ShoppingList(
          id: 'test-list',
          name: 'Test',
          description: 'Test',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [],
          members: [
            'c@example.com',
            'a@example.com',
            'b@example.com',
          ], // Different order
        );

        // Act & Assert
        expect(
          syncService.testShouldUpdateLocal(list1, list2),
          isFalse,
          reason:
              'Should not detect change when member order differs but content is same',
        );
      });
    });
  });
}
