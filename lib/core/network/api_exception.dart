/// Every failure the network layer can produce, as one closed set.
///
/// Sealed so a `switch` over it is exhaustive: adding a case here makes the
/// compiler point at every screen that has to decide what to show for it.
/// Views never see an `http` type or a raw status code.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Safe to show a telecaller. Never contains a stack trace or a URL.
  final String message;

  @override
  String toString() => message;
}

/// The request never reached the server -- no connectivity, DNS failure, or a
/// refused socket.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

/// The server accepted the request but did not answer in time.
final class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([
    super.message = 'The server took too long to respond.',
  ]);
}

/// 401. The token is missing, expired or was revoked by a logout elsewhere.
/// The session layer listens for this and sends the user back to login.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

/// 403. Authenticated, but this account may not do that -- the API returns it
/// for a role that cannot access the CRM at all.
final class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'This account does not have access.',
  ]);
}

/// 404, including a party or invoice that exists but is outside this
/// telecaller's region and city scope.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found.']);
}

/// 422. Laravel's validation failure, with the per-field messages it returns.
final class ValidationException extends ApiException {
  const ValidationException(super.message, [this.errors = const {}]);

  /// Field name to the messages for it, straight from Laravel's `errors` key.
  final Map<String, List<String>> errors;

  /// The first message for [field], for showing under one input.
  String? forField(String field) {
    final List<String>? messages = errors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }
}

/// Any 5xx.
final class ServerException extends ApiException {
  const ServerException([
    super.message = 'Something went wrong on the server. Try again shortly.',
  ]);
}

/// A 2xx whose body was not the JSON object the caller expected. Usually a
/// login page or an HTML error returned where JSON was promised.
final class UnexpectedResponseException extends ApiException {
  const UnexpectedResponseException([
    super.message = 'The server sent an unexpected response.',
  ]);
}
