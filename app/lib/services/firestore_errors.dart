class UserNotFoundException implements Exception {
  final String email;

  UserNotFoundException(this.email);

  @override
  String toString() => 'UserNotFoundException: $email';
}

class UserAlreadyMemberException implements Exception {
  final String userName;

  UserAlreadyMemberException(this.userName);

  @override
  String toString() => 'UserAlreadyMemberException: $userName';
}

/// Exception thrown when a list action (add, update, delete, share) fails.
///
/// Used by ViewModels to signal action-level failures without exposing
/// internal error details to the UI. Callers can catch this to distinguish
/// action failures from other error types.
class ListActionException implements Exception {
  final String message;

  const ListActionException(this.message);

  @override
  String toString() => 'ListActionException: $message';
}
