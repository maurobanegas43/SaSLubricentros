/// Unified failure type for all operations.
abstract class Failure {
  final String message;
  final Object? originalError;
  const Failure({required this.message, this.originalError});
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message, Object? error})
      : super(message: message ?? 'Sin conexión a internet. Verificá tu red.', originalError: error);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required String message, this.statusCode, Object? error})
      : super(message: message, originalError: error);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message, Object? error})
      : super(message: message, originalError: error);
}

class UnknownFailure extends Failure {
  const UnknownFailure({Object? error})
      : super(message: 'Ocurrió un error inesperado. Intentá de nuevo.', originalError: error);
}

class AuthFailure extends Failure {
  const AuthFailure({String? message, Object? error})
      : super(message: message ?? 'Credenciales inválidas. Verificá tus datos.', originalError: error);
}
