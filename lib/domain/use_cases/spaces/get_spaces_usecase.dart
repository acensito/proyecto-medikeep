import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';

/// Caso de uso para obtener la lista de Spaces
/// Retorna un Stream de Either con Failure o List
class GetSpaces {
  // Repositorio de Space
  final SpaceRepository repository;

  // Constructor
  GetSpaces(this.repository);

  // Método que ejecuta el caso de uso
  // Retorna un Stream de Either con Failure o List de Spaces
  Stream<Either<Failure, List<Space>>> call() {
    return repository.getSpaces();
  }
}