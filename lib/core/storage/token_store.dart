/// Where the API token lives between launches.
///
/// An interface so the network layer depends on the idea of a token store, not
/// on `shared_preferences`. Swapping to secure storage later is one new class
/// and one provider override.
abstract interface class TokenStore {
  /// The bearer token, or null when nobody is signed in.
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}
