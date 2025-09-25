import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/shopping_repository.dart';
import '../repositories/storage_shopping_repository.dart';

/// Global provider for the shopping repository
///
/// This provides a single instance of ShoppingRepository that can be used
/// across all ViewModels. The concrete implementation (StorageShoppingRepository)
/// is injected here, following the dependency inversion principle.
final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return StorageShoppingRepository.instance();
});
