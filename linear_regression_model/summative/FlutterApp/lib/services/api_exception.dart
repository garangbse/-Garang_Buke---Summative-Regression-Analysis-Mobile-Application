/// An error that can be shown to the user as it is.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
