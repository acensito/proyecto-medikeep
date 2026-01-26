import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medikeep/core/errors/failure.dart';

/// Caso de uso para que el usuario actual abandone un Space.
class LeaveSpace {
  // Repositorio de funciones en la nube
  final FirebaseFunctions _functions;

  // Constructor
  LeaveSpace(this._functions);

  // Método que ejecuta el caso de uso
  // Recibe el ID del Space a abandonar. Retorna un Either con Failure o void
  Future<Either<Failure, void>> call(String spaceId) async {
    // Obtener el ID del usuario actual
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Validaciones básicas
    // Validar que el ID no esté vacío y que el usuario esté autenticado
    if (spaceId.isEmpty || currentUserId == null) {
      return Future.value(Left(const ValidationFailure('Usuario o Space no válido.')));
    }
    
    try {
      // Llamar a la Cloud Function para abandonar el Space
      final callable = _functions.httpsCallable('leaveSpaceSelfService');
      // Ejecutar la función con los parámetros necesarios
      final result = await callable.call({
        'spaceId': spaceId,
      });
      // Verificar el resultado devuelto por la función
      if (result.data['success'] == true) {
        return const Right(null); // Abandono exitoso
      } else {
        return Left(ValidationFailure(result.data['message'] ?? 'Error al abandonar.')); // Error devuelto por la función
      }
    } on FirebaseFunctionsException catch (e) { // Excepciones especificas
      if (e.code == 'failed-precondition') { // Caso específico: único propietario
         return Left(ValidationFailure('No puedes abandonar. Eres el único propietario.'));
      }
      return Left(ServerFailure('Error en la nube: ${e.message}')); // Otras excepciones de funciones en la nube
    } catch (e) {
      return Left(ServerFailure(e.toString())); // Otras excepciones generales
    }
  }
}