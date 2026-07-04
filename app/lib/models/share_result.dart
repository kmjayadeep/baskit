/// Result for sharing a list with another user.
class ShareResult {
  final bool success;
  final String? errorMessage;

  const ShareResult.success() : success = true, errorMessage = null;

  const ShareResult.error(this.errorMessage) : success = false;
}
