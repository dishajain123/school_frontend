import 'dart:async';

/// Singleton broadcast stream used to communicate forced logout events
/// from [AuthInterceptor] (inside Dio) to [AuthNotifier] without
/// creating a circular Riverpod dependency.
///
/// Usage:
///   Emit:  AuthLogoutBus.instance.notifyLogout();
///   Listen: AuthLogoutBus.instance.stream.listen((_) { ... });
class AuthLogoutBus {
  AuthLogoutBus._();
  static final AuthLogoutBus instance = AuthLogoutBus._();

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notifyLogout() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() => _controller.close();
}