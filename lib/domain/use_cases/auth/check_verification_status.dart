import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

class CheckVerificationStatus {
  final AuthRepository repository;

  CheckVerificationStatus({required this.repository});

  Future<Either<Failure, bool>> call() {
    return repository.checkVerificationStatus();
  }
}