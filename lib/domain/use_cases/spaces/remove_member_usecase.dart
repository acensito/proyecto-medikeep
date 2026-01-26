import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';

/// Caso de uso para eliminar un miembro de un Space 
/// Solo posible por un Owner a otro usuario que no sea Owner
class RemoveMember {
  // Instancia de Firebase Functions
  final FirebaseFunctions _functions;

  // Constructor
  RemoveMember(this._functions);

  // Método que ejecuta el caso de uso
  // Recibe el ID del Space y el ID del usuario a eliminar.
  // Retorna un Either con Failure o void
  Future<Either<Failure, void>> call({
    required String spaceId,
    required String userIdToRemove,
  }) async {

    // Validaciones básicas
    // Validar que el ID del Space no esté vacío
    if (userIdToRemove.isEmpty) {
      return Future.value(Left(const ValidationFailure('ID de usuario no válido.')));
    }
    
    try {
      // Llamar a la Cloud Function para eliminar el miembro
      final callable = _functions.httpsCallable('removeMemberFromSpace');
      // Ejecutar la función con los parámetros necesarios
      final result = await callable.call({
        'spaceId': spaceId,
        'userIdToRemove': userIdToRemove,
      });
      // Verificar el resultado devuelto por la función
      if (result.data['success'] == true) {
        return const Right(null); // Eliminación exitosa
      } else {
        // Error devuelto por la función (es el ultimo miembro, por ejemplo)
        return Left(ValidationFailure(result.data['message'] ?? 'Error al eliminar miembro.'));
      }
    } on FirebaseFunctionsException catch (e) {
      // Si falla la condicion que el Space debe tener al menos un Owner
      // devuelve un error específico
      if (e.code == 'failed-precondition') {
        return Left(ValidationFailure('Error: El Space debe tener al menos un propietario.'));
      }
      // Otras excepciones de funciones en la nube
      return Left(ServerFailure('Error en la nube: ${e.message}'));
    } catch (e) {
      // Otras excepciones generales
      return Left(ServerFailure(e.toString()));
    }
  }
}