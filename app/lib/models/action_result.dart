/// Result returned by ViewModel actions that need to report a user-facing
/// success or failure without forcing the UI to inspect ViewModel state.
class ActionResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool requiresReauth;

  const ActionResult._({
    required this.isSuccess,
    this.errorMessage,
    this.requiresReauth = false,
  });

  const ActionResult.success() : this._(isSuccess: true);

  const ActionResult.failure(String message)
    : this._(isSuccess: false, errorMessage: message);

  const ActionResult.requiresReauth(String message)
    : this._(
        isSuccess: false,
        errorMessage: message,
        requiresReauth: true,
      );
}
