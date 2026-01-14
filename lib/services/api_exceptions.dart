class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => message.isEmpty ? 'Unauthorized' : message;
}

class UnAuthenticatedException extends UnauthorizedException {
  UnAuthenticatedException([super.message = 'Unauthenticated']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);

  @override
  String toString() => message.isEmpty ? 'Network error' : message;
}
