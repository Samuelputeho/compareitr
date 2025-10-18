import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class SendPasswordResetEmail implements UseCase<void, String> {
  final AuthRepository authRepository;

  const SendPasswordResetEmail(this.authRepository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await authRepository.sendPasswordResetEmail(email);
  }
} 