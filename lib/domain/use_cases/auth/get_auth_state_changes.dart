import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para obtener los cambios en el estado de autenticación.
/// Este caso de uso simplemente delega la llamada al repositorio de autenticación.
class GetAuthStateChanges {
  // Repositorio de autenticación.
  final AuthRepository repository;
  // Constructor del caso de uso.
  GetAuthStateChanges(this.repository);

  // Llama al caso de uso.
  Stream<AppUser?> call() {
    // Este caso de uso es un simple "pass-through" (intermediario)
    // al método del repositorio.
    return repository.authStateChanges;
  }
}
