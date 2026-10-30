import 'dart:async';

/// Broadcasts "the server rejected our token" to whoever cares.
///
/// This exists to break a cycle. The API client has to react to a 401, but
/// deciding to sign the user out is session policy, and the session is built
/// on top of the API client. A one-way signal lets the client fire and the
/// session listen, with neither importing the other.
class UnauthorizedSignal {
  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void fire() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() => _controller.close();
}
