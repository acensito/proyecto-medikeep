
import 'package:equatable/equatable.dart';

/// Clase abstracta Failure para los mensajes de error genericos
/// Obliga a cada fallo tener su mensaje especifico
abstract class Failure extends Equatable {
  // atributos
  final String message; //mensaje de error

  // constructor
  const Failure(this.message);
  // comparador de equatable
  @override
  List<Object> get props => [message];
}

// Errores que extienden de la clase. Mensajes especificos
// +-------------------------------+

/// Fallo del servidor
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Fallo de autenticación
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Fallo de la API
class ApiFailure extends Failure {
  const ApiFailure(super.message);
}

/// Fallo de red
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Fallo de crear recursos
class ResourceCreationFailure extends Failure {
  const ResourceCreationFailure(super.message);
}

//Fallo de validación
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

