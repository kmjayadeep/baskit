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

class ListNotFoundException implements Exception {
  final String listId;

  ListNotFoundException(this.listId);

  @override
  String toString() => 'ListNotFoundException: $listId';
}
