/// Where the API lives. The address can be changed without editing code:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// (10.0.2.2 is how the Android emulator reaches a server running on your computer.)
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://garang-buke-summative-regression-lb0z.onrender.com/', // replace with your Render URL
  );

  static const String predictPath = '/predict';

  /// A free Render service can need up to a minute to wake up, so the timeout is generous.
  static const Duration timeout = Duration(seconds: 90);
}
